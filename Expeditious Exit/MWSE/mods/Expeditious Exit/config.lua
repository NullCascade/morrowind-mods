local config = mwse.loadConfig("Expeditious Exit")

if (config == nil or config.showMenuOnExit == nil) then
	config = {
		showMenuOnExit = true,
	}
end

return config