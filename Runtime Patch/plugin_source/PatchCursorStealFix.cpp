#include "stdafx.h"

#include "PatchCursorStealFix.h"

namespace RunPatch {
	// Mapping to global TES3 variables.
	bool& TES3_WindowInFocus = *reinterpret_cast<bool*>(0x776D08);
	int& TES3_CursorShown = *reinterpret_cast<int*>(0x776D0C);

	// Functions from TES3 that we want to call but that don't exist in MWSE.
	const auto TES3_WorldController_updateTiming = reinterpret_cast<void(__thiscall*)(TES3::WorldController *)>(0x453610);

	// Store the previously used handle, so that we can fall back to its logic in the cases we don't care about.
	WNDPROC previousHandler = nullptr;

	// Our custom handler for window messages.
	LRESULT __stdcall handle(HWND hWnd, int uMsg, WPARAM wParam, LPARAM lParam) {
		switch (uMsg) {
		case WM_ACTIVATE:
		{
			if (wParam) {
				auto worldController = mwse::tes3::getWorldController();
				if (worldController) {
					TES3_WorldController_updateTiming(worldController);
				}
				TES3_WindowInFocus = true;
				if (TES3_CursorShown) {
					ShowCursor(false);
					TES3_CursorShown = false;
				}
			}
			else {
				TES3_WindowInFocus = false;
				if (!TES3_CursorShown) {
					ShowCursor(true);
					TES3_CursorShown = true;
				}
			}
			return 0;
		}
		break;
		case WM_NCHITTEST:
		{
			auto result = DefWindowProc(hWnd, uMsg, wParam, lParam);
			if (TES3_WindowInFocus && TES3_CursorShown && result == HTCLIENT) {
				ShowCursor(false);
				TES3_CursorShown = false;
			}
			else if (TES3_WindowInFocus && !TES3_CursorShown && result != HTCLIENT) {
				ShowCursor(true);
				TES3_CursorShown = true;
			}
			return result;
		}
		break;
		}

		return previousHandler(hWnd, uMsg, wParam, lParam);
	}

	// Lua-called function to try to replace the window message handler.
	int hookCursorStealFix(lua_State* L) {
		// Replace the window's handler function.
		previousHandler = (WNDPROC)SetClassLongPtr(mwse::tes3::getWorldController()->Win32_hWndParent, GCLP_WNDPROC, (LONG_PTR)handle);
		if (previousHandler == nullptr) {
			mwse::log::getLog() << "[Runtime Patch] ERROR: Failed to replace window handler." << std::endl;
			lua_pushboolean(L, false);
			return 1;
		}

		lua_pushboolean(L, true);
		return 1;
	}
}
