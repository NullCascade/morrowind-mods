#pragma once

extern "C" {
#include <lua.h>
#include <lauxlib.h>
}

namespace UIEXT {
	int patchWorldMap(lua_State* L);
}
