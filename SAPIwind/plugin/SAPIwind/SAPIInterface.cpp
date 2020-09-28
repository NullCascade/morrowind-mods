#include "pch.h"

#include "SAPIInterface.h"

#include "sphelper.h"

inline HRESULT TTSSymToPhoneId(LANGID langid, WCHAR* pszSym, WCHAR* pszPhoneId) {
    CComPtr<ISpPhoneConverter> cpPhoneConv;
    auto hr = SpCreatePhoneConverter(langid, NULL, NULL, &cpPhoneConv);
    if (SUCCEEDED(hr))
    {
        return cpPhoneConv->PhoneToId(pszSym, pszPhoneId);
    }
    return hr;
}

SAPIInterface::SAPIInterface() {
    if (FAILED(::CoInitialize(nullptr))) {
        throw std::runtime_error("Could not CoInitialize.");
    }

    if (FAILED(CoCreateInstance(CLSID_SpLexicon, nullptr, CLSCTX_ALL, IID_ISpLexicon, (void**)&pLexicon))) {
        throw std::runtime_error("Could not create SpLexicon instance.");
    }

    if (FAILED(CoCreateInstance(CLSID_SpVoice, nullptr, CLSCTX_ALL, IID_ISpVoice, (void**)&pVoice))) {
        throw std::runtime_error("Could not create SpVoice instance.");
    }
}

SAPIInterface::~SAPIInterface() {
    if (pVoice) {
        pVoice->Release();
    }
    ::CoUninitialize();
}

bool SAPIInterface::speak(const std::wstring& text, DWORD flags) {
    return SUCCEEDED(pVoice->Speak(text.c_str(), flags, nullptr));
}

bool SAPIInterface::stop() {
    if (isSpeaking()) {
        return SUCCEEDED(pVoice->Speak(L" ", SVSFPurgeBeforeSpeak, nullptr));
    }
    return false;
}

bool SAPIInterface::isSpeaking() {
    SPVOICESTATUS status;
    if (FAILED(pVoice->GetStatus(&status, 0))) {
        return false;
    }

    return status.dwRunningState == SpeechRunState::SRSEIsSpeaking;
}

bool SAPIInterface::addPronunciation(const std::wstring& word, const std::wstring& pronunciation, SPPARTOFSPEECH partOfSpeech, LANGID language) {
    WCHAR szwPronStr[MAX_PATH] = L"";
    WCHAR szPronunciation[MAX_PATH] = L"";
    StrCpyW(szwPronStr, pronunciation.c_str());

#if false
    SPWORDPRONUNCIATIONLIST spwordpronlist;
    SPWORDPRONUNCIATION* wordpron = nullptr;
    spwordpronlist.ulSize = sizeof(SPWORDPRONUNCIATIONLIST);
    memset(&spwordpronlist, 0, sizeof(spwordpronlist));
    while (SUCCEEDED(pLexicon->GetPronunciations(word.c_str(), 0, 0, &spwordpronlist)) && spwordpronlist.pFirstWordPronunciation) {
        // Remove existing entry.
        if (FAILED(pLexicon->RemovePronunciation(word.c_str(), spwordpronlist.pFirstWordPronunciation->LangID, spwordpronlist.pFirstWordPronunciation->ePartOfSpeech, spwordpronlist.pFirstWordPronunciation->szPronunciation))) {
            CoTaskMemFree(spwordpronlist.pvBuffer);
            throw std::runtime_error("Failed to remove pronunciation!");
        }

        // Clean up after ourselves.
        CoTaskMemFree(spwordpronlist.pvBuffer);
        memset(&spwordpronlist, 0, sizeof(spwordpronlist));
    }
#endif

    pLexicon->RemovePronunciation(word.c_str(), language, partOfSpeech, szPronunciation);
    if (SUCCEEDED(TTSSymToPhoneId(language, szwPronStr, szPronunciation))) {
        return SUCCEEDED(pLexicon->AddPronunciation(word.c_str(), language, partOfSpeech, szPronunciation));
    }
    return false;
}
