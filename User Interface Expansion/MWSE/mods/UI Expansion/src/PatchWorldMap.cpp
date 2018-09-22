#include "PatchWorldMap.h"

#include "stdafx.h"

#include <TES3Cell.h>
#include <TES3DataHandler.h>
#include <TES3GameFile.h>
#include <TES3Land.h>
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

#define RESOLUTION_PER_CELL 9

namespace UIEXT {
	static lua_State * luaState = nullptr;

	static int cellMinX = -142;
	static int cellMaxX = 49;
	static int cellMinY = -59;
	static int cellMaxY = 29;

	static unsigned int mapWidth = 0;
	static unsigned int mapHeight = 0;

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

	// Loop through all the cells and figure out where our map bounds should be.
	void loadCellRanges() {
		// Figure out the cell ranges.
		auto cellNode = mwse::tes3::getDataHandler()->nonDynamicData->cells->head;
		while (cellNode) {
			TES3::Cell * cell = cellNode->data;
			if (cell->isInterior()) {
				cellNode = cellNode->next;
				continue;
			}

			int x = cell->getGridX();
			if (x < cellMinX) {
				cellMinX = x;
			}
			else if (x > cellMaxX) {
				cellMaxX = x;
			}

			int y = cell->getGridY();
			if (y < cellMinY) {
				cellMinY = y;
			}
			else if (y > cellMaxY) {
				cellMaxY = y;
			}

			cellNode = cellNode->next;
		}

		std::stringstream ss;
		ss << "print(\"Cell X range: " << cellMinX << " -> " << cellMaxX << "; Cell Y range: " << cellMinY << " -> " << cellMaxY << "\")";
		luaL_dostring(luaState, ss.str().c_str());
	}

	//
	// When allocating space for our map, use the new size.
	//

	const auto TES3_NiPixelData_ctor = reinterpret_cast<void*(__thiscall *)(void*, unsigned int, unsigned int, void*, unsigned int)>(0x6D4FC0);
	void * __fastcall OnCreateMapPixelData(void * pixelData, DWORD _UNUSUED_, unsigned int width, unsigned int height, void * format, unsigned int mipMapLevels) {
		mapWidth = getNextHighestPowerOf2((cellMaxX - cellMinX) * RESOLUTION_PER_CELL);
		mapHeight = getNextHighestPowerOf2((cellMaxY - cellMinY) * RESOLUTION_PER_CELL);
		size_t largerResolution = max(mapWidth, mapHeight);

		mwse::log::getLog() << "Creating map. Resolution: " << std::dec << mapWidth << ", " << mapHeight << std::endl;
		return TES3_NiPixelData_ctor(pixelData, largerResolution, largerResolution, format, mipMapLevels);
	}

	//
	// Loading a new game, figure out the map size before allocation.
	//

	const auto TES3_NonDynamicData_allocateMap = reinterpret_cast<void(__thiscall *)(TES3::NonDynamicData*)>(0x4C8070);
	void __fastcall OnAllocateMapDefault(TES3::NonDynamicData * nonDynamicData) {
#if true
		// Figure out our map bounds.
		loadCellRanges();

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
#endif
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

	const auto TES3_GameFile_getChunkData = reinterpret_cast<void(__thiscall *)(TES3::NonDynamicData*)>(0x4C8070);

	bool __fastcall OnLoadMAPHChunk(TES3::GameFile * saveFile, DWORD _UNUSED_, MAPH* data, unsigned int dataSize) {
		// Actually load our data.
		if (!saveFile->getChunkData(data, dataSize)) {
			return false;
		}

		// Load our cell ranges.
		loadCellRanges();

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

		int offsetX = (land->gridX - cellMinX) * RESOLUTION_PER_CELL;
		int offsetY = (land->gridY * -1 - cellMinY) * RESOLUTION_PER_CELL;

		NI::PixelRGB pixelColor;
		for (size_t y = 0; y < 9; y++) {
			for (size_t x = 0; x < 9; x++) {
				size_t pixelOffset = (y + offsetY) * mapWidth + x + offsetX;

				if (pixelOffset * 3 > pixelBufferSize) {
					return;
				}

				float heightData = 16 * wnam->data[8 - y].data[x];
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

	// Initialize our patches based on a lua function, so it can be semi-easily disabled.
	int patchWorldMap(lua_State* L) {
		luaState = L;

		std::srand(std::time(nullptr));

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

		lua_pushboolean(L, true);
		return 1;
	}


	double zoomLevel = 0.0;

	int setMapZoom(lua_State* L) {
		zoomLevel = luaL_checknumber(L, 1);
		mwse::log::getLog() << "Setting zoom level: " << zoomLevel << std::endl;

		auto menuMap = TES3::UI::findMenu(*reinterpret_cast<TES3::UI::UI_ID*>(0x7D45F2));
		auto worldMap = menuMap->findChild(*reinterpret_cast<TES3::UI::UI_ID*>(0x7D4714));
		if (worldMap == nullptr) {
			lua_pushboolean(L, false);
			return 1;
		}

		int scaledSize = 1024 * zoomLevel;
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
