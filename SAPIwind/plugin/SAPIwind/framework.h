#pragma once

#define _CRT_SECURE_NO_WARNINGS

#define WIN32_LEAN_AND_MEAN             // Exclude rarely-used stuff from Windows headers
// Windows Header Files
#include <windows.h>


#define _ATL_APARTMENT_THREADED
#include <sapi.h>
#include <atlbase.h>
#include <sperror.h>

#include <sol/sol.hpp>
