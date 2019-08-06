
local common = {}

function common.addTestSpell(params)
	local spell = tes3.getObject(params.id) or tes3spell.create(params.id, params.name)
	spell.magickaCost = 0

	local effect = spell.effects[1]
	effect.id = params.effect
	effect.rangeType = params.range or tes3.effectRange.self
	effect.min = params.min or 0
	effect.max = params.max or 0
	effect.duration = params.duration or 0

	mwscript.addSpell({reference = tes3.player, spell = spell})
end

return common
