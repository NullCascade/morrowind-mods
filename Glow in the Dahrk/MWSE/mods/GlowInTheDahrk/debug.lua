local debug = {}

debug.interop = require("GlowInTheDahrk.interop")
debug.config = require("GlowInTheDahrk.config")

local function debugWeatherChangedImmediate(e)
	mwse.log("Weather changed to %s.", table.find(tes3.weather, e.to.index))
end

local function debugWeatherTransitionStarted(e)
	mwse.log("Weather transition from %s to %s started.", table.find(tes3.weather, e.from.index),
	         table.find(tes3.weather, e.to.index))
end

local function debugWeatherTransitionFinished(e)
	mwse.log("Weather transition to %s finished.", table.find(tes3.weather, e.to.index))
end

function debug.startWeatherTracking()
	event.register("weatherChangedImmediate", debugWeatherChangedImmediate)
	event.register("weatherTransitionStarted", debugWeatherTransitionStarted)
	event.register("weatherTransitionFinished", debugWeatherTransitionFinished)
end

function debug.stopWeatherTracking()
	event.unregister("weatherChangedImmediate", debugWeatherChangedImmediate)
	event.unregister("weatherTransitionStarted", debugWeatherTransitionStarted)
	event.unregister("weatherTransitionFinished", debugWeatherTransitionFinished)
end

function debug.printColorTimings()
	local weatherController = tes3.worldController.weatherController
	local fields = {
		"skyPostSunriseTime",
		"skyPostSunsetTime",
		"skyPreSunriseTime",
		"skyPreSunsetTime",
		"sunriseDuration",
		"sunriseHour",
		"sunsetDuration",
		"sunsetHour",
	}
	mwse.log("[Glow in the Dahrk] tes3weatherController timings:")
	for _, field in ipairs(fields) do
		mwse.log("  %s = %.2f", field, weatherController[field])
	end

	-- Figure out when our important sunrise times are.
	local sunriseStartTime = weatherController.sunriseHour - weatherController.skyPreSunriseTime
	local sunriseTotalDuration = weatherController.skyPostSunriseTime + weatherController.sunriseDuration +
	                             weatherController.skyPreSunriseTime
	local sunriseMidPoint = sunriseStartTime + (sunriseTotalDuration / 2)
	local sunriseStopTime = sunriseStartTime + sunriseTotalDuration
	mwse.log("  sunriseStartTime = %.2f", sunriseStartTime)
	mwse.log("  sunriseTotalDuration = %.2f", sunriseTotalDuration)
	mwse.log("  sunriseMidPoint = %.2f", sunriseMidPoint)
	mwse.log("  sunriseStopTime = %.2f", sunriseStopTime)

	-- Figure out when our important sunset times are.
	local sunsetStartTime = weatherController.sunsetHour - weatherController.skyPreSunsetTime
	local sunsetTotalDuration = weatherController.skyPostSunsetTime + weatherController.sunsetDuration +
	                            weatherController.skyPreSunsetTime
	local sunsetMidPoint = sunsetStartTime + (sunsetTotalDuration / 2)
	local sunsetStopTime = sunsetStartTime + sunsetTotalDuration
	mwse.log("  sunsetStartTime = %.2f", sunsetStartTime)
	mwse.log("  sunsetTotalDuration = %.2f", sunsetTotalDuration)
	mwse.log("  sunsetMidPoint = %.2f", sunsetMidPoint)
	mwse.log("  sunsetStopTime = %.2f", sunsetStopTime)
end

return debug
