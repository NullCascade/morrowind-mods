#include "stdafx.h"

#include "PatchAttachmentCrash.h"

namespace RunPatch {
	// Display information about attachments.
	void printAttachmentDataForVariables(TES3::Object * object, TES3::ItemDataAttachment * attachment) {
		__try {
			auto itemData = attachment->data;
			mwse::log::getLog() << "      - Count: " << itemData->count << std::endl;

			if (itemData->owner) {
				mwse::log::getLog() << "      - Owner: ";
				mwse::log::getLog() << itemData->owner->getObjectID() << std::endl;
			}

			if (itemData->script) {
				mwse::log::getLog() << "      - Script: ";
				mwse::log::getLog() << itemData->script->getObjectID() << std::endl;
			}
		}
		__except (EXCEPTION_EXECUTE_HANDLER) {
			mwse::log::getLog() << "Data corruption found on attachment! " << std::dec << attachment->type << std::endl;
		}
	}

	// Help tooltip wrapper.
	typedef void(__stdcall *DisplayToolTipSignature)(TES3::Object *, TES3::ItemData *, int);
	DisplayToolTipSignature ToolTipFunction = nullptr;
	void __stdcall displayToolTip(TES3::Object * object, TES3::ItemData * itemData, int count) {
		__try {
			ToolTipFunction(object, itemData, count);
		}
		__except (EXCEPTION_EXECUTE_HANDLER) {
			mwse::tes3::ui::messagePlayer("[Runtime Patch] Intercepted crash when displaying tooltip. See logs for details.");
			mwse::log::getLog() << "[Runtime Patch] Intercepted crash when displaying tooltip." << std::endl;
			mwse::log::getLog() << "  Object: " << object->getObjectID() << " [" << object->objectType << "]" << std::endl;
			mwse::log::getLog() << "  Item Data: " << (itemData ? "true" : "false") << std::endl;
			mwse::log::getLog() << "  Count: " << std::dec <<  count << std::endl;
			if (object->objectType == TES3::ObjectType::Reference) {
				auto attachment = reinterpret_cast<TES3::Reference*>(object)->attachments;
				if (attachment) {
					mwse::log::getLog() << "  Attachments: " << std::endl;
					while (attachment) {
						switch (attachment->type) {
						case TES3::AttachmentType::Variables:
							printAttachmentDataForVariables(object, static_cast<TES3::ItemDataAttachment *>(attachment));
							break;
						default:
							mwse::log::getLog() << "    - Attachment of type " << std::dec << attachment->type << std::endl;
						}
						attachment = attachment->next;
					}
				}
			}
		}
	}

	TES3::ItemData* __fastcall PatchCatchInvalidItemDataAttachment(TES3::Reference* reference) {
		__try {
			return mwse::tes3::getAttachedItemDataNode(reference);
		}
		__except (EXCEPTION_EXECUTE_HANDLER) {
			mwse::tes3::ui::messagePlayer("[Runtime Patch] Intercepted crash when fetching item data attachment. See logs for details.");
			mwse::log::getLog() << "[Runtime Patch] Intercepted crash when attempting to get item data for reference '" << reference->getObjectID() << "'. Removing invalid attachment." << std::endl;

			// Attempt to remove the attachment.
			TES3::Attachment * attachment = reference->attachments;
			while (attachment) {
				if (attachment->type != TES3::AttachmentType::Variables) {
					attachment = attachment->next;
					continue;
				}

				reference->removeAttachment(attachment);
				break;
			}

			return nullptr;
		}
	}

	// Lua-called function to try to replace the window message handler.
	int hookAttachmentCrashFix(lua_State* L) {
		// Try to get the current function type
		ToolTipFunction = (DisplayToolTipSignature)mwse::getCallAddress(0x41CC2E);
		if (ToolTipFunction == nullptr) {
			lua_pushboolean(L, false);
			return 1;
		}

		// Patch all the tooltip calls.
		DWORD address = (DWORD)ToolTipFunction;
		mwse::genCallEnforced(0x41CC2E, address, reinterpret_cast<DWORD>(displayToolTip));
		mwse::genCallEnforced(0x58FF1D, address, reinterpret_cast<DWORD>(displayToolTip));
		mwse::genCallEnforced(0x59E10D, address, reinterpret_cast<DWORD>(displayToolTip));
		mwse::genCallEnforced(0x5A7633, address, reinterpret_cast<DWORD>(displayToolTip));
		mwse::genCallEnforced(0x5B6FD1, address, reinterpret_cast<DWORD>(displayToolTip));
		mwse::genCallEnforced(0x5C663C, address, reinterpret_cast<DWORD>(displayToolTip));
		mwse::genCallEnforced(0x5CE054, address, reinterpret_cast<DWORD>(displayToolTip));
		mwse::genCallEnforced(0x5CE071, address, reinterpret_cast<DWORD>(displayToolTip));
		mwse::genCallEnforced(0x5D24B2, address, reinterpret_cast<DWORD>(displayToolTip));
		mwse::genCallEnforced(0x5D4B5C, address, reinterpret_cast<DWORD>(displayToolTip));
		mwse::genCallEnforced(0x5E4FAD, address, reinterpret_cast<DWORD>(displayToolTip));
		mwse::genCallEnforced(0x5E802D, address, reinterpret_cast<DWORD>(displayToolTip));
		mwse::genCallEnforced(0x5F6F78, address, reinterpret_cast<DWORD>(displayToolTip));
		mwse::genCallEnforced(0x607C33, address, reinterpret_cast<DWORD>(displayToolTip));
		mwse::genCallEnforced(0x607C86, address, reinterpret_cast<DWORD>(displayToolTip));
		mwse::genCallEnforced(0x607CA7, address, reinterpret_cast<DWORD>(displayToolTip));
		mwse::genCallEnforced(0x60EE6B, address, reinterpret_cast<DWORD>(displayToolTip));
		mwse::genCallEnforced(0x61550D, address, reinterpret_cast<DWORD>(displayToolTip));

		// Patch: Invalid item condition attachment.
		mwse::genCallUnprotected(0x4E5460, reinterpret_cast<DWORD>(PatchCatchInvalidItemDataAttachment), 0x1D);

		lua_pushboolean(L, true);
		return 1;
	}
}
