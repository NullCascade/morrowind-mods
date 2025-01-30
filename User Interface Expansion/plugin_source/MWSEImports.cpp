#include "stdafx.h"

#include <TES3Cell.h>
#include <TES3DataHandler.h>
#include <TES3GameFile.h>
#include <TES3Vectors.h>
#include <TES3UIElement.h>
#include <TES3WorldController.h>
#include <TES3MobileActor.h>

#include <NIAVObject.h>
#include <MemAccess.h>


namespace TES3 {
	const auto TES3_TES3File_readChunkData = reinterpret_cast<bool(__thiscall*)(GameFile*, void*, unsigned int)>(0x4B6880);
	bool GameFile::readChunkData(void* data, unsigned int size) {
		return TES3_TES3File_readChunkData(this, data, size);
	}

	const auto TES3_TES3File_writeChunkData = reinterpret_cast<int(__thiscall*)(GameFile*, unsigned int, const void*, unsigned int)>(0x4B6BA0);
	int GameFile::writeChunkData(unsigned int tag, const void* data, unsigned int size) {
		return TES3_TES3File_writeChunkData(this, tag, data, size);
	}

	const auto TES3_NonDynamicData_getCellByGrid = reinterpret_cast<Cell * (__thiscall*)(NonDynamicData*, int, int)>(0x4BAA10);
	Cell* NonDynamicData::getCellByGrid(int x, int y) {
		return TES3_NonDynamicData_getCellByGrid(this, x, y);
	}


	bool Cell::getCellFlag(unsigned int flag) const {
		return (cellFlags & flag);
	}

	bool Cell::getIsInterior() const {
		return getCellFlag(TES3::CellFlag::Interior);
	}

	const auto TES3_Cell_getExteriorGridX = reinterpret_cast<int(__thiscall*)(const Cell*)>(0x4DB9D0);
	int Cell::getGridX() const {
		return TES3_Cell_getExteriorGridX(this);
	}

	const auto TES3_Cell_getExteriorGridY = reinterpret_cast<int(__thiscall*)(const Cell*)>(0x4DB9F0);
	int Cell::getGridY() const {
		return TES3_Cell_getExteriorGridY(this);
	}

	WorldController* WorldController::get() {
		return *reinterpret_cast<TES3::WorldController**>(0x7C67DC);
	}

	const auto TES3_WorldController_getMobilePlayer = reinterpret_cast<MobilePlayer * (__thiscall*)(WorldController*)>(0x40FF20);
	MobilePlayer* WorldController::getMobilePlayer() {
		return TES3_WorldController_getMobilePlayer(this);
	}

	const auto TES3_MobileActor_getCell = reinterpret_cast<Cell * (__thiscall*)(const MobileActor*)>(0x521630);
	Cell* MobileActor::getCell() const {
		return TES3_MobileActor_getCell(this);
	}

	Vector3::Vector3() : x(0.0f), y(0.0f), z(0.0f) {
	}

	Vector3::Vector3(float _x, float _y, float _z) : x(_x), y(_y), z(_z) {
	}

	bool Vector3::operator==(const Vector3& vec3) const {
		return x == vec3.x && y == vec3.y && z == vec3.z;
	}

	bool Vector3::operator!=(const Vector3& vec3) const {
		return x != vec3.x || y != vec3.y || z != vec3.z;
	}

	Matrix33::Matrix33() : m0(), m1(), m2() {
	}

	const auto TES3_Matrix33_toRotationY = reinterpret_cast<void(__thiscall*)(Matrix33*, float)>(0x6E7D60);
	void Matrix33::toRotationY(float value) {
		TES3_Matrix33_toRotationY(this, value);
	}
}

namespace TES3::UI {
	const auto TES3_ui_findMenu = reinterpret_cast<UI::Element * (__cdecl*)(UI_ID)>(0x595370);
	Element* findMenu(UI_ID id) {
		return TES3_ui_findMenu(id);
	}

	const auto TES3_ui_findChildElement = reinterpret_cast<Element * (__thiscall*)(const Element*, UI_ID)>(0x582DE0);
	Element* Element::findChild(UI_ID id) const {
		return TES3_ui_findChildElement(this, id);
	}

	const auto TES3_ui_performLayout = reinterpret_cast<Element * (__thiscall*)(Element*, bool)>(0x583B70);
	Element* Element::performLayout(bool bUpdateTimestamp) {
		return TES3_ui_performLayout(this, bUpdateTimestamp);
	}

	const auto TES3_ui_updateSceneGraph = reinterpret_cast<void(__thiscall*)(Element*)>(0x587000);
	void Element::updateSceneGraph() {
		TES3_ui_updateSceneGraph(this);
	}

	const auto TES3_ui_timingUpdate = reinterpret_cast<long(__thiscall*)(Element*)>(0x583B60);
	long Element::timingUpdate() {
		return TES3_ui_timingUpdate(this);
	}
}

namespace NI {
	void AVObject::setLocalRotationMatrix(const TES3::Matrix33* matrix) {
		reinterpret_cast<void(__thiscall*)(AVObject*, const TES3::Matrix33*)>(0x50E020)(this, matrix);
	}

