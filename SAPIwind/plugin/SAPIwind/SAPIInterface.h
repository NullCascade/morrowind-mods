#pragma once

#include "pch.h"

class SAPIInterface {
public:
    SAPIInterface();
    ~SAPIInterface();

    bool speak(const std::wstring& text, DWORD flags = SPF_ASYNC);
    bool stop();
    bool isSpeaking();
    bool addPronunciation(const std::wstring& word, const std::wstring& pronunciation, SPPARTOFSPEECH partOfSpeech = SPPS_Unknown, LANGID language = 0x409);

    ISpVoice* pVoice = nullptr;
    ISpLexicon* pLexicon = nullptr;
};
