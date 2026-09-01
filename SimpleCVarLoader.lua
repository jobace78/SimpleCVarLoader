-- SimpleCVarLoader.lua

SimpleCVarLoader             = SimpleCVarLoader or {}
SimpleCVarLoader.profiles    = SimpleCVarLoader.profiles or {}

local NAME                   = "SimpleCVarLoader"
local FAIL_MESSAGE_PREFIX    = "|cffff4444[SimpleCVarLoader]|r"
local SUCCESS_MESSAGE_PREFIX = "|cff00ccff[SimpleCVarLoader]|r"

local activeProfile          = nil

-- =======
-- HELPERS
-- =======

local function getProfile(profileName)
    return SimpleCVarLoader.profiles[profileName]
end

local function getActiveProfile()
    if not activeProfile then
        print(FAIL_MESSAGE_PREFIX .. " No active profile.")
        return nil
    end
    return getProfile(activeProfile)
end

local function applyProfile(profileName)
    local currentProfile = getProfile(profileName)
    local failCounter = 0
    local successCounter = 0
    if not currentProfile then
        print(FAIL_MESSAGE_PREFIX .. " Profile <" .. profileName .. "> not found.")
        return
    end
    for cvarName, cvarValue in pairs(currentProfile.cvars) do
        if C_CVar.SetCVar(cvarName, cvarValue) then
            successCounter = successCounter + 1
        else
            print(FAIL_MESSAGE_PREFIX .. " Invalid CVar: " .. cvarName)
            failCounter = failCounter + 1
        end
    end
    for _tweakName, tweakCode in pairs(currentProfile.tweaks) do
        RunScript(tweakCode)
    end
    activeProfile = profileName
    SimpleCVarLoader.activeProfile = profileName
    print(SUCCESS_MESSAGE_PREFIX ..
        " Profile <" ..
        profileName ..
        "> loaded, " ..
        successCounter .. " CVar(s) applied" .. (failCounter > 0 and ", " .. failCounter .. " CVar(s) failed." or "."))
end

-- ========================
-- SLASH COMMANDS (PROFILE)
-- ========================

local profileSlashCommand = {}

profileSlashCommand.list = function()
    if not next(SimpleCVarLoader.profiles) then
        print(FAIL_MESSAGE_PREFIX .. " No profiles found.")
        return
    end
    print(SUCCESS_MESSAGE_PREFIX .. " Profiles:")
    for currentProfileName, _ in pairs(SimpleCVarLoader.profiles) do
        local isActive = (currentProfileName == activeProfile) and " |cff00ff00(active)|r" or ""
        print(" - " .. currentProfileName .. isActive)
    end
end

profileSlashCommand.new = function(args)
    local currentProfileName = args:match("^(%S+)$")
    if not currentProfileName then
        print(FAIL_MESSAGE_PREFIX .. " Usage: /scvl profile new <name>")
        return
    end
    if getProfile(currentProfileName) then
        print(FAIL_MESSAGE_PREFIX .. " Profile <" .. currentProfileName .. "> already exists.")
        return
    end
    SimpleCVarLoader.profiles[currentProfileName] = { cvars = {}, tweaks = {} }
    print(SUCCESS_MESSAGE_PREFIX .. " Profile <" .. currentProfileName .. "> created.")
end

profileSlashCommand.set = function(args)
    local currentProfileName = args:match("^(%S+)$")
    if not currentProfileName then
        print(FAIL_MESSAGE_PREFIX .. " Usage: /scvl profile set <name>")
        return
    end
    applyProfile(currentProfileName)
end

profileSlashCommand.delete = function(args)
    local currentProfileName = args:match("^(%S+)$")
    if not currentProfileName then
        print(FAIL_MESSAGE_PREFIX .. " Usage: /scvl profile delete <name>")
        return
    end
    if not getProfile(currentProfileName) then
        print(FAIL_MESSAGE_PREFIX .. " Profile <" .. currentProfileName .. "> not found.")
        return
    end
    SimpleCVarLoader.profiles[currentProfileName] = nil
    if activeProfile == currentProfileName then
        activeProfile = nil
        SimpleCVarLoader.activeProfile = nil
    end
    print(SUCCESS_MESSAGE_PREFIX .. " Profile <" .. currentProfileName .. "> deleted.")
