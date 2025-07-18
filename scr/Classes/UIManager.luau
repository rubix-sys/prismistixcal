--[=[
	@class UIManager
]=]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Maid = require("@pkgs/maid")

local UIManager = {}
UIManager.__index = UIManager

export type Fields = {
    _Library: any,
    _ThemeManager: any,
	_Maid: Maid.Maid,
    _Window: any,
    _Tabs: any,
    IsDestroyed: boolean,
    Toggles: any,
    Options: any,
}

export type UIManager = typeof(setmetatable({} :: Fields, UIManager))

function UIManager.new(): UIManager
    local self = setmetatable({}, UIManager)
    
    self._Library = require("@libraries/LinoriaLib/Library")
    self._ThemeManager = require("@libraries/LinoriaLib/ThemeManager")

    self._ThemeManager:SetLibrary(self._Library)

    self._Maid = Maid.new()
    self._Window = self._Library:CreateWindow({
        Title = game:GetService("MarketplaceService"):GetProductInfo(109983668079237).Name .. " | Prismistix",
        Center = true,
        AutoShow = true,
        TabPadding = 8,
        MenuFadeTime = 0.2,
        Size = UDim2.new(0, 525, 0, 400)
    })

    self._Tabs = {}
    
    self.IsDestroyed = false
    
    self.Toggles = self._Library.Toggles
    self.Options = self._Library.Options

    self:_SetupTabs()
    
    self._Maid:GiveTask(function()
        self.IsDestroyed = true

        -- Terminate the script
        shared._InkGameScriptState.Cleanup()

        -- Unload UI library
        self._Library:Unload()
    end)

    self._ThemeManager:ApplyTheme("Tokyo Night")
    
    return self
end

function UIManager._SetupTabs(self: UIManager)
    -- Create tabs
    self._Tabs = {
        Main = self._Window:AddTab("Main"),
        Player = self._Window:AddTab("Player"),
        Settings = self._Window:AddTab("Settings")
    }
    
    -- Setup tabs
    self:_SetupMainCheatsTab()
    self:_SetupPlayerTab()
    self:_SetupSettingsTab()
end

