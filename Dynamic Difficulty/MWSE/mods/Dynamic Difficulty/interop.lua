local this = {}

-- This function is replaced at runtime once Dynamic Difficulty has registered.
function this.recalculate()
    mwse.log("[Dynamic Difficulty] Warning: interop recalculate function called in invalid state.")
end

return this