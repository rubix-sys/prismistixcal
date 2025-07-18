--[=[
	@class Dalgona
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Maid = require("@pkgs/maid")
local UIManager = require("@classes/UIManager")

local Dalgona = {}
Dalgona.__index = Dalgona

export type Fields = {
    _UIManager: UIManager.UIManager,
	_Maid: Maid.Maid,
}

export type Dalgona = typeof(setmetatable({} :: Fields, Dalgona))

function Dalgona.new(UIManager: UIManager.UIManager): Dalgona
    local self = setmetatable({}, Dalgona)

    self._UIManager = UIManager
    self._Maid = Maid.new()

    return self
end

function Dalgona.Start(self: Dalgona)
    local DalgonaClientModule = ReplicatedStorage.Modules.Games.DalgonaClient :: ModuleScript

    local function CompleteDalgona()
        --[[
            Search for the callback of RunService.RenderStepped
             containing an upvalue used to keep track of the amount of successful clicks
             for the Dalgona challenge.

            Setting this upvalue (amount of successful clicks) to a large number
             will allow it to pass the Dalgona challenge checks.
        ]]

        if not self._UIManager:GetToggleValue("DalgonaAuto") then return end

        for _, Value in ipairs(getreg()) do
            if typeof(Value) == "function" and islclosure(Value) then
                if getfenv(Value).script == DalgonaClientModule then
                    if getinfo(Value).nups == 73 then
                        setupvalue(Value, 31, 9e9)
                        break
                    end
                end
            end
        end
    end
    
    local OriginalDalgonaFunction
    OriginalDalgonaFunction = hookfunction((require)(DalgonaClientModule), function(...)
        task.delay(3, CompleteDalgona)        
        return OriginalDalgonaFunction(...)
    end)

    self._Maid:GiveTask(function()
        hookfunction((require)(DalgonaClientModule), OriginalDalgonaFunction)
        self._UIManager.Toggles.DalgonaAuto:OnChanged(function() end)
    end)
    
    self._UIManager.Toggles.DalgonaAuto:OnChanged(CompleteDalgona)
    
    warn("Dalgona feature started!")
end

function Dalgona.Destroy(self: Dalgona)
    warn("Dalgona feature destroyed!")
    self._Maid:Destroy()
end

return Dalgona
