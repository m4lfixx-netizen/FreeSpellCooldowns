local _, FSC = ...
local function Public(value) return not (issecretvalue and issecretvalue(value)) end
local function Known(id)
    if not C_SpellBook or not C_SpellBook.IsSpellKnown then return end
    local ok, value = pcall(C_SpellBook.IsSpellKnown, id)
    if ok and Public(value) and type(value) == "boolean" then return value end
end

-- A class-specific public ability signal for the native five-stack maximum.
-- This never queries a restricted aura and does not estimate intermediate stacks.
-- If another instant-cast talent is learned, the signal is deliberately unused.
function FSC:ReadMaelstromSoundSignal(entry, threshold)
    if self:ResolveBuffAuraID(entry.spellID) ~= 408505 or threshold ~= 5 then return end
    local _, class = UnitClass("player")
    if class ~= "SHAMAN" or Known(16188) ~= false or Known(16166) ~= false then return end
    if not C_Spell or not C_Spell.GetSpellInfo or not C_Spell.GetSpellPowerCost then return end
    local ok, info = pcall(C_Spell.GetSpellInfo, 403)
    if not ok or not Public(info) or type(info) ~= "table" then return end
    local cast = info.castTime
    if not Public(cast) or type(cast) ~= "number" or cast < 0 or cast ~= cast or cast == math.huge then return end
    local success, costs = pcall(C_Spell.GetSpellPowerCost, 403)
    if not success or not Public(costs) or type(costs) ~= "table" then return end
    for _, cost in ipairs(costs) do
        if not Public(cost) or type(cost) ~= "table" then return end
        local power, amount = cost.type, cost.cost
        if not Public(power) or not Public(amount) then return end
        if power == 0 and type(amount) == "number" and amount >= 0 and amount == amount and amount < math.huge then
            return cast == 0 and amount == 0
        end
    end
end
