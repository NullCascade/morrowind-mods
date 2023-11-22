#include "PatchWorldMap.h"

#include "stdafx.h"

#include <sol/sol.hpp>

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
#include <unordered_map>

namespace UIEXT {
	static lua_State* luaState = nullptr;

	static bool updateMapBounds = false;
	static int cellResolution = 9;
	static int cellMinX = 0;
	static int cellMaxX = 0;
	static int cellMinY = 0;
	static int cellMaxY = 0;

	static unsigned int mapWidth = 0;
	static unsigned int mapHeight = 0;

	float zoomLevel = 1.0;

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

	const auto TES3_NiPixelData_ctor = reinterpret_cast<void* (__thiscall*)(void*, unsigned int, unsigned int, void*, unsigned int)>(0x6D4FC0);
	void* __fastcall OnCreateMapPixelData(void* pixelData, DWORD _UNUSUED_, unsigned int width, unsigned int height, void* format, unsigned int mipMapLevels) {
		mapWidth = getNextHighestPowerOf2((cellMaxX - cellMinX + 1) * cellResolution);
		mapHeight = getNextHighestPowerOf2((cellMaxY - cellMinY + 1) * cellResolution);
		return TES3_NiPixelData_ctor(pixelData, mapWidth, mapHeight, format, mipMapLevels);
	}

	//
	// Loading a new game, figure out the map size before allocation.
	//

