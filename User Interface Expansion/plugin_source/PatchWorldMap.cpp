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

	static bool autoMapBounds = false;
	static int cellResolution = 9;
	static int cellMinX = 0;
	static int cellMaxX = 0;
	static int cellMinY = 0;
	static int cellMaxY = 0;

	static unsigned int mapWidth = 0;
	static unsigned int mapHeight = 0;

	typedef unsigned char VisitedFlag;
	static std::vector<VisitedFlag> visitedMapCells;

	float zoomLevel = 1.0;

	const NI::PixelRGB seaColor{ 24, 36, 33 };

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

	bool isPositionInMap(int gridX, int gridY) {
		return !(gridX < cellMinX || gridX > cellMaxX || gridY < cellMinY || gridY > cellMaxY);
	}

	//
	// When allocating space for our map, use the new size.
	//

	const auto TES3_NiPixelData_ctor = reinterpret_cast<void* (__thiscall*)(void*, unsigned int, unsigned int, void*, unsigned int)>(0x6D4FC0);
	void* __fastcall OnCreateMapPixelData(void* pixelData, DWORD _UNUSUED_, unsigned int width, unsigned int height, void* format, unsigned int mipMapLevels) {
		int cellWidth = cellMaxX - cellMinX + 1;
		int cellHeight = cellMaxY - cellMinY + 1;

		// Allocate visited cells data and set to unvisited.
		visitedMapCells.resize(cellWidth * cellHeight, 0);

		// Allocate map texture.
		mapWidth = getNextHighestPowerOf2(cellWidth * cellResolution);
		mapHeight = getNextHighestPowerOf2(cellHeight * cellResolution);
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
			*pixels++ = seaColor;
		}
	}

	//
	// Draw cell location marker.
	// 

	void __fastcall OnDrawLocationMarker(TES3::Cell* cell) {
		// Always update cell flags. This allows markers to be re-drawn later, even if they fail initially.
		cell->cellFlags |= TES3::CellFlag::MarkerDrawn;
		cell->vTable.base->setObjectModified(cell, true);

		auto mapTexture = TES3::DataHandler::get()->nonDynamicData->mapTexture;
		if (!mapTexture) {
			return;
		}

		auto pixelData = mapTexture->pixelData;
		auto pixelBuffer = reinterpret_cast<NI::PixelRGB*>(&pixelData->pixels[pixelData->offsets[0]]);
		auto pixelBufferSize = pixelData->offsets[1] - pixelData->offsets[0];

		// Check drawable map bounds.
		int gridX = cell->getGridX(), gridY = cell->getGridY();
		if (!isPositionInMap(gridX, gridY)) {
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
		pixelData->revisionID++;
	}

	//
	// Save game map serialization.
	//

	struct MAPH {
		int mapResolution;
		int cellResolution;
	};
	static_assert(sizeof(MAPH) == 0x8, "MAPH failed size validation");

	struct MAPE {
		unsigned short version;
		unsigned short cellResolution;
		short cellMinX;
		short cellMaxX;
		short cellMinY;
		short cellMaxY;
	} extendedHeader;
	static_assert(sizeof(MAPE) == 0xC, "MAPE failed size validation");

	const unsigned int MAPE_ChunkTag = 'EPAM'; // "MAPE", little endian
	const unsigned int VSIT_ChunkTag = 'TISV'; // "VSIT", little endian
	bool flagRedrawBaseMap = false;

	//
	// Loading from a save. The loader expects MAPH values of 512 and 9. It will stop loading if given other values.
	//

	const auto TES3_GameFile_fetchNextChunk = reinterpret_cast<bool(__thiscall*)(TES3::GameFile*)>(0x4B67F0);
	const auto TES3_GameFile_getChunkHeader = reinterpret_cast<unsigned int(__thiscall*)(TES3::GameFile*)>(0x4B67C0);

	bool __fastcall OnLoadMAPHChunk(TES3::GameFile* saveFile, DWORD _UNUSED_, MAPH* data, unsigned int dataSize) {
		// Actually load our data.
		if (!saveFile->readChunkData(data, dataSize)) {
			return false;
		}

		// Redraw base map and cell markers by default, including any early out conditions.
		flagRedrawBaseMap = true;
		// Reset visited cell data.
		std::fill(visitedMapCells.begin(), visitedMapCells.end(), 0);

		// Check if the map is vanilla format.
		if (data->mapResolution == 512 && data->cellResolution == 9) {
			extendedHeader.version = 0;
			return true;
		}
		
		// Check for extended format map.
		if (data->mapResolution == -1) {
			// Read extended map header.
			if (!TES3_GameFile_fetchNextChunk(saveFile)) {
				return false;
			}

			if (TES3_GameFile_getChunkHeader(saveFile) == MAPE_ChunkTag) {
				if (!saveFile->readChunkData(&extendedHeader, sizeof(extendedHeader))) {
					return false;
				}

				// Let the loader think the values are what it expects. This allows loading to continue.
				data->mapResolution = 512;
				data->cellResolution = 9;
			}
		}

		return true;
	}

	bool __fastcall OnLoadMAPDChunk(TES3::GameFile* saveFile, DWORD _UNUSED_, char* data, unsigned int dataSize) {
		auto mapTexture = TES3::DataHandler::get()->nonDynamicData->mapTexture;
		auto pixelData = mapTexture->pixelData;
		auto pixelBuffer = reinterpret_cast<NI::PixelRGB*>(&pixelData->pixels[pixelData->offsets[0]]);
		auto pixelBufferSize = pixelData->offsets[1] - pixelData->offsets[0];

		if (extendedHeader.version == 1) {
			// Read saved extended map, which may not be the same dimensions as the current map.
			int srcWidth = (extendedHeader.cellMaxX - extendedHeader.cellMinX + 1) * cellResolution;
			int srcHeight = (extendedHeader.cellMaxY - extendedHeader.cellMinY + 1) * cellResolution;
			size_t dataSize = saveFile->currentChunkHeader.size;

			// Check saved data size. It may not match if cellResolution differs from the save game.
			if (dataSize != sizeof(NI::PixelRGB) * srcWidth * srcHeight) {
				// We cannot copy if the cell grid doesn't match.
				return true;
			}

			// Read extended map image.
			auto buffer = std::make_unique<char[]>(dataSize);
			saveFile->readChunkData(buffer.get(), dataSize);

			// Copy extended map image to correct location in the extended map texture.
			int minX = std::max(cellMinX, int(extendedHeader.cellMinX)), maxX = std::min(cellMaxX, int(extendedHeader.cellMaxX));
			int minY = std::max(cellMinY, int(extendedHeader.cellMinY)), maxY = std::min(cellMaxY, int(extendedHeader.cellMaxY));
			int copyWidth = (maxX - minX + 1) * cellResolution, copyHeight = (maxY - minY + 1) * cellResolution;

			size_t srcOffset = (extendedHeader.cellMaxY - maxY) * cellResolution * srcWidth + (minX - extendedHeader.cellMinX) * cellResolution;
			size_t destOffset = (cellMaxY - maxY) * cellResolution * mapWidth + (minX - cellMinX) * cellResolution;
			const char* srcPtr = reinterpret_cast<char*>(buffer.get()) + sizeof(NI::PixelRGB) * srcOffset;
			char* destPtr = reinterpret_cast<char*>(pixelBuffer) + sizeof(NI::PixelRGB) * destOffset;

			for (int y = 0; y < copyHeight; y++) {
				memcpy(destPtr, srcPtr, sizeof(NI::PixelRGB) * copyWidth);
				srcPtr += sizeof(NI::PixelRGB) * srcWidth;
				destPtr += sizeof(NI::PixelRGB) * mapWidth;
			}

			// Visited cell data.
			if (TES3_GameFile_fetchNextChunk(saveFile) && TES3_GameFile_getChunkHeader(saveFile) == VSIT_ChunkTag) {
				// Read visited data.
				size_t dataSize = saveFile->currentChunkHeader.size;
				auto bufferVisited = std::make_unique<char[]>(dataSize);
				saveFile->readChunkData(bufferVisited.get(), dataSize);

				// Copy loaded visited cell data to correct location.
				int srcWidth = extendedHeader.cellMaxX - extendedHeader.cellMinX + 1;
				int srcHeight = extendedHeader.cellMaxY - extendedHeader.cellMinY + 1;
				int destWidth = cellMaxX - cellMinX + 1;
				int copyWidth = (maxX - minX + 1), copyHeight = (maxY - minY + 1);

				size_t srcOffset = (extendedHeader.cellMaxY - maxY) * srcWidth + (minX - extendedHeader.cellMinX);
				size_t destOffset = (cellMaxY - maxY) * destWidth + (minX - cellMinX);
				const char* srcPtr = reinterpret_cast<char*>(bufferVisited.get()) + sizeof(VisitedFlag) * srcOffset;
				char* destPtr = reinterpret_cast<char*>(visitedMapCells.data()) + sizeof(VisitedFlag) * destOffset;

				for (int y = 0; y < copyHeight; y++) {
					memcpy(destPtr, srcPtr, sizeof(VisitedFlag) * copyWidth);
					srcPtr += sizeof(VisitedFlag) * srcWidth;
					destPtr += sizeof(VisitedFlag) * destWidth;
				}
			}

			flagRedrawBaseMap = false;
		}
		else {
			// Don't load vanilla map image, but fill in base map and cell markers after loading.
			flagRedrawBaseMap = true;
		}

		return true;
	}

	const auto TES3_Land_loadAndDrawBaseMap = reinterpret_cast<bool(__thiscall*)(TES3::Land*, unsigned char*)>(0x4CEAD0);
	void RedrawBaseMapRect(int minX, int maxX, int minY, int maxY, bool clearMarkers) {
		auto records = TES3::DataHandler::get()->nonDynamicData;
		auto pixelData = records->mapTexture->pixelData;
		auto pixelBuffer = &pixelData->pixels[pixelData->offsets[0]];
		auto pixelBufferSize = pixelData->offsets[1] - pixelData->offsets[0];

		// The region bounds are inclusive.
		// Ensure clear region is inside the texture and correctly sized.
		minX = std::max(minX, cellMinX);
		maxX = std::min(maxX, cellMaxX);
		minY = std::max(minY, cellMinY);
		maxY = std::min(maxY, cellMaxY);

		if (minX > maxX || minY > maxY) {
			return;
		}

		// Clear visited data for cells.
		for (int vy = minY; vy <= maxY; vy++) {
			for (int vx = minX; vx <= maxX; vx++) {
				visitedMapCells.at((cellMaxY - vy) * (cellMaxX - cellMinX + 1) + (vx - cellMinX)) = 0;
			}
		}

		// Clear all cells in bounds to sea, as the next part will only render cells with landscape records.
		int offsetX = (minX - cellMinX) * cellResolution, offsetY = (cellMaxY - maxY) * cellResolution;
		int clearWidth = (maxX - minX + 1) * cellResolution, clearHeight = (maxY - minY + 1) * cellResolution;
		auto pixels = reinterpret_cast<NI::PixelRGB*>(pixelBuffer);

		for (size_t y = 0; y < clearHeight; y++) {
			size_t pixelOffset = (y + offsetY) * mapWidth + offsetX;

			for (size_t x = 0; x < clearWidth; x++, pixelOffset++) {
				if (pixelOffset * sizeof(NI::PixelRGB) < pixelBufferSize) {
					pixels[pixelOffset] = seaColor;
				}
			}
		}

		// Redraw cells within bounds parameters.
		for (auto cell : *records->cells) {
			if (cell->getIsInterior()) {
				continue;
			}

			int gridX = cell->variantData.exterior.gridX, gridY = cell->variantData.exterior.gridY;
			if (gridX < minX || gridX > maxX || gridY < minY || gridY > maxY) {
				continue;
			}

			auto landscape = cell->variantData.exterior.landscape;
			if (landscape) {
				// Redraw base land. This is not guaranteed to redraw the cell if data is missing.
				TES3_Land_loadAndDrawBaseMap(landscape, pixelBuffer);
			}

			// Clear marked locations.
			if (clearMarkers) {
				cell->cellFlags &= ~TES3::CellFlag::MarkerDrawn;
			}
		}

		// Signal map change to renderer.
		pixelData->revisionID++;
	}

	void RedrawUnvisitedCells() {
		auto records = TES3::DataHandler::get()->nonDynamicData;
		auto pixelData = records->mapTexture->pixelData;
		auto pixelBuffer = &pixelData->pixels[pixelData->offsets[0]];
		auto pixelBufferSize = pixelData->offsets[1] - pixelData->offsets[0];

		// Scan whole map for unvisited cells. This will catch cells that used to exist but are not present in the current masters.
		for (int gridY = cellMinY; gridY <= cellMaxY; gridY++) {
			for (int gridX = cellMinX; gridX <= cellMaxX; gridX++) {
				// Unvisited cells only.
				auto visited = visitedMapCells.at((cellMaxY - gridY) * (cellMaxX - cellMinX + 1) + (gridX - cellMinX));
				if (visited) {
					continue;
				}

				// Reset cell to sea. This clears cells which no longer have land data.
				// Note that having landscape record does not mean there is always land data.
				auto pixels = reinterpret_cast<NI::PixelRGB*>(pixelBuffer);
				int offsetX = (gridX - cellMinX) * cellResolution;
				int offsetY = (cellMaxY - gridY) * cellResolution;

				for (size_t y = 0; y < cellResolution; y++) {
					size_t pixelOffset = (y + offsetY) * mapWidth + offsetX;

					for (size_t x = 0; x < cellResolution; x++, pixelOffset++) {
						if (pixelOffset * sizeof(NI::PixelRGB) < pixelBufferSize) {
							pixels[pixelOffset] = seaColor;
						}
					}
				}

				auto cell = records->getCellByGrid(gridX, gridY);
				if (cell) {
					auto landscape = cell->variantData.exterior.landscape;
					if (landscape) {
						// Redraw base land. This is not guaranteed to redraw the cell if data is missing.
						TES3_Land_loadAndDrawBaseMap(landscape, pixelBuffer);
					}

					// Recheck marked locations.
					if (cell->cellFlags & TES3::CellFlag::MarkerDrawn) {
						if (cell->name && landscape) {
							// Redraw marker cell if it still likely to be a real location.
							OnDrawLocationMarker(cell);
						}
						else {
							// Clear marker flag if the land or location is no longer there.
							cell->cellFlags &= ~TES3::CellFlag::MarkerDrawn;
						}
					}
				}
			}
		}

		// Signal map change to renderer.
		pixelData->revisionID++;
	}

	void OnLoadedUpdateMap(bool isNewGame) {
		auto records = TES3::DataHandler::get()->nonDynamicData;

		if (isNewGame) {
			// Reset visited cell data on new game.
			std::fill(visitedMapCells.begin(), visitedMapCells.end(), 0);
		}

		if (flagRedrawBaseMap) {
			// Redraw entire base map after a saved map has been discarded, so that no cells carry over from the previous game.
			RedrawBaseMapRect(cellMinX, cellMaxX, cellMinY, cellMaxY, false);
		}
		else if (!records->allSavegameMastersMatchLoadOrder) {
			// Redraw unvisited cells when any master is changed.
			RedrawUnvisitedCells();
		}
	}

	//
	// Saving to the file. This will write our custom resolution information to the save.
	//

	int __fastcall OnSaveMAPHChunk(TES3::GameFile* saveFile, DWORD _UNUSED_, DWORD tag, MAPH* data, unsigned int size) {
		// Save magic numbers to mark extended map.
		data->cellResolution = -1;
		data->mapResolution = -1;

		saveFile->writeChunkData(tag, data, size);

		// Save extra chunk with more data.
		extendedHeader.version = 1;
		extendedHeader.cellResolution = cellResolution;
		extendedHeader.cellMinX = cellMinX;
		extendedHeader.cellMaxX = cellMaxX;
		extendedHeader.cellMinY = cellMinY;
		extendedHeader.cellMaxY = cellMaxY;

		saveFile->writeChunkData(MAPE_ChunkTag, &extendedHeader, sizeof(extendedHeader));
		return 0;
	}

	int __fastcall OnSaveMAPDChunk(TES3::GameFile* saveFile, DWORD _UNUSED_, DWORD tag, char* data, unsigned int size) {
		// Only save the part of the texture that contains cells.
		int exactWidth = (cellMaxX - cellMinX + 1) * cellResolution;
		int exactHeight = (cellMaxY - cellMinY + 1) * cellResolution;

		size_t stride = sizeof(NI::PixelRGB) * mapWidth;
		size_t dataSize = sizeof(NI::PixelRGB) * exactWidth * exactHeight;

		// Write chunk header, followed by the map data line by line.
		// This incremental style write requires a fixup of the form size afterwards.
		struct { DWORD tag, size; } chunkHeader{ tag, dataSize };
		const auto TES3_GameFile_writeRaw = reinterpret_cast<int(__thiscall*)(TES3::GameFile*, const void*, unsigned int)>(0x4B6CD0);

		TES3_GameFile_writeRaw(saveFile, &chunkHeader, sizeof(chunkHeader));
		for (int y = 0; y < exactHeight; y++, data += stride) {
			TES3_GameFile_writeRaw(saveFile, data, sizeof(NI::PixelRGB) * exactWidth);
		}
		saveFile->bytesWritten += sizeof(chunkHeader) + dataSize;

		// Write visited map cell data.
		saveFile->writeChunkData(VSIT_ChunkTag, visitedMapCells.data(), visitedMapCells.size() * sizeof(VisitedFlag));

		return 0;
	}

	//
	// Attempt to draw a cell when it is explored.
	//

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
		const auto sourceBuffer = reinterpret_cast<NI::PixelRGBA*>(&textureSource->pixelData->pixels[textureSource->pixelData->offsets[0]]);
		const auto sourceWidth = worldController->mapRenderTarget.targetWidth;
		const auto sourceDivision = float(worldController->mapRenderTarget.targetHeight) / float(cellResolution + 1);

		auto pixelData = TES3::DataHandler::get()->nonDynamicData->mapTexture->pixelData;
		auto pixelBuffer = reinterpret_cast<NI::PixelRGB*>(&pixelData->pixels[pixelData->offsets[0]]);
		auto pixelBufferSize = pixelData->offsets[1] - pixelData->offsets[0];

		int gridX = cell->getGridX(), gridY = cell->getGridY();
		if (!isPositionInMap(gridX, gridY)) {
			return;
		}

		// Copy pixels from the larger source render target to the map cell.
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

		// Draw marker, or remove marker flag if the cell no longer has a name.
		if (cell->name) {
			OnDrawLocationMarker(cell);
		}
		else {
			cell->cellFlags &= ~TES3::CellFlag::MarkerDrawn;
		}

		// Remember cell was visited.
		visitedMapCells.at((cellMaxY - gridY) * (cellMaxX - cellMinX + 1) + (gridX - cellMinX)) = 1;
	}

	//
	// Draw base map.
	//

	struct WNAM {
		signed char height[9][9];
	};
	static_assert(sizeof(WNAM) == 0x51, "TES3::Land::WNAM failed size validation");

	void __fastcall OnDrawBaseCell(TES3::Land* land, DWORD _UNUSED_, WNAM* wnam, NI::PixelRGB* pixelBuffer, unsigned int pixelBufferSize) {
		if (wnam == nullptr || pixelBuffer == nullptr) {
			return;
		}

		if (!isPositionInMap(land->gridX, land->gridY)) {
			return;
		}

		// Draw base heightmap.
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
				float heightData = 16 * wnam->height[8 - mappedY][mappedX];
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
	// Draw base map on game startup.
	//

	struct BaseMapCacheEntry {
		TES3::Land* land;
		WNAM heightfield;

		BaseMapCacheEntry(TES3::Land* _land, WNAM& _heightfield) : land(_land), heightfield(_heightfield) {}
	};
	std::vector<BaseMapCacheEntry> baseMapCache;
	const size_t BaseMapCacheReservation = 16000;

	void __fastcall OnStartupDrawBaseCell(TES3::Land* land, DWORD _UNUSED_, WNAM* wnam, NI::PixelRGB* pixelBuffer, unsigned int pixelBufferSize) {
		// Cache heightmap data until all cells have loaded, so that the map dimensions can be determined before drawing.
		if (baseMapCache.empty()) {
			baseMapCache.reserve(BaseMapCacheReservation);

			if (autoMapBounds) {
				cellMinX = cellMaxX = cellMinY = cellMaxY = 0;
			}
		}

		baseMapCache.emplace_back(land, *wnam);

		// Adjust auto map bounds.
		if (autoMapBounds) {
			cellMinX = std::min(cellMinX, land->gridX);
			cellMaxX = std::max(cellMaxX, land->gridX);
			cellMinY = std::min(cellMinY, land->gridY);
			cellMaxY = std::max(cellMaxY, land->gridY);
		}
	}

	void OnInitializedUpdateMap() {
		// MWSE initialized event handler.

		if (autoMapBounds) {
			// Clamp map bounds to something reasonable, to avoid allocating an oversized texture.
			cellMinX = std::max(cellMinX, -300);
			cellMaxX = std::min(cellMaxX, 300);
			cellMinY = std::max(cellMinY, -300);
			cellMaxY = std::min(cellMaxY, 300);

			// Re-allocate map.
			OnAllocateMapDefault(TES3::DataHandler::get()->nonDynamicData);
		}

		// Draw map.
		auto pixelData = TES3::DataHandler::get()->nonDynamicData->mapTexture->pixelData;
		auto pixelBuffer = reinterpret_cast<NI::PixelRGB*>(&pixelData->pixels[pixelData->offsets[0]]);
		auto pixelBufferSize = pixelData->offsets[1] - pixelData->offsets[0];

		for (auto& entry : baseMapCache) {
			OnDrawBaseCell(entry.land, 0, &entry.heightfield, pixelBuffer, pixelBufferSize);
		}

		// Clean up 
		baseMapCache.clear();
		baseMapCache.shrink_to_fit();
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

	struct TES3MapControllerStub {
		int unknown1[7];
		float northMarkerRotationDegrees;
		int unknown2[9];
	};
	float getMapControllerNorthMarkerOffset() {
		TES3MapControllerStub* mapController = reinterpret_cast<TES3MapControllerStub*>(TES3::WorldController::get()->mapController);
		return mapController->northMarkerRotationDegrees * 0.017453279f;
	}

	bool __cdecl OnUpdatePlayerPosition(TES3::UI::Element* mapMenu) {
		// mapMenu may be either the main map and mini-map.

		// If we weren't given a map menu, find it.
		if (mapMenu == nullptr) {
			mapMenu = TES3::UI::findMenu(*ui_id_MenuMap);
			if (mapMenu == nullptr) {
				return false;
			}
		}

		// Get player marker rotation, accounting for NorthMarker in interiors.
		const auto player = TES3::WorldController::get()->getMobilePlayer();
		float playerZRot = player->reference->orientation.z * -1;
		playerZRot += getMapControllerNorthMarkerOffset();

		if (mapMenu == TES3::UI::findMenu(*ui_id_MenuMulti)) {
			// Mini-map.
			auto localMarker = mapMenu->findChild(*ui_id_MenuMap_local_marker);

			// Update map marker rotation.
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
				const auto TES3UI_MenuMap_calcLocalMapPos = reinterpret_cast<void(__cdecl*)(TES3::Vector3*, int)>(0x5ED190);
				auto localMapPos = playerPosition;
				TES3UI_MenuMap_calcLocalMapPos(&localMapPos, 512);

				localMarker->positionX = localMapPos.x;
				localMarker->positionY = localMapPos.y;
				localMarker->flagPosChanged = true;
				mapMenu->timingUpdate();
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

	float memoZoomCentreX = 0, memoZoomCentreY = 0;

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
		int panelCentreX = panel->width / 2, panelCentreY = panel->height / 2;
		float zoomCentreX = (-panel->childOffsetX + panelCentreX) / previousZoom;
		float zoomCentreY = (panel->childOffsetY + panelCentreY) / previousZoom;

		// Record initial zoom point to avoid errors from rounding the childOffset every zoom step as the zoom level changes.
		const float tolerance = 1.0f;
		if (fabs(zoomCentreX - memoZoomCentreX) < tolerance && fabs(zoomCentreY - memoZoomCentreY) < tolerance) {
			// Use the original centre point, avoiding cumulative rounding errors.
			zoomCentreX = memoZoomCentreX;
			zoomCentreY = memoZoomCentreY;
		}
		else {
			// Remember this point as the original zoom centre.
			memoZoomCentreX = zoomCentreX;
			memoZoomCentreY = zoomCentreY;
		}

		panel->childOffsetX = -std::lround(zoomCentreX * zoomLevel - panelCentreX);
		panel->childOffsetY = std::lround(zoomCentreY * zoomLevel - panelCentreY);
		panel->timingUpdate();

		// Update player world marker position.
		auto worldMarker = menuMap->findChild(*ui_id_MenuMap_world_marker);

		if (worldMarker) {
			auto x = ((lastExteriorPlayerPosition.x / 8192) - cellMinX) * cellResolution * zoomLevel;
			auto y = (cellMaxY + 1 - (lastExteriorPlayerPosition.y / 8192)) * cellResolution * zoomLevel;
			worldMarker->positionX = std::lround(x);
			worldMarker->positionY = -std::lround(y);
			worldMarker->flagPosChanged = true;

			menuMap->timingUpdate();
		}

		lua_pushboolean(L, true);
		return 1;
	}

	int centerOnPlayer(lua_State* L) {
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

	int redrawCellRect(lua_State* L) {
		lua_settop(L, 1);
		luaL_checktype(L, 1, LUA_TTABLE);

		lua_getfield(L, 1, "minX");
		int minX = luaL_checknumber(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, 1, "maxX");
		int maxX = luaL_checknumber(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, 1, "minY");
		int minY = luaL_checknumber(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, 1, "maxY");
		int maxY = luaL_checknumber(L, -1);
		lua_pop(L, 1);

		RedrawBaseMapRect(minX, maxX, minY, maxY, true);
		return 0;
	}

	int onInitialized(lua_State* L) {
		OnInitializedUpdateMap();
		return 0;
	}

	int onLoaded(lua_State* L) {
		lua_settop(L, 1);
		luaL_checktype(L, 1, LUA_TTABLE);

		lua_getfield(L, 1, "newGame");
		bool isNewGame = lua_toboolean(L, -1);
		lua_pop(L, 1);

		OnLoadedUpdateMap(isNewGame);
		return 0;
	}

	// Initialize our patches based on a lua function, so it can be semi-easily disabled.
	int patchWorldMap(lua_State* L) {
		luaState = L;

		// Load config from lua.
		lua_settop(L, 1);
		luaL_checktype(L, 1, LUA_TTABLE);

		lua_getfield(L, 1, "autoMapBounds");
		autoMapBounds = lua_toboolean(L, -1);
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

		// If auto-calculating bounds, set a small initial size, so that the initial texture allocation isn't a big block of memory.
		if (autoMapBounds) {
			cellMinX = cellMaxX = cellMinY = cellMaxY = 0;
		}

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

		// Draw visited cells.
		mwse::genCallEnforced(0x4E32FE, 0x4C81C0, reinterpret_cast<DWORD>(OnDrawCell));

		// Draw cell location markers.
		const BYTE patchDrawLocationMarker[] = {
			0x57,			// push edi
			0x8B, 0xCB		// mov ecx, ebx
		};
		mwse::writeBytesUnprotected(0x4C855D, patchDrawLocationMarker, sizeof(patchDrawLocationMarker));
		mwse::genCallUnprotected(0x4C8560, reinterpret_cast<DWORD>(OnDrawLocationMarker));
		mwse::genJumpUnprotected(0x4C8565, 0x4C864A);

		// Draw base cells on startup. This caches cell data to be drawn later.
		mwse::genCallEnforced(0x4CACE7, 0x4CE800, reinterpret_cast<DWORD>(OnStartupDrawBaseCell));

		// Draw base cells on new game/load game.
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

		// Remove boundary limits when dragging the map.
		const BYTE patchRemoveDragLimitX[] = {
			0x8B, 0xC3,		// mov eax, ebx
			0xEB, 0x0C,		// jmp over limit code
		};
		const BYTE patchRemoveDragLimitY[] = {
			0x8B, 0xC5,		// mov eax, ebp
			0xEB, 0x0C,		// jmp over limit code
		};
		mwse::writeBytesUnprotected(0x5EE96F, patchRemoveDragLimitX, sizeof(patchRemoveDragLimitX));
		mwse::writeBytesUnprotected(0x5EEAFF, patchRemoveDragLimitY, sizeof(patchRemoveDragLimitY));

		lua_pushboolean(L, true);
		return 1;
	}

	int getMapData(lua_State* L) {
		lua_createtable(L, 0, 4);

		lua_pushboolean(L, autoMapBounds);
		lua_setfield(L, -2, "autoMapBounds");
		lua_pushnumber(L, cellResolution);
		lua_setfield(L, -2, "cellResolution");
		lua_pushnumber(L, mapWidth);
		lua_setfield(L, -2, "mapWidth");
		lua_pushnumber(L, mapHeight);
		lua_setfield(L, -2, "mapHeight");
		lua_pushnumber(L, cellMinX);
		lua_setfield(L, -2, "minX");
		lua_pushnumber(L, cellMaxX);
		lua_setfield(L, -2, "maxX");
		lua_pushnumber(L, cellMinY);
		lua_setfield(L, -2, "minY");
		lua_pushnumber(L, cellMaxY);
		lua_setfield(L, -2, "maxY");

		return 1;
	}
}