function UIManager._SetupMainCheatsTab(self: UIManager)
    local RoundCheatsGroup = self._Tabs.Main:AddLeftGroupbox("Round Cheats"
    
    -- Tug of War Auto Pull
    RoundCheatsGroup:AddToggle("TugOfWarAuto", {
        Text = "Auto Tug Of War",
        Default = false,
        Tooltip = "Automatically pulls during Tug of War game"
    })
    
    -- Dalgona Auto Complete
    RoundCheatsGroup:AddToggle("DalgonaAuto", {
        Text = "Auto Dalgona",
        Default = false,
        Tooltip = "Automatically completes the Dalgona cookie challenge"
    })

    -- Mingle power hold minigame/QTE Auto solver
    RoundCheatsGroup:AddToggle("MinglePowerHoldAuto", {
        Text = "Auto Mingle & Power Hold",
        Default = false,
        Tooltip = "Automatically completes the Mingle power hold minigame/QTE"
    })
    
    -- ESP/Visuals
    local VisualsGroup = self._Tabs.Main:AddRightGroupbox("Visual ESP")

    VisualsGroup:AddLabel("Hide And Seek")

    VisualsGroup:AddToggle("HiderESP", {
        Text = "Hider ESP",
        Default = false,
        Tooltip = "Visually shows where the hiders are located and their status"
    })

    VisualsGroup:AddToggle("HunterESP", {
        Text = "Seeker ESP",
        Default = false,
        Tooltip = "Visually shows where the Seekers are located and their status"
    })

    VisualsGroup:AddDivider()
    VisualsGroup:AddLabel("Glass Bridge")
    
    VisualsGroup:AddToggle("GlassBridgeESP", {
        Text = "Show Safe Glass Panels",
        Default = false,
        Tooltip = "Visually shows which glass panels are safe to step on"
    })
end

function UIManager._SetupPlayerTab(self: UIManager)
    local PlayerSettings = self._Tabs.Player:AddLeftGroupbox("Player Modifications")

    -- NoClip Toggle
    PlayerSettings:AddToggle("EnableWalkSpeed", {
        Text = "Enable WalkSpeed",
        Default = false
    })

    -- WalkSpeed Changer
    PlayerSettings:AddSlider("WalkSpeed", {
        Text = "Walk Speed",
        Default = 16,
        Min = 1,
        Max = 100,
        Rounding = 0,
        Compact = false,
        Suffix = " studs/s"
    })

    -- Add divider
    PlayerSettings:AddDivider()

    -- NoClip Toggle
    PlayerSettings:AddToggle("Noclip", {
        Text = "Noclip",
        Default = false,
        Tooltip = "Walk through walls"
    })

    -- Setup character cheats
    local Client = Players.LocalPlayer
    local CharacterMaid: Maid.Maid = Maid.new()
    
    self._Maid:GiveTask(CharacterMaid)

    local function OnCharacterAdded(Character: Model)
        CharacterMaid:DoCleaning()
        local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
        
        local CachedBaseParts: {BasePart} = {}

        for _, Object in ipairs(Character:GetDescendants()) do
            if Object:IsA("BasePart") then
                table.insert(CachedBaseParts, Object)
            end
        end

        CharacterMaid:GiveTask(Character.DescendantAdded:Connect(function(Descendant)
            if Descendant:IsA("BasePart") then
                table.insert(CachedBaseParts, Descendant)
            end
        end))
        
        local function ChangeWalkSpeed()
            if not self:GetToggleValue("EnableWalkSpeed") then return end

            local NewWalkSpeed: number = self:GetOptionValue("WalkSpeed")
            if not NewWalkSpeed then return end
        
            Humanoid.WalkSpeed = NewWalkSpeed
        end
        
        CharacterMaid:GiveTask(Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(ChangeWalkSpeed))

        local NoclippedBaseParts: {[BasePart]: boolean} = {}

        CharacterMaid:GiveTask(RunService.Stepped:Connect(function()
            if not self:GetToggleValue("Noclip") then
                for BasePart : BasePart, _ in NoclippedBaseParts do
                    NoclippedBaseParts[BasePart] = nil
                    BasePart.CanCollide = true
                end
                return
            end

            for _, BasePart in ipairs(CachedBaseParts) do
                if BasePart.CanCollide then
                    NoclippedBaseParts[BasePart] = true
                    BasePart.CanCollide = false
                end
            end
        end))
        
        CharacterMaid:GiveTask(function()
            table.clear(CachedBaseParts)
            for BasePart, _ in NoclippedBaseParts do
                NoclippedBaseParts[BasePart] = nil
                BasePart.CanCollide = true
            end
        end)

        self.Toggles.EnableWalkSpeed:OnChanged(ChangeWalkSpeed)
        self.Options.WalkSpeed:OnChanged(ChangeWalkSpeed)
    end

    self._Maid:GiveTask(function()
        self.Toggles.EnableWalkSpeed:OnChanged(function() end)
        self.Options.WalkSpeed:OnChanged(function() end)
    end)
    
    self._Maid:GiveTask(Client.CharacterAdded:Connect(OnCharacterAdded))
    
    if Client.Character then
        task.spawn(OnCharacterAdded, Client.Character)
    end
end

function UIManager._SetupSettingsTab(self: UIManager)
    local MenuSettings = self._Tabs.Settings:AddLeftGroupbox("Menu Settings")
    
    MenuSettings:AddButton({
        Text = "Unload/Destroy Script",
        Func = function()
            self:Destroy()
        end,
        Tooltip = "Completely removes and destroys the script"
    })
end

function UIManager.GetToggleValue(self: UIManager, ToggleName: string)
    if self.Toggles and self.Toggles[ToggleName] then
        return self.Toggles[ToggleName].Value
    end
    return false
end

function UIManager.GetOptionValue(self: UIManager, OptionName: string)
    return self.Options[OptionName].Value
end

function UIManager.Notify(self: UIManager, Text: string, Duration: number)
    if not self._Library then return end
    self._Library:Notify(Text, Duration)
end

function UIManager.Destroy(self: UIManager)
    if self.IsDestroyed then return end
    self._Maid:Destroy()
    
    warn("UIManager destroyed successfully!")
end

return UIManager
