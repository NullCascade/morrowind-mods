// dllmain.cpp : Defines the entry point for the DLL application.
#include "pch.h"

#include "SAPIInterface.h"

std::shared_ptr<SAPIInterface> sapi = nullptr;

bool speak(const std::wstring& text, sol::optional<DWORD> flags) {
    return sapi->speak(text, flags.value_or(SPF_ASYNC));
}

bool stop() {
    return sapi->stop();
}

bool isSpeaking() {
    return sapi->isSpeaking();
}

bool addPronunciation(const std::wstring& word, const std::wstring& pronunciation, sol::optional<SPPARTOFSPEECH> partOfSpeech, sol::optional<LANGID> language) {
    return sapi->addPronunciation(word, pronunciation, partOfSpeech.value_or(SPPS_Unknown), language.value_or(0x409));
}

extern "C" int  __declspec(dllexport) luaopen_SAPIwind_SAPI(lua_State* L) {
    if (sapi == nullptr) {
        sapi = std::make_shared<SAPIInterface>();
    }

    sol::state_view state = L;

    sol::table sapi = state.create_table();
    sapi["speak"] = speak;
    sapi["stop"] = stop;
    sapi["isSpeaking"] = isSpeaking;
    sapi["addPronunciation"] = addPronunciation;

    // Create an instance and return it as the module.
	return sapi.push();
}