	void AVObject::update(float fTime, bool bUpdateControllers, bool bUpdateBounds) {
		reinterpret_cast<void(__thiscall*)(AVObject*, float, int, int)>(0x6EB000)(this, fTime, bUpdateControllers, bUpdateBounds);
	}
}

namespace mwse {
	void genNOP(DWORD Address) {
		MemAccess<unsigned char>::Set(Address, 0x90);
	}

	void genJumpUnprotected(DWORD address, DWORD to, DWORD size) {
		// Unprotect memory.
		DWORD oldProtect;
		VirtualProtect((DWORD*)address, size, PAGE_READWRITE, &oldProtect);

		// Create our jump.
		MemAccess<unsigned char>::Set(address, 0xE9);
		MemAccess<DWORD>::Set(address + 1, to - address - 0x5);

		// NOP out the rest of the block.
		for (DWORD i = address + 5; i < address + size; ++i) {
			genNOP(i);
		}

		// Protect memory again.
		VirtualProtect((DWORD*)address, size, oldProtect, &oldProtect);
	}

	void genCallUnprotected(DWORD address, DWORD to, DWORD size) {
		// Unprotect memory.
		DWORD oldProtect;
		VirtualProtect((DWORD*)address, size, PAGE_READWRITE, &oldProtect);

		// Create our call.
		MemAccess<unsigned char>::Set(address, 0xE8);
		MemAccess<DWORD>::Set(address + 1, to - address - 0x5);

		// NOP out the rest of the block.
		for (DWORD i = address + 5; i < address + size; ++i) {
			genNOP(i);
		}

		// Protect memory again.
		VirtualProtect((DWORD*)address, size, oldProtect, &oldProtect);
	}

	bool genCallEnforced(DWORD address, DWORD previousTo, DWORD to, DWORD size) {
		// Make sure we're doing a call.
		BYTE instruction = *reinterpret_cast<BYTE*>(address);
		if (instruction != 0xE8) {
#if _DEBUG
			log::getLog() << "[MemoryUtil] Skipping call generation at 0x" << std::hex << address << ". Expected 0xe8, found instruction: 0x" << (int)instruction << "." << std::endl;
#endif
			return false;
		}

		// Read previous call address to make sure it's what we are expecting.
		DWORD currentCallAddress = *reinterpret_cast<DWORD*>(address + 1) + address + 0x5;
		if (currentCallAddress != previousTo) {
#if _DEBUG
			log::getLog() << "[MemoryUtil] Skipping call generation at 0x" << std::hex << address << ". Expected previous call to 0x" << previousTo << ", found 0x" << currentCallAddress << "." << std::endl;
#endif
			return false;
		}

		// Unprotect memory.
		DWORD oldProtect;
		VirtualProtect((DWORD*)address, size, PAGE_READWRITE, &oldProtect);

		// Create our call.
		MemAccess<unsigned char>::Set(address, 0xE8);
		MemAccess<DWORD>::Set(address + 1, to - address - 0x5);

		// NOP out the rest of the block.
		for (DWORD i = address + 5; i < address + size; ++i) {
			genNOP(i);
		}

		// Protect memory again.
		VirtualProtect((DWORD*)address, size, oldProtect, &oldProtect);

		return true;
	}

	bool genNOPUnprotected(DWORD address, DWORD size) {
		// Unprotect memory.
		DWORD oldProtect;
		VirtualProtect((DWORD*)address, size, PAGE_READWRITE, &oldProtect);

		for (DWORD i = 0; i < size; ++i) {
			genNOP(address + i);
		}

		// Protect memory again.
		VirtualProtect((DWORD*)address, size, oldProtect, &oldProtect);
		return true;
	}

	void writeByteUnprotected(DWORD address, BYTE value) {
		// Unprotect memory.
		DWORD oldProtect;
		VirtualProtect((DWORD*)address, sizeof(BYTE), PAGE_READWRITE, &oldProtect);

		// Overwrite our single byte.
		MemAccess<BYTE>::Set(address, value);

		// Protect memory again.
		VirtualProtect((DWORD*)address, sizeof(BYTE), oldProtect, &oldProtect);
	}

	void writeBytesUnprotected(DWORD address, const BYTE* value, size_t count) {
		DWORD oldProtect;
		VirtualProtect((DWORD*)address, count, PAGE_READWRITE, &oldProtect);
		memmove_s((void*)address, count, value, count);
		VirtualProtect((DWORD*)address, count, oldProtect, &oldProtect);
	}

	void writeDoubleWordUnprotected(DWORD address, DWORD value) {
		// Unprotect memory.
		DWORD oldProtect;
		VirtualProtect((DWORD*)address, sizeof(DWORD), PAGE_READWRITE, &oldProtect);

		// Overwrite our single byte.
		MemAccess<DWORD>::Set(address, value);

		// Protect memory again.
		VirtualProtect((DWORD*)address, sizeof(DWORD), oldProtect, &oldProtect);
	}
}