local function disableEnchantCallAt(address)
	local previousCallAddress = mwse.memory.readCallAddress({ address = address + 0x8 })
	if (previousCallAddress == 0x410B00 ) then
		mwse.memory.writeNoOperation({ address = address, length = 0xD })
	else
		mwse.log("[MWSE-NoGlow] Could not patch section at 0x%6X, found unexpected call to 0x%6X.", address, previousCallAddress)
	end
end

-- Disable enchant effect calls.
disableEnchantCallAt(0x473707)
disableEnchantCallAt(0x474414)
disableEnchantCallAt(0x49EC32)
disableEnchantCallAt(0x4EFC51)
