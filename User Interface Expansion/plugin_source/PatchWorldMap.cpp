#include "PatchWorldMap.h"

#include "stdafx.h"

#include <TES3Cell.h>
#include <TES3DataHandler.h>
#include <TES3GameFile.h>
#include <TES3Land.h>
#include <TES3MobilePlayer.h>
#include <TES3Reference.h>
#include <TES3Region.h>
#include <TES3WorldController.h>

#include <TES3UIElement.h>
#include <TES3UIManager.h>

#include <NISourceTexture.h>

#include <MemoryUtil.h>
#include <TES3Util.h>
#include <Log.h>

#include <algorithm>

namespace UIEXT {
	static lua_State * luaState = nullptr;

	static bool updateMapBounds = false;
	static int cellResolution = 9;
	static int cellMinX = 0;
	static int cellMaxX = 0;
	static int cellMinY = 0;
	static int cellMaxY = 0;

	static int mapResolution = 0;

	static unsigned int mapWidth = 0;
	static unsigned int mapHeight = 0;

	float zoomLevel = 0.0;

	unsigned long getNextHighestPowerOf2(unsigned long value) {
		value--;
		value |= value >> 1;
		value |= value >> 2;
		value |= value >> 4;
		value |= value >> 8;
		value |= value >> 16;
		value++;
		return value;
	}

	//
	// When allocating space for our map, use the new size.
	//

	const auto TES3_NiPixelData_ctor = reinterpret_cast<void*(__thiscall *)(void*, unsigned int, unsigned int, void*, unsigned int)>(0x6D4FC0);
	void * __fastcall OnCreateMapPixelData(void * pixelData, DWORD _UNUSUED_, unsigned int width, unsigned int height, void * format, unsigned int mipMapLevels) {
		mapWidth = getNextHighestPowerOf2((cellMaxX - cellMinX + 1) * cellResolution);
		mapHeight = getNextHighestPowerOf2((cellMaxY - cellMinY + 1) * cellResolution);
		mapResolution = max(mapWidth, mapHeight);
		return TES3_NiPixelData_ctor(pixelData, mapResolution, mapResolution, format, mipMapLevels);
	}

	//
	// Loading a new game, figure out the map size before allocation.
	//

	const auto TES3_NonDynamicData_allocateMap = reinterpret_cast<void(__thiscall *)(TES3::NonDynamicData*)>(0x4C8070);
	void __fastcall OnAllocateMapDefault(TES3::NonDynamicData * nonDynamicData) {
		// Call overwritten function.
		TES3_NonDynamicData_allocateMap(nonDynamicData);

		// We need to set the default pixels, using the new size since we removed that code.
		auto pixelData = nonDynamicData->mapTexture->pixelData;
		size_t length = pixelData->widths[0] * pixelData->heights[0];
		auto pixels = reinterpret_cast<NI::PixelRGB*>(&pixelData->pixels[pixelData->offsets[0]]);
		for (size_t i = 0; i < length; i++) {
			pixels->r = 25;
			pixels->g = 36;
			pixels->b = 33;
			pixels++;
		}
	}

	//
	// Loading from a save. This expects values of 512 and 9. It will stop loading if given other values.
	//

	struct MAPH {
		union {
			struct {
				unsigned int mapResolution;
				int unknown;
			} vanillaData;
			struct {
				short cellMinX;
				short cellMaxX;
				short cellMinY;
				short cellMaxY;
			} uiextData;
		};
	};
	static_assert(sizeof(MAPH) == 0x8, "MAPH failed size validation");

	bool __fastcall OnLoadMAPHChunk(TES3::GameFile * saveFile, DWORD _UNUSED_, MAPH* data, unsigned int dataSize) {
		// Actually load our data.
		if (!saveFile->readChunkData(data, dataSize)) {
			return false;
		}

		// If our data differs, return invalid data so we don't load the map.
		if (data->uiextData.cellMinX != cellMinX || data->uiextData.cellMaxX != cellMaxX ||
			data->uiextData.cellMinY != cellMinY || data->uiextData.cellMaxY != cellMaxY) {
			data->vanillaData.mapResolution = 0;
		}
		// If it does match, let the system think the values are what it wants. They're thrown away.
		else {
			data->vanillaData.mapResolution = 512;
			data->vanillaData.mapResolution = 9;
		}

		return true;
	}

	//
	// Saving to the file. This will write our custom resolution information to the save.
	//



	//
	// Attempt to draw a cell when it is explored.
	//

	static std::unordered_map<DWORD, NI::PixelRGB> colorMap;

	void __fastcall OnDrawCell(TES3::NonDynamicData * nonDynamicData, DWORD _UNUSED_, TES3::Cell * cell) {
		if (cell->isInterior()) {
			return;
		}


	}