end

-- =====================
-- SLASH COMMANDS (CVAR)
-- =====================

local cvarSlashCommand = {}

cvarSlashCommand.list = function()
    local currentProfile = getActiveProfile()
    if not currentProfile then
        return
    end
    print(SUCCESS_MESSAGE_PREFIX .. " Profile <" .. activeProfile .. "> CVar(s):")
    for cvar, value in pairs(currentProfile.cvars) do
        local defaultValue = C_CVar.GetCVarDefault(cvar)
        local valueColor = (defaultValue and value == defaultValue) and "|cff00ff00" or "|cffff8800"
        local defaultInfo = defaultValue and "|cffaaaaaa(" .. defaultValue .. ")|r" or "|cffaaaaaa(N/A)|r"
        print(string.format("  %s = %s%s|r %s", cvar, valueColor, value, defaultInfo))
    end
end

cvarSlashCommand.set = function(args)
    local currentProfile = getActiveProfile()
    if not currentProfile then
        return
    end
    local cvar, value = args:match("^(%S+)%s+(%S+)$")
    if not cvar or not value then
        print(FAIL_MESSAGE_PREFIX .. " Usage: /scvl cvar set <name> <value>")
        return
    end
    local defaultValue = C_CVar.GetCVarDefault(cvar)
    local existed = currentProfile.cvars[cvar] ~= nil
    currentProfile.cvars[cvar] = value
    if C_CVar.SetCVar(cvar, value) then
        local valueColor = (defaultValue and value == defaultValue) and "|cff00ff00" or "|cffff8800"
        local defaultInfo = defaultValue and "|cffaaaaaa(" .. defaultValue .. ")|r" or "|cffaaaaaa(N/A)|r"
        print(SUCCESS_MESSAGE_PREFIX ..
            " " ..
            cvar .. " = " .. valueColor .. value .. "|r " .. defaultInfo .. (existed and " (updated)" or " (added)"))
    else
        currentProfile.cvars[cvar] = nil
        print(FAIL_MESSAGE_PREFIX .. " Invalid CVar: " .. cvar)
    end
end

cvarSlashCommand.delete = function(args)
    local currentProfile = getActiveProfile()
    if not currentProfile then
        return
    end
    local cvar = args:match("^(%S+)$")
    if not cvar then
        print(FAIL_MESSAGE_PREFIX .. " Usage: /scvl cvar delete <name>")
        return
    end
    if not currentProfile.cvars[cvar] then
        print(FAIL_MESSAGE_PREFIX .. " No override found for: " .. cvar)
        return
    end
    currentProfile.cvars[cvar] = nil
    print(SUCCESS_MESSAGE_PREFIX .. " CVar removed: " .. cvar)
end

-- ======================
-- SLASH COMMANDS (TWEAK)
-- ======================

local tweakSlashCommand = {}

tweakSlashCommand.list = function()
    local currentProfile = getActiveProfile()
    if not currentProfile then
        return
    end
    print(SUCCESS_MESSAGE_PREFIX .. " profile <" .. activeProfile .. "> — tweaks:")
    for tweakName, tweakCode in pairs(currentProfile.tweaks) do
        print(string.format("  |cff00ff00%s|r = %s", tweakName, tweakCode))
    end
end

tweakSlashCommand.set = function(args)
    local currentProfile = getActiveProfile()
    if not currentProfile then
        return
    end
    local tweakName, tweakCode = args:match("^(%S+)%s+(.+)$")
    if not tweakName or not tweakCode then
        print(FAIL_MESSAGE_PREFIX .. " Usage: /scvl tweak set <name> <code>")
        return
    end
    local existed = currentProfile.tweaks[tweakName] ~= nil
    local success, err = pcall(RunScript, tweakCode)
    if success then
        currentProfile.tweaks[tweakName] = tweakCode
        print(SUCCESS_MESSAGE_PREFIX .. " Tweak " .. tweakName .. (existed and " (updated)" or " (added)"))
    else
        print(FAIL_MESSAGE_PREFIX .. " Tweak failed: " .. tostring(err))
    end
