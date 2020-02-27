local _, BuffLog = ...

-- NAMESPACE
BuffLog = {}
BuffLog.ADDON_NAME = "BuffLog"
BuffLog.buffs = {}
BuffLog.lastTime = time()

-- COMMAND
SLASH_BUFFLOG1 = "/bufflog"
SlashCmdList["BUFFLOG"] = function(msg)
    BuffLog:logBuffs(msg)
end

-- INTERFACE
local BuffLogFrame = CreateFrame("Frame") -- Root frame

-- REGISTER EVENTS
BuffLogFrame:RegisterEvent("ADDON_LOADED")
BuffLogFrame:RegisterEvent("ENCOUNTER_START")
BuffLogFrame:RegisterEvent("READY_CHECK")
BuffLogFrame:RegisterEvent("TAXIMAP_OPENED")

-- REGISTER EVENT LISTENERS
BuffLogFrame:SetScript("OnEvent", function(self, event, arg1, ...) 
    BuffLogFrame:onEvent(self, event, arg1, ...) 
end);

-- COMMAND HANDLER
function BuffLog:logBuffs(msg)
    local buffs = BuffLog:getBuffs()
    BuffLog:saveBuffs(buffs)
end

-- EVENT HANDLER
function BuffLogFrame:onEvent(self, event, arg1, ...)
    if event == "ADDON_LOADED" then
        if arg1 == BuffLog.ADDON_NAME then
            local colorHex = "2979ff"
            print("|cff"..colorHex..BuffLog.ADDON_NAME.." loaded - /bufflog")
        end
    end

    -- AUTOMATICALLY COLLECT BUFFS WHEN A READY CHECK IS PERFORMED
    if event == "ENCOUNTER_START" or event == "READY_CHECK" then
        BuffLog:logBuffs(msg)
    end

    -- CLEAR SAVED VARIABLES WHENVER TALKING TO FLIGHTPATH
    -- AND THE VARIABLES ARE MORE THAN 12 HOURS OLD
    --(YOU WONT DO THIS IN A RAID ENVIRONMENT ANYWAY SO NO WAY TO ACCIDENTALLY DELETE THEM)
    if event == "TAXIMAP_OPENED" then
        if not BuffLog_LastLog then return end
        if time() - BuffLog_LastLog > 43200 then
            BuffLog_SavedBuffs = {}
        end
    end
end

-- BUFF LOG FUNCTIONS
function BuffLog:getBuffs()
    if UnitInRaid("player") then
        return BuffLog:getRaidBuffs()

    elseif UnitInParty("player") then
        return BuffLog:getPartyBuffs()

    else
        return BuffLog:getPlayerbuffs()
    end
end

function BuffLog:getPlayerbuffs()
    wipe(BuffLog.buffs)
    BuffLog.buffs[UnitGUID("player")] = BuffLog:getUnitBuffs("player")
    return BuffLog.buffs
end

function BuffLog:getPartyBuffs()
    local buffs = BuffLog:getPlayerbuffs()
    for i = 1, GetNumGroupMembers() - 1 do
        unit = "party" .. i
        BuffLog.buffs[UnitGUID(unit)] = BuffLog:getUnitBuffs(unit)
    end
    return BuffLog.buffs
end

function BuffLog:getRaidBuffs()
    wipe(BuffLog.buffs)
    for i = 1, GetNumGroupMembers() do
        unit = "raid" .. i
        BuffLog.buffs[UnitGUID(unit)] = BuffLog:getUnitBuffs(unit)
    end
    return BuffLog.buffs
end

function BuffLog:getUnitBuffs(unit)
    wipe(BuffLog.buffs)
    for buffIndex = 1, 40 do
        _, _, _, _, _, _, _, _, _, spellId = UnitBuff(unit, buffIndex)
        if spellId ~= nil then
            BuffLog.buffs[#BuffLog.buffs + 1] = spellId
        end
    end
    return BuffLog.buffs
end

function BuffLog:saveBuffs(buffs)
    local key = date("%m-%d-%H-%M-%S")
    BuffLog_SavedBuffs = BuffLog_SavedBuffs or {}
    BuffLog_SavedBuffs[key] = buffs
    BuffLog_LastLog = time()
    print("Buffs Logged")
end