	//
	// Draw base map.
	//

	struct WNAM {
		struct block {
			signed char data[9];
		};
		block data[9];
	};
	static_assert(sizeof(WNAM) == 0x51, "TES3::Land::WNAM failed size validation");

	void __fastcall OnDrawBaseCell(TES3::Land * land, DWORD _UNUSED_, WNAM * wnam, NI::PixelRGB * pixelBuffer, unsigned int pixelBufferSize) {
		if (wnam == nullptr || pixelBuffer == nullptr) {
			return;
		}

		if (land->gridX < cellMinX || land->gridX > cellMaxX || land->gridY < cellMinY || land->gridY > cellMaxY) {
			return;
		}

		int offsetX = (land->gridX - cellMinX) * cellResolution;
		int offsetY = (land->gridY * -1 - cellMinY) * cellResolution;

		NI::PixelRGB pixelColor;
		for (size_t y = 0; y < cellResolution; y++) {
			for (size_t x = 0; x < cellResolution; x++) {
				size_t pixelOffset = (y + offsetY) * mapWidth + x + offsetX;

				if (pixelOffset * 3 > pixelBufferSize) {
					return;
				}

				size_t mappedX = 9 * x / cellResolution;
				size_t mappedY = 9 * y / cellResolution;
				float heightData = 16 * wnam->data[8 - mappedY].data[mappedX];
				float clippedData = heightData / 2048;
				clippedData = max(-1.0f, min(clippedData, 1.0f));

				// Above ocean level.
				if (heightData >= 0.0f) {
					// Darker heightmap threshold.
					if (clippedData > 0.3f) {
						float base = (clippedData - 0.3f) * 1.428f;
						pixelColor.r = 34.0f - base * 29.0f;
						pixelColor.g = 25.0f - base * 20.0f;
						pixelColor.b = 17.0f - base * 12.0f;
					}
					// Lighter heightmap threshold.
					else {
						float base = (clippedData > 0.1f) ? clippedData - 0.1f + 0.8f : clippedData * 8.0f;
						pixelColor.r = 66.0f - base * 32.0f;
						pixelColor.g = 48.0f - base * 23.0f;
						pixelColor.b = 33.0f - base * 16.0f;
					}
				}
				// Underwater, fade out towards the water color.
				else {
					pixelColor.r = 38.0f + clippedData * 14.0f;
					pixelColor.g = 56.0f + clippedData * 20.0f;
					pixelColor.b = 51.0f + clippedData * 18.0f;
				}

				pixelBuffer[pixelOffset] = pixelColor;
			}
		}
	}

	TES3::Cell * lastVisitedInteriorCell = nullptr;
	TES3::Vector3 lastPlayerPosition;
	float lastPlayerRotation = 0.0f;

	bool __cdecl OnUpdatePlayerPosition(TES3::UI::Element * mapMenu) {
		// If we weren't given a map menu, find it.
		if (mapMenu == nullptr) {
			mapMenu = TES3::UI::findMenu(*reinterpret_cast<TES3::UI::UI_ID*>(0x7D45F2));
			if (mapMenu == nullptr) {
				return false;
			}
		}

		// Get our local/world markers.
		auto localMarker = mapMenu->findChild(*reinterpret_cast<TES3::UI::UI_ID*>(0x7D4642));
		auto worldMarker = mapMenu->findChild(*reinterpret_cast<TES3::UI::UI_ID*>(0x7D4784));
		auto worldMapPane = mapMenu->findChild(*reinterpret_cast<TES3::UI::UI_ID*>(0x7D4714));
		if (localMarker == nullptr || worldMarker == nullptr) {
			return false;
		}

		// Update map marker rotation.
		auto player = mwse::tes3::getWorldController()->getMobilePlayer();
		float playerZRot = player->reference->orientation.z * -1;
		if (lastPlayerRotation != playerZRot) {
			TES3::Matrix33 rotationMatrix;
			rotationMatrix.toRotationY(player->reference->orientation.z * -1);

			localMarker->node_88->setLocalRotationMatrix(&rotationMatrix);
			localMarker->node_88->propagatePositionChange();
			worldMarker->node_88->setLocalRotationMatrix(&rotationMatrix);
			worldMarker->node_88->propagatePositionChange();

			lastPlayerRotation = playerZRot;
		}

		auto playerPosition = player->reference->position;
		if (lastPlayerPosition != playerPosition) {
			auto dataHandler = mwse::tes3::getDataHandler();
			if (dataHandler->currentInteriorCell) {
				
			}
			else {
				worldMarker->positionX = ((playerPosition.x / 8192) - cellMinX) * cellResolution * zoomLevel;
				worldMarker->positionY = ((playerPosition.y / -8192) - cellMinY + 1) * cellResolution * zoomLevel * -1;

				worldMarker->flagPosChanged = true;
				worldMarker->timingUpdate();
				mapMenu->timingUpdate();
			}

			lastPlayerPosition = playerPosition;
		}

		return true;
	}

