#pragma once

extern "C" {
#include <lua.h>
#include <lauxlib.h>
}

namespace UIEXT {
	int patchWorldMap(lua_State* L);
	int onInitialized(lua_State* L);
	int onLoaded(lua_State* L);
	int setMapZoom(lua_State* L);
	int centreOnPlayer(lua_State* L);
	int getMapData(lua_State* L);
}
