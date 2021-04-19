-- Plugin setup
local plugin = script:FindFirstAncestorWhichIsA("Plugin")
if plugin == nil then return end
local Toolbar = plugin:CreateToolbar("Development tools")
local Button = Toolbar:CreateButton("Lighting Toggle", "Toggle game lighting between gameplay and development", "rbxassetid://463925648");

-- Only execute this during a Studio session, not during testing.
local RunService = game:GetService("RunService")
local IsRunning = RunService:IsRunning()
if IsRunning then return end

--Establish services needed
local GameLighting = {}
local Lighting      = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

local TempFolder        = script:WaitForChild("LightingStorage")
--Get our Development Profile
local DevelopmentFolder = ServerStorage:FindFirstChild("DevelopmentLighting") or TempFolder:Clone()
DevelopmentFolder.Name  = "DevelopmentLighting"
DevelopmentFolder.Parent= ServerStorage
--Get our Game Profile
local GameFolder        = Lighting:FindFirstChild("GameLighting") or TempFolder:Clone()
local Initial           = GameFolder.Name == "LightingStorage"
GameFolder.Name         = "GameLighting"

--Properties we will search through; this includes properties from PostEffects, as it was intended to store data as strings originally.
local PropertiesToSearch = {
    --Lighting Appearance
    "Ambient";
    "Brightness";
    "ColorShift_Bottom";
    "ColorShift_Top";
    "EnvironmentDiffuseScale";
    "EnvironmentSpecularScale";
    "GlobalShadows";
    "OutdoorAmbient";
    "ShadowSoftness";
    "FogEnd";
    "FogStart";
    "FogColor";
    --Lighting Data
    "ClockTime";
    "GeographicLatitude";
    "TimeOfDay";
    "ExposureCompensation";
    --PostEffects
    "Enabled";
    "Intensity";
    --Bloom
    "Size";
    "Threshold";
    --SunRays
    "Spread";
    --ColorCorrection
    "Contrast";
    "Saturation";
    "TintColor";
    --BlurEffect;
}

-- All the Lighting-changing objects that we will want to capture & change.
local ClassesToScan = {
    "PostEffect";
    "Sky";
    "Atmosphere";
    "Clouds";
}

local State = "Game"

function Development()
    --Use our development lighting setup
    --Revert to our Lighting profile
    for Name, Value in pairs(DevelopmentFolder:GetAttributes()) do
        Lighting[Name] = Value
    end
    --Place our contents in the Lighting
    for _, x in pairs(DevelopmentFolder:GetChildren()) do
        x.Parent = Lighting
    end
end

function ClearDevelopment()
     --Only clear the children that are "Lighting" objects
     for _, Object in pairs(Lighting:GetChildren()) do
        if Object ~= GameFolder then
            for n, x in pairs(ClassesToScan) do
                if Object:IsA(x) then
                    Object.Parent = DevelopmentFolder
                    break
                end
            end
        end
    end
    --Iterate through the Properties table, use a PCall to determine if the property exists or not.
    for _, PropertyName in pairs(PropertiesToSearch) do
        local HasProperty, PropertyValue = pcall(function()
            local ISAPROPERTY = Lighting[PropertyName]
            return ISAPROPERTY
        end)
        if HasProperty then
            DevelopmentFolder:SetAttribute(PropertyName, PropertyValue) --Make changes to our Development Folder.
        else continue
        end
    end
end

function SaveGameState()
    --Iterate through the Properties table, use a PCall to determine if the property exists or not.
    for _, PropertyName in pairs(PropertiesToSearch) do
        local HasProperty, PropertyValue = pcall(function()
            local ISAPROPERTY = Lighting[PropertyName]
            return ISAPROPERTY
        end)
        if HasProperty then
            GameFolder:SetAttribute(PropertyName, PropertyValue) --Make changes to our Game Folder.
        else continue
        end
    end
    --Only clear the children that are "Lighting" objects
    for _, Object in pairs(Lighting:GetChildren()) do
        if Object ~= GameFolder then
            for n, x in pairs(ClassesToScan) do
                if Object:IsA(x) then
                    Object.Parent = GameFolder
                    break
                end
            end
        end
    end

    GameFolder.Parent = Lighting;
end

function InGame()
    --Revert to our Lighting profile
    for Name, Value in pairs(GameFolder:GetAttributes()) do
        Lighting[Name] = Value
    end
    --Return our contents. We know all contents are Lighting objects
    for n, x in pairs(GameFolder:GetChildren()) do
        x.Parent = Lighting
    end
    GameFolder.Parent = nil;    --Parent to nil, not remove. May use again.
end

function GameLighting.ChangeState(NewState)
    if State == NewState then return
    elseif NewState == "Game" then
        print("GameState")          --Printed cue
        ClearDevelopment()
        InGame()
        State = "Game"
    elseif NewState == "Development" then
        print("DevelopmentState")   --Printed cue
        SaveGameState()
        Development()
        State = "Development"
    elseif NewState == "Reset" then --Unused; would revert development/game to their original versions.
        InGame()
        State = "Game"
    end
end

if Initial then --The game didn't have a GameLighting profile. First setup.
    GameFolder:ClearAllChildren()
elseif #GameFolder:GetChildren() ~= 0 then
    State = "Development"
end

--Shortcut keys
local DevAction = plugin:CreatePluginAction("MoveToInDevLightingState",     "Development Lighting", "Toggles the game's lighting into development mode",    nil, true)
local GameAction = plugin:CreatePluginAction("MoveIntoGameLightingState",    "Game Lighting",        "Toggles the game's lighting into 'In-Game' mode",      nil, true)

--Shortcut actions
GameAction.Triggered:Connect(function()
    GameLighting.ChangeState("Game")
end)
DevAction.Triggered:Connect(function()
    GameLighting.ChangeState("Development")
end)

--Revert to game in the case of plugin removal/deactivation.
function GameLighting.Deactivate()
    GameLighting.ChangeState("Game")
end

--Button stuff
Button.Click:Connect(function()
    if plugin:IsActivated() == false then
        GameLighting.ChangeState("Development")
        plugin:Activate(true)
    else
        GameLighting.ChangeState("Game")
        plugin:Deactivate()
    end
end)

--Deactivation stuff
plugin.Deactivation:Connect(GameLighting.Deactivate) --If we are told to close
plugin.Unloading:Connect(GameLighting.Deactivate) --If we are unloading this plugin.

return GameLighting