end

tweakSlashCommand.delete = function(args)
    local currentProfile = getActiveProfile()
    if not currentProfile then
        return
    end
    local tweakName = args:match("^(%S+)$")
    if not tweakName then
        print(FAIL_MESSAGE_PREFIX .. " Usage: /scvl tweak delete <name>")
        return
    end
    if not currentProfile.tweaks[tweakName] then
        print(FAIL_MESSAGE_PREFIX .. " No custom tweak found: " .. tweakName)
        return
    end
    currentProfile.tweaks[tweakName] = nil
    print(SUCCESS_MESSAGE_PREFIX .. " Tweak removed: " .. tweakName)
end

-- ==============
-- SLASH COMMANDS
-- ==============

local slashCommand = {}

slashCommand.profile = function(args)
    local cmd, cmdArgs = args:match("^(%S+)%s*(.*)$")
    cmd = cmd and cmd:lower() or ""
    if profileSlashCommand[cmd] then
        profileSlashCommand[cmd](cmdArgs)
    else
        print(FAIL_MESSAGE_PREFIX .. " Usage: /scvl profile [ list | new | set | delete ]")
    end
end

slashCommand.cvar = function(args)
    local cmd, cmdArgs = args:match("^(%S+)%s*(.*)$")
    cmd = cmd and cmd:lower() or ""
    if cvarSlashCommand[cmd] then
        cvarSlashCommand[cmd](cmdArgs)
    else
        print(FAIL_MESSAGE_PREFIX .. " Usage: /scvl cvar [ list | set | delete ]")
    end
end

slashCommand.tweak = function(args)
    local cmd, cmdArgs = args:match("^(%S+)%s*(.*)$")
    cmd = cmd and cmd:lower() or ""
    if tweakSlashCommand[cmd] then
        tweakSlashCommand[cmd](cmdArgs)
    else
        print(FAIL_MESSAGE_PREFIX .. " Usage: /scvl tweak [ list | set | delete ]")
    end
end

SLASH_SIMPLECVARLOADER1 = "/simplecvarloader"

SLASH_SIMPLECVARLOADER2 = "/scvl"

SlashCmdList["SIMPLECVARLOADER"] = function(args)
    local cmd, cmdArgs = args:match("^(%S+)%s*(.*)$")
    cmd = cmd and cmd:lower() or ""
    if slashCommand[cmd] then
        slashCommand[cmd](cmdArgs)
    else
        print(SUCCESS_MESSAGE_PREFIX .. " Commands:")
        print(" /scvl profile list")
        print(" /scvl profile new <name>")
        print(" /scvl profile set <name>")
        print(" /scvl profile delete <name>")
        print(" /scvl cvar list")
        print(" /scvl cvar set <name> <value>")
        print(" /scvl cvar delete <name>")
        print(" /scvl tweak list")
        print(" /scvl tweak set <name> <code>")
        print(" /scvl tweak delete <name>")
    end
end

-- ====
-- MAIN
-- ====

---@diagnostic disable-next-line: missing-parameter
local frame = CreateFrame("Frame", NAME .. "Frame")

frame:RegisterEvent("PLAYER_LOGIN")

---@diagnostic disable-next-line: undefined-field
frame:SetScript(
    "OnEvent", function(_self, event)
        if event == "PLAYER_LOGIN" then
            local currentProfileName = SimpleCVarLoader.activeProfile
            if currentProfileName and getProfile(currentProfileName) then
                applyProfile(currentProfileName)
            else
                print(FAIL_MESSAGE_PREFIX .. " No active profile.")
            end
        end
    end
)