	const auto TES3_NonDynamicData_allocateMap = reinterpret_cast<void(__thiscall*)(TES3::NonDynamicData*)>(0x4C8070);
	void __fastcall OnAllocateMapDefault(TES3::NonDynamicData* nonDynamicData) {
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
				int cellPixelDimension;
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

	bool convertMAPD = false;

	bool __fastcall OnLoadMAPHChunk(TES3::GameFile* saveFile, DWORD _UNUSED_, MAPH* data, unsigned int dataSize) {
		// Actually load our data.
		if (!saveFile->readChunkData(data, dataSize)) {
			return false;
		}

		// Check if the map is vanilla format.
		if (data->vanillaData.mapResolution == 512 && data->vanillaData.cellPixelDimension == 9) {
			convertMAPD = true;
			return true;
		}

		// If our data differs, return invalid data so we don't load the map.
		if (data->uiextData.cellMinX != cellMinX || data->uiextData.cellMaxX != cellMaxX ||
			data->uiextData.cellMinY != cellMinY || data->uiextData.cellMaxY != cellMaxY) {
			data->vanillaData.mapResolution = 0;
			data->vanillaData.cellPixelDimension = 0;
		}
		// If it does match, let the system think the values are what it wants. They're thrown away.
		else {
			data->vanillaData.mapResolution = 512;
			data->vanillaData.cellPixelDimension = 9;
		}

		convertMAPD = false;
		return true;
	}

	bool __fastcall OnLoadMAPDChunk(TES3::GameFile* saveFile, DWORD _UNUSED_, char* data, unsigned int dataSize) {
		auto mapTexture = TES3::DataHandler::get()->nonDynamicData->mapTexture;
		auto pixelData = mapTexture->pixelData;
		auto pixelBuffer = (NI::PixelRGB*)&pixelData->pixels[pixelData->offsets[0]];
		auto pixelBufferSize = pixelData->offsets[1] - pixelData->offsets[0];
		const size_t vanillaMapSize = 0xC0000, vanillaStride = 512 * sizeof(NI::PixelRGB);

		if (!convertMAPD) {
			// Read extended map image.
			saveFile->readChunkData(pixelBuffer, sizeof(NI::PixelRGB) * mapWidth * mapHeight);
		}
		else if (saveFile->currentChunkHeader.size == vanillaMapSize) {
			// Copy vanilla map image to correct location in the extended map.
			auto buffer = std::make_unique<char[]>(vanillaMapSize);
			saveFile->readChunkData(buffer.get(), vanillaMapSize);

			int offsetX = (0 - cellMinX) * cellResolution - 256;
			int offsetY = (cellMaxY - 0) * cellResolution - 256;
			const char* from = buffer.get();

			if (offsetX >= 0 && offsetY >= 0) {
				for (int y = 0; y < 512; y++, from += vanillaStride) {
					size_t pixelOffset = (y + offsetY) * mapWidth + offsetX;
					if ((pixelOffset * sizeof(NI::PixelRGB) + vanillaStride) >= pixelBufferSize) {
						break;
					}
					memcpy(&data[pixelOffset * sizeof(NI::PixelRGB)], from, vanillaStride);
				}
			}
		}

		return true;
	}

	//
	// Saving to the file. This will write our custom resolution information to the save.
	//

	int __fastcall OnSaveMAPHChunk(TES3::GameFile* saveFile, DWORD _UNUSED_, DWORD tag, MAPH* data, unsigned int size) {
		data->uiextData.cellMinX = cellMinX;
		data->uiextData.cellMaxX = cellMaxX;
		data->uiextData.cellMinY = cellMinY;
		data->uiextData.cellMaxY = cellMaxY;

		return saveFile->writeChunkData(tag, data, size);
	}

	int __fastcall OnSaveMAPDChunk(TES3::GameFile* saveFile, DWORD _UNUSED_, DWORD tag, void* data, unsigned int size) {
		size_t realSize = sizeof(NI::PixelRGB) * mapWidth * mapHeight;
		return saveFile->writeChunkData(tag, data, realSize);
	}

	//
	// Draw cell location marker.
	// 

	void __fastcall OnDrawLocationMarker(TES3::Cell* cell) {
		auto mapTexture = TES3::DataHandler::get()->nonDynamicData->mapTexture;
		if (!mapTexture) {
			return;
		}

		auto pixelData = mapTexture->pixelData;
		auto pixelBuffer = (NI::PixelRGB*)&pixelData->pixels[pixelData->offsets[0]];
		auto pixelBufferSize = pixelData->offsets[1] - pixelData->offsets[0];

		int gridX = cell->getGridX(), gridY = cell->getGridY();
		if (gridX < cellMinX || gridX > cellMaxX || gridY < cellMinY || gridY > cellMaxY) {
			return;
		}

		// Draw square marker.
		int offsetX = (gridX - cellMinX) * cellResolution;
		int offsetY = (cellMaxY - gridY) * cellResolution;
		int leftTop = cellResolution / 4, rightBottom = cellResolution - (cellResolution / 4) - 1;
		NI::PixelRGB col = { 0xCA, 0xA5, 0x60 };

		for (size_t y = leftTop; y <= rightBottom; y++) {
			for (size_t x = leftTop; x <= rightBottom; x++) {
				if (x == leftTop || x == rightBottom || y == leftTop || y == rightBottom) {
					size_t pixelOffset = (y + offsetY) * mapWidth + offsetX + x;
					if (pixelOffset * sizeof(NI::PixelRGB) >= pixelBufferSize) {
						break;
					}

					pixelBuffer[pixelOffset] = col;
				}
			}
		}

		// Update flags.
		pixelData->revisionID++;
		cell->cellFlags |= TES3::CellFlag::MarkerDrawn;
		cell->vTable.base->setObjectModified(cell, true);
	}

	//
	// Attempt to draw a cell when it is explored.
	//

	static std::unordered_map<DWORD, NI::PixelRGB> colorMap;

	void __fastcall OnDrawCell(TES3::NonDynamicData* nonDynamicData, DWORD _UNUSED_, TES3::Cell* cell) {
		if (cell->getIsInterior()) {
			return;
		}

		auto mappingVisuals = cell->mappingVisuals;
		if (!mappingVisuals) {
			return;
		}

		auto textureSource = mappingVisuals->texture;
		if (!textureSource) {
			return;
		}

		const auto worldController = TES3::WorldController::get();
		const auto sourceBuffer = (NI::PixelRGBA*)&textureSource->pixelData->pixels[textureSource->pixelData->offsets[0]];
		const auto sourceWidth = worldController->mapRenderTarget.targetWidth;
		const auto sourceDivision = float(worldController->mapRenderTarget.targetHeight) / float(cellResolution + 1);

		auto pixelData = TES3::DataHandler::get()->nonDynamicData->mapTexture->pixelData;
		auto pixelBuffer = (NI::PixelRGB*)&pixelData->pixels[pixelData->offsets[0]];
		auto pixelBufferSize = pixelData->offsets[1] - pixelData->offsets[0];

		int gridX = cell->getGridX(), gridY = cell->getGridY();
		int offsetX = (gridX - cellMinX) * cellResolution;
		int offsetY = (cellMaxY - gridY) * cellResolution;

		for (size_t y = 0; y < cellResolution; y++) {
			size_t pixelOffset = (y + offsetY) * mapWidth + offsetX;

			for (size_t x = 0; x < cellResolution; x++, pixelOffset++) {
				if (pixelOffset * sizeof(NI::PixelRGB) >= pixelBufferSize) {
					// Break to complete rest of update instead of returning.
					break;
				}

				NI::PixelRGB col = pixelBuffer[pixelOffset];
				if (col.r < 24 || col.r > 36 || col.g < 36 || col.g > 56 || col.b < 33 || col.b > 51) {
					int sourceOffset = int((y + 0.5f) * sourceDivision * sourceWidth) + int((x + 0.5f) * sourceDivision);
					pixelBuffer[pixelOffset] = sourceBuffer[sourceOffset];
				}
			}
		}
		++pixelData->revisionID;

		if (cell->name) {
			OnDrawLocationMarker(cell);
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

	void __fastcall OnDrawBaseCell(TES3::Land* land, DWORD _UNUSED_, WNAM* wnam, NI::PixelRGB* pixelBuffer, unsigned int pixelBufferSize) {
		if (wnam == nullptr || pixelBuffer == nullptr) {
			return;
		}

		if (land->gridX < cellMinX || land->gridX > cellMaxX || land->gridY < cellMinY || land->gridY > cellMaxY) {
			return;
		}

		const int offsetX = (land->gridX - cellMinX) * cellResolution;
		const int offsetY = (cellMaxY - land->gridY) * cellResolution;

		NI::PixelRGB pixelColor;
		for (size_t y = 0; y < cellResolution; y++) {
			size_t pixelOffset = (y + offsetY) * mapWidth + offsetX;

			for (size_t x = 0; x < cellResolution; x++, pixelOffset++) {
				if (pixelOffset * sizeof(NI::PixelRGB) >= pixelBufferSize) {
					return;
				}

				size_t mappedX = 9 * x / cellResolution;
				size_t mappedY = 9 * y / cellResolution;
				float heightData = 16 * wnam->data[8 - mappedY].data[mappedX];
				float clippedData = heightData / 2048;
				clippedData = std::max(-1.0f, std::min(clippedData, 1.0f));

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

	//
	// UI functions.
	//

	const auto ui_id_MenuMap = reinterpret_cast<TES3::UI::UI_ID*>(0x7D45F2);
	const auto ui_id_MenuMulti = reinterpret_cast<TES3::UI::UI_ID*>(0x7D4AB0);
	const auto ui_id_MenuMap_local_map = reinterpret_cast<TES3::UI::UI_ID*>(0x7D4640);
	const auto ui_id_MenuMap_world_map = reinterpret_cast<TES3::UI::UI_ID*>(0x7D476C);
	const auto ui_id_MenuMap_local_marker = reinterpret_cast<TES3::UI::UI_ID*>(0x7D4642);
	const auto ui_id_MenuMap_world_marker = reinterpret_cast<TES3::UI::UI_ID*>(0x7D4784);
	const auto ui_id_MenuMap_world_pane = reinterpret_cast<TES3::UI::UI_ID*>(0x7D4714);
	const auto ui_id_MenuMap_world_panel = reinterpret_cast<TES3::UI::UI_ID*>(0x7D45E0);

	TES3::Cell* lastVisitedInteriorCell = nullptr;
	TES3::Vector3 lastExteriorPlayerPosition;
	float lastPlayerRotation = 0.0f;

	bool __cdecl OnUpdatePlayerPosition(TES3::UI::Element* mapMenu) {
		// mapMenu may be either the main map and mini-map.

		// If we weren't given a map menu, find it.
		if (mapMenu == nullptr) {
			mapMenu = TES3::UI::findMenu(*ui_id_MenuMap);
			if (mapMenu == nullptr) {
				return false;
			}
		}

        if (mapMenu == TES3::UI::findMenu(*ui_id_MenuMulti)) {
            // Mini-map.
            
            // Update map marker rotation.
            const auto player = TES3::WorldController::get()->getMobilePlayer();
            float playerZRot = player->reference->orientation.z * -1;
            auto localMarker = mapMenu->findChild(*ui_id_MenuMap_local_marker);

            TES3::Matrix33 rotationMatrix;
            rotationMatrix.toRotationY(playerZRot);

            localMarker->sceneNode->setLocalRotationMatrix(&rotationMatrix);
            localMarker->sceneNode->update();
        }
        else {
            // Main map.

            // Get our local/world markers.
            auto localMarker = mapMenu->findChild(*ui_id_MenuMap_local_marker);
            auto worldMarker = mapMenu->findChild(*ui_id_MenuMap_world_marker);
            auto worldMapPane = mapMenu->findChild(*ui_id_MenuMap_world_pane);
            if (localMarker == nullptr || worldMarker == nullptr) {
                return false;
            }

            // Update map marker rotation.
            const auto player = TES3::WorldController::get()->getMobilePlayer();
            float playerZRot = player->reference->orientation.z * -1;
            if (lastPlayerRotation != playerZRot) {
                TES3::Matrix33 rotationMatrix;
                rotationMatrix.toRotationY(playerZRot);

                localMarker->sceneNode->setLocalRotationMatrix(&rotationMatrix);
                localMarker->sceneNode->update();
                worldMarker->sceneNode->setLocalRotationMatrix(&rotationMatrix);
                worldMarker->sceneNode->update();

                lastPlayerRotation = playerZRot;
            }

            // Update map marker position.
			auto localMap = mapMenu->findChild(*ui_id_MenuMap_local_map);
			auto worldMap = mapMenu->findChild(*ui_id_MenuMap_world_map);
			auto playerPosition = player->reference->position;

			if (localMap && localMap->visibleAtLastUpdate) {
				auto localMapPos = playerPosition;

				const auto TES3UI_MenuMap_calcLocalMapPos = reinterpret_cast<void(__cdecl*)(TES3::Vector3*, int)>(0x5ED190);
				TES3UI_MenuMap_calcLocalMapPos(&localMapPos, 512);
				localMarker->positionX = localMapPos.x;
				localMarker->positionY = localMapPos.y;
				localMarker->flagPosChanged = true;
			}
			if (worldMap && worldMap->visibleAtLastUpdate) {
				if (TES3::DataHandler::get()->currentInteriorCell == nullptr) {
					if (lastExteriorPlayerPosition != playerPosition) {
						worldMarker->positionX = ((playerPosition.x / 8192) - cellMinX) * cellResolution * zoomLevel;
						worldMarker->positionY = -(cellMaxY + 1 - (playerPosition.y / 8192)) * cellResolution * zoomLevel;
						worldMarker->flagPosChanged = true;
						mapMenu->timingUpdate();

						lastExteriorPlayerPosition = playerPosition;
					}
				}
			}
        }

        return true;
	}

	TES3::Cell* __fastcall OnFindCellAtMouse(TES3::UI::Element* element, DWORD _UNUSED_, int mouseX, int mouseY) {
		const int cursorOffset = 4;
		int x = mouseX - element->cached_screenX, y = element->cached_screenY - mouseY + cursorOffset;
		int cellX = std::floor(cellMinX + x / (cellResolution * zoomLevel));
		int cellY = std::floor(cellMaxY - y / (cellResolution * zoomLevel)) + 1;

		auto cell = TES3::DataHandler::get()->nonDynamicData->getCellByGrid(cellX, cellY);
		if (cell && (cell->cellFlags & TES3::CellFlag::MarkerDrawn)) {
			return cell;
		}
		return nullptr;
	}

	//
	// API functions.
	//

	int setMapZoom(lua_State* L) {
		const auto previousZoom = zoomLevel;
		zoomLevel = luaL_checknumber(L, 1);

		auto menuMap = TES3::UI::findMenu(*ui_id_MenuMap);
		auto worldMap = menuMap->findChild(*ui_id_MenuMap_world_pane);
		if (worldMap == nullptr) {
			lua_pushboolean(L, false);
			return 1;
		}

		// Update map pane scaling.
		float scaledWidth = mapWidth * zoomLevel, scaledHeight = mapHeight * zoomLevel;
		worldMap->width = scaledWidth;
		worldMap->height = scaledHeight;

		auto vertsA = reinterpret_cast<int*>(worldMap->vectorVerts_40.first);
		vertsA[5] = scaledHeight * -1;
		vertsA[7] = scaledWidth;
		vertsA[10] = scaledWidth;
		vertsA[11] = scaledHeight * -1;

		auto vertsB = reinterpret_cast<float*>(worldMap->vector_60.first);
		vertsB[0] = 1.0f / scaledWidth;
		vertsB[1] = -1.0f / scaledHeight;

		worldMap->flagVisibilityChanged = true;
		worldMap->updateSceneGraph();

		// Fix up scroll offset to keep the centre point in place.
		auto panel = menuMap->findChild(*ui_id_MenuMap_world_panel);
		float ratio = zoomLevel / previousZoom;
		int panelCentreX = panel->width / 2, panelCentreY = panel->height / 2;
		panel->childOffsetX = -(int((-panel->childOffsetX + panelCentreX) * ratio) - panelCentreX);
		panel->childOffsetY = int((panel->childOffsetY + panelCentreY) * ratio) - panelCentreY;
		panel->timingUpdate();

		// Update player world marker position.
		auto worldMarker = menuMap->findChild(*ui_id_MenuMap_world_marker);

		if (worldMarker) {
			worldMarker->positionX = ((lastExteriorPlayerPosition.x / 8192) - cellMinX) * cellResolution * zoomLevel;
			worldMarker->positionY = -(cellMaxY + 1 - (lastExteriorPlayerPosition.y / 8192)) * cellResolution * zoomLevel;
			worldMarker->flagPosChanged = true;

			menuMap->timingUpdate();
		}

		lua_pushboolean(L, true);
		return 1;
	}

	int centreOnPlayer(lua_State* L) {
		auto menuMap = TES3::UI::findMenu(*ui_id_MenuMap);
		auto worldMap = menuMap->findChild(*ui_id_MenuMap_world_pane);
		if (worldMap == nullptr) {
			lua_pushboolean(L, false);
			return 1;
		}

		const auto dataHandler = TES3::DataHandler::get();
		const auto cell = dataHandler->lastExteriorCell;
		auto panel = menuMap->findChild(*ui_id_MenuMap_world_panel);
		auto worldMarker = menuMap->findChild(*ui_id_MenuMap_world_marker);

		if (worldMarker) {
			int panelCentreX = panel->width / 2, panelCentreY = panel->height / 2;
			panel->childOffsetX = -(worldMarker->positionX - panelCentreX);
			panel->childOffsetY = -(worldMarker->positionY + panelCentreY);

			// Cancel alpha fadeout for markers at the edge or outside of the visible area.
			worldMarker->colourAlpha = 1.0f;
			worldMarker->flagColourChanged = true;
			worldMarker->visible = true;
			worldMarker->flagVisibilityChanged = true;

			menuMap->timingUpdate();
		}

		lua_pushboolean(L, true);
		return 1;
	}

	// Initialize our patches based on a lua function, so it can be semi-easily disabled.
	int patchWorldMap(lua_State* L) {
		luaState = L;

		//std::srand(std::time(nullptr));

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
		mwse::genNOPUnprotected(0x4BB5A5, 0x36);

		// Actually create the map.
		mwse::genCallEnforced(0x4C80F4, 0x6D4FC0, reinterpret_cast<DWORD>(OnCreateMapPixelData));

		// Loading and validation.
		mwse::genCallEnforced(0x4C8002, 0x4B6880, reinterpret_cast<DWORD>(OnLoadMAPHChunk));
		mwse::genNOPUnprotected(0x4C801E, 0x7);
		mwse::genCallEnforced(0x4C803E, 0x4B6880, reinterpret_cast<DWORD>(OnLoadMAPDChunk));
		mwse::genCallEnforced(0x4C803E, 0x736A20, reinterpret_cast<DWORD>(OnLoadMAPDChunk)); // MCP

		// Saving.
		mwse::genCallEnforced(0x4BCCAA, 0x4B6BA0, reinterpret_cast<DWORD>(OnSaveMAPHChunk));
		mwse::genCallEnforced(0x4BCCBC, 0x4B6BA0, reinterpret_cast<DWORD>(OnSaveMAPDChunk));
		mwse::genCallEnforced(0x4BCCBC, 0x736A70, reinterpret_cast<DWORD>(OnSaveMAPDChunk)); // MCP

		// Draw cells.
		mwse::genCallEnforced(0x4E32FE, 0x4C81C0, reinterpret_cast<DWORD>(OnDrawCell));

		// Draw cell location markers.
		const BYTE patchDrawLocationMarker[] = {
			0x57,			// push edi
			0x8B, 0xCB		// mov ecx, ebx
		};
		mwse::writeBytesUnprotected(0x4C855D, patchDrawLocationMarker, sizeof(patchDrawLocationMarker));
		mwse::genCallUnprotected(0x4C8560, reinterpret_cast<DWORD>(OnDrawLocationMarker));
		mwse::genJumpUnprotected(0x4C8565, 0x4C864A);

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

		// Find cell for mouseover.
		const BYTE patchFindCellAtMouse[] = {
			0x8B, 0x44, 0x24, 0x40,		// mov eax, [mouseX]
			0x8B, 0x54, 0x24, 0x44,		// mov edx, [mouseY]
			0x52,						// push edx
			0x50,						// push eax
		};
		mwse::writeBytesUnprotected(0x5EF331, patchFindCellAtMouse, sizeof(patchFindCellAtMouse));
		mwse::genJumpUnprotected(0x5EF331 + sizeof(patchFindCellAtMouse), 0x5EF3DA);
		mwse::genCallEnforced(0x5EF3DC, 0x4C8680, reinterpret_cast<DWORD>(OnFindCellAtMouse));

		lua_pushboolean(L, true);
		return 1;
	}

	int getMapData(lua_State* L) {
		lua_createtable(L, 0, 4);

		lua_pushnumber(L, cellResolution);
		lua_setfield(L, -2, "cellResolution");
		lua_pushnumber(L, mapWidth);
		lua_setfield(L, -2, "mapWidth");
		lua_pushnumber(L, mapHeight);
		lua_setfield(L, -2, "mapHeight");

		return 1;
	}
}
