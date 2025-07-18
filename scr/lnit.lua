
--[[
	@author Jorsan
]]

-- Validate game
assert(game.GameId == 7008097940, "Invalid Game!")

local Signal = require("@pkgs/goodsignal")

-- Setup Global State
if not shared._InkGameScriptState then
    shared._InkGameScriptState = {
        IsScriptExecuted = false,
        IsScriptReady = false,
        ScriptReady = Signal.new(),
        Cleanup = function() end
    }
end

local GlobalScriptState = shared._InkGameScriptState

-- Handle script re-execution
if GlobalScriptState.IsScriptExecuted then
    if not GlobalScriptState.IsScriptReady then
        GlobalScriptState.ScriptReady:Wait()
        if GlobalScriptState.IsScriptReady then return end
    end
    GlobalScriptState.Cleanup()
end

GlobalScriptState.IsScriptExecuted = true

-- Main
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local UI = require("@classes/UIManager").new()

local GameState = workspace:WaitForChild("Values") :: Folder
local CurrentGame = GameState:WaitForChild("CurrentGame") :: StringValue

local Features = {
    ["RedLightGreenLight"] = require("@classes/Rounds/RedLightGreenLight"),
    ["Dalgona"] = require("@classes/Rounds/Dalgona"),
    ["TugOfWar"] = require("@classes/Rounds/TugOfWar"),
    ["GlassBridge"] = require("@classes/Rounds/GlassBridge"),
    ["Mingle"] = require("@classes/Rounds/Mingle"),
    ["HideAndSeek"] = require("@classes/Rounds/HideAndSeek")
}

local CurrentRunningFeature: any = nil
local GameChangedConnection: RBXScriptConnection? = nil

local function CleanupCurrentFeature()
    if CurrentRunningFeature then
        CurrentRunningFeature:Destroy()
        CurrentRunningFeature = nil
    end
end

local function CurrentGameChanged()
    warn("Current game: " .. CurrentGame.Value)
    
    CleanupCurrentFeature()
    
    local Feature = Features[CurrentGame.Value]
    if not Feature then return end

    CurrentRunningFeature = Feature.new(UI)
    CurrentRunningFeature:Start()
end

-- Round updater
GameChangedConnection = CurrentGame:GetPropertyChangedSignal("Value"):Connect(CurrentGameChanged)
CurrentGameChanged()

-- Global cleanup function
GlobalScriptState.Cleanup = function()
    CleanupCurrentFeature()
    
    if GameChangedConnection then
        GameChangedConnection:Disconnect()
        GameChangedConnection = nil
    end
    
    if not UI.IsDestroyed then
        UI:Destroy()
    end
    
    GlobalScriptState.IsScriptReady = false
    GlobalScriptState.IsScriptExecuted = false
end

-- Mark as ready
GlobalScriptState.IsScriptReady = true
GlobalScriptState.ScriptReady:Fire()

UI:Notify("Script executed successfully!", 4)
UI:Notify("Script authored by: Jorsan, enjoy!", 4)