	// Initialize our patches based on a lua function, so it can be semi-easily disabled.
	int patchWorldMap(lua_State* L) {
		luaState = L;

		std::srand(std::time(nullptr));

		// Load config from lua.
		lua_settop(L, 1);
		luaL_checktype(L, 1, LUA_TTABLE);

		lua_getfield(L, 1, "autoExpand");
		updateMapBounds = lua_toboolean(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, 1, "cellResolution");
		cellResolution = luaL_checknumber(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, 1, "minX");
		cellMinX = luaL_checknumber(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, 1, "maxX");
		cellMaxX = luaL_checknumber(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, 1, "minY");
		cellMinY = luaL_checknumber(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, 1, "maxY");
		cellMaxY = luaL_checknumber(L, -1);
		lua_pop(L, 1);

		// Default map. We need to remove some code so we can do our own thing.
		mwse::genCallEnforced(0x4BB5A0, 0x4C8070, reinterpret_cast<DWORD>(OnAllocateMapDefault));
		mwse::genNOPUnprotected(0x4BB5A5, 0x34);

		// Actually create the map.
		mwse::genCallEnforced(0x4C80F4, 0x6D4FC0, reinterpret_cast<DWORD>(OnCreateMapPixelData));

		// Loading and validation.
		mwse::genCallEnforced(0x4C8002, 0x4C8070, reinterpret_cast<DWORD>(OnLoadMAPHChunk));

		// Draw cells.
		mwse::genCallEnforced(0x4E32FE, 0x4C81C0, reinterpret_cast<DWORD>(OnDrawCell));

		// Draw base cells.
		mwse::genCallEnforced(0x4CACE7, 0x4CE800, reinterpret_cast<DWORD>(OnDrawBaseCell));
		mwse::genCallEnforced(0x4CEBB5, 0x4CE800, reinterpret_cast<DWORD>(OnDrawBaseCell));

		// Update from player movement.
		mwse::genCallEnforced(0x5E9701, 0x5EC250, reinterpret_cast<DWORD>(OnUpdatePlayerPosition));
		mwse::genCallEnforced(0x5E9733, 0x5EC250, reinterpret_cast<DWORD>(OnUpdatePlayerPosition));
		mwse::genCallEnforced(0x5EB798, 0x5EC250, reinterpret_cast<DWORD>(OnUpdatePlayerPosition));
		mwse::genCallEnforced(0x5EB7DD, 0x5EC250, reinterpret_cast<DWORD>(OnUpdatePlayerPosition));
		mwse::genCallEnforced(0x5EC1FC, 0x5EC250, reinterpret_cast<DWORD>(OnUpdatePlayerPosition));
		mwse::genCallEnforced(0x5ED712, 0x5EC250, reinterpret_cast<DWORD>(OnUpdatePlayerPosition));
		mwse::genCallEnforced(0x5ED965, 0x5EC250, reinterpret_cast<DWORD>(OnUpdatePlayerPosition));
		mwse::genCallEnforced(0x736C9E, 0x5EC250, reinterpret_cast<DWORD>(OnUpdatePlayerPosition));

		lua_pushboolean(L, true);
		return 1;
	}

	int setMapZoom(lua_State* L) {
		zoomLevel = luaL_checknumber(L, 1);

		auto menuMap = TES3::UI::findMenu(*reinterpret_cast<TES3::UI::UI_ID*>(0x7D45F2));
		auto worldMap = menuMap->findChild(*reinterpret_cast<TES3::UI::UI_ID*>(0x7D4714));
		if (worldMap == nullptr) {
			lua_pushboolean(L, false);
			return 1;
		}

		float scaledSize = mapResolution * zoomLevel;
		worldMap->width = scaledSize;
		worldMap->height = scaledSize;

		auto vertsA = reinterpret_cast<int*>(worldMap->vectorVerts_40.begin);
		vertsA[5] = scaledSize * -1;
		vertsA[7] = scaledSize;
		vertsA[10] = scaledSize;
		vertsA[11] = scaledSize * -1;

		auto vertsB = reinterpret_cast<float*>(worldMap->vector_60.begin);
		vertsB[0] = 1.0f / scaledSize;
		vertsB[1] = -1.0f / scaledSize;

		worldMap->flagVisibilityChanged = true;
		worldMap->updateSceneGraph();

		lua_pushboolean(L, true);
		return 1;
	}
}
