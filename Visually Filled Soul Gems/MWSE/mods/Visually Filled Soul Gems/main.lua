
local config = require("Visually Filled Soul Gems.config")
local interop = require("Visually Filled Soul Gems.interop")
local log = require("Visually Filled Soul Gems.log")

--- Callback for when a new scene node is created for a reference.
--- We'll use it add a visual effect to soul gems that are filled.
--- @param e referenceSceneNodeCreatedEventData
local function onReferenceSceneNodeCreated(e)
	if (not e.reference.object.isSoulGem) then
		return
	end

	interop.setSoulEffectActive(e.reference)
end
event.register("referenceSceneNodeCreated", onReferenceSceneNodeCreated)

--- Grab the enchantment we're going to use for our plastic wrap.
local function onInitialized()
	log:info("Mod loaded with config: %s", json.encode(config, { indent = true }))
	interop.setEnchantmentEffect(config.enchantmentId)
end
event.register("initialized", onInitialized)

--- Create our MCM.
local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "Visually Filled Soul Gems" })
	template:saveOnClose("Visually Filled Soul Gems", config)

	local pageDefault = template:createSideBarPage({ label = "Features" })
	pageDefault.sidebar:createInfo({ text = "Visually Filled Soul Gems v1.1\n  by NullCascade" })

	local catDefaultEffect = pageDefault:createCategory({ label = "Default Enchant Effect" })
	do
		catDefaultEffect:createOnOffButton({
			label = "Enable default magic wrap effect?",
			description = "If true, the default magic wrap effect will be applied to soul gems. This may be disabled if using a soul gem replacer that supports custom VFSG data.",
			variable = mwse.mcm.createTableVariable({ id = "useEnchantEffect", table = config }),
			callback = interop.refreshActiveSoulGems,
		})

		catDefaultEffect:createTextField({
			label = "Enchantment effect to use:",
			description = "The enchantment effect to apply to filled soul gems.",
			variable = mwse.mcm.createTableVariable({ id = "enchantmentId", table = config }),
			callback = function(self)
				interop.setEnchantmentEffect(self.variable.value)
			end,
		})
	end

	local catDebug = pageDefault:createCategory({ label = "Debugging" })
	do
		catDebug:createDropdown({
			label = "Logging Level",
			description = "Set the log level.",
			options = {
				{ label = "TRACE", value = "TRACE" },
				{ label = "DEBUG", value = "DEBUG" },
				{ label = "INFO", value = "INFO" },
				{ label = "WARN", value = "WARN" },
				{ label = "ERROR", value = "ERROR" },
				{ label = "NONE", value = "NONE" },
			},
			variable = mwse.mcm.createTableVariable{ id = "logLevel", table = config },
			callback = function(self)
				log:setLogLevel(self.variable.value)
			end
		})
	end

	-- Finish up.
	template:register()
end
event.register("modConfigReady", registerModConfig)
