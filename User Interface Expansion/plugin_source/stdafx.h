// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

#include "targetver.h"

#define WIN32_LEAN_AND_MEAN             // Exclude rarely-used stuff from Windows headers
#define NOMINMAX
// Windows Header Files
#include <windows.h>

#undef near
#undef far
#undef PlaySound

// reference additional headers your program requires here

#include <algorithm>
#include <map>
#include <mutex>
#include <unordered_map>
#include <vector>

#include <cmath>
#include <cstdint>

#include <nonstd/span.hpp>

#include <sol/sol.hpp>