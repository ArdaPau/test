-- [[ Rscripts Risk Notice ]]
-- This script is not verified by rscripts.net. Deal with caution.
--
-- Stay safe:
--   • Never log in on unofficial Roblox sites or lookalike domains.
--   • Real Roblox links use roblox.com (check the .com ending).
--   • Treat fake Roblox login / "claim reward" pages as phishing.
-- [[ End Rscripts Risk Notice ]]
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local localPlayer = Players.LocalPlayer

local function findPlayer(query)
    local results = {}
    local lowerQuery = query:lower()
    
    for _, player in pairs(Players:GetPlayers()) do
        if lowerQuery == "tous" then
            table.insert(results, player)
        elseif lowerQuery == "autres" and player.Name ~= localPlayer.Name then
            table.insert(results, player)
        elseif lowerQuery == "moi" and player.Name == localPlayer.Name then
            table.insert(results, player)
        elseif player.Name:lower():sub(1, #query) == lowerQuery then
            table.insert(results, player)
        end
    end
    
    return results
end

local function notify(message, duration)
    StarterGui:SetCore("SendNotification", {
        Title = "Yeet GUI V2",
        Text = message,
        Icon = "rbxassetid://2005276185",
        Duration = duration or 3
    })
end

-- Interface setup
local screenGui = Instance.new("ScreenGui", CoreGui)
screenGui.Name = "YeetInterface"
screenGui.ResetOnSpawn = false

local backgroundImage = Instance.new("ImageLabel", screenGui)
backgroundImage.Name = "BackgroundImage"
backgroundImage.Image = "rbxassetid://" -- Remplacez par l'ID de votre image d'anime girl
backgroundImage.Size = UDim2.new(1, 0, 1, 0)
backgroundImage.Position = UDim2.new(0, 0, 0, 0)
backgroundImage.BackgroundTransparency = 1
backgroundImage.ImageTransparency = 0.2

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Name = "MainFrame"
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 105, 180) -- Utilisation d'une couleur vibrante (rose)
mainFrame.BorderSizePixel = 0
mainFrame.Position = UDim2.new(0.35, 0, 0.35, 0)
mainFrame.Size = UDim2.new(0, 454, 0, 218)
mainFrame.BackgroundTransparency = 0.3

local header = Instance.new("Frame", mainFrame)
header.Name = "Header"
header.BackgroundColor3 = Color3.fromRGB(255, 182, 193) -- Couleur de l'en-tête en rose clair
header.BorderSizePixel = 0
header.Size = UDim2.new(1, 0, 0, 44)

local titleLabel = Instance.new("TextLabel", header)
titleLabel.Name = "TitleLabel"
titleLabel.BackgroundColor3 = Color3.fromRGB(255, 182, 193)
titleLabel.BorderSizePixel = 0
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.Text = "Yeet GUI"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.TextSize = 14
titleLabel.TextWrapped = true

local inputBox = Instance.new("TextBox", mainFrame)
inputBox.Name = "InputBox"
inputBox.BackgroundColor3 = Color3.fromRGB(255, 192, 203) -- Couleur de la zone de texte en rose
inputBox.BorderSizePixel = 0
inputBox.Position = UDim2.new(0.07, 0, 0.27, 0)
inputBox.Size = UDim2.new(0.86, 0, 0, 62)
inputBox.Font = Enum.Font.FredokaOne
inputBox.PlaceholderText = "Pseudo"
inputBox.Text = ""
inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
inputBox.TextScaled = true
inputBox.TextSize = 14
inputBox.TextWrapped = true

local actionButton = Instance.new("TextButton", mainFrame)
actionButton.Name = "ActionButton"
actionButton.BackgroundColor3 = Color3.fromRGB(255, 20, 147) -- Couleur du bouton en rose foncé
actionButton.BorderSizePixel = 0
actionButton.Position = UDim2.new(0.07, 0, 0.62, 0)
actionButton.Size = UDim2.new(0.86, 0, 0, 50)
actionButton.Font = Enum.Font.FredokaOne
actionButton.Text = "Crash"
actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
actionButton.TextScaled = true
actionButton.TextSize = 14
actionButton.TextWrapped = true
actionButton.AutoButtonColor = false
actionButton.ClipsDescendants = true

-- Apply UICorner for rounded UI elements
local function applyRoundCorners(instance)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 30)
    corner.Parent = instance
end

applyRoundCorners(mainFrame)
applyRoundCorners(header)
applyRoundCorners(titleLabel)
applyRoundCorners(inputBox)
applyRoundCorners(actionButton)

actionButton.MouseButton1Click:Connect(function()
    local targets = findPlayer(inputBox.Text)
    if #targets > 0 then
        local target = targets[1]
        local thrust = Instance.new('BodyThrust', localPlayer.Character.HumanoidRootPart)
        thrust.Force = Vector3.new(9999, 9999, 9999)
        thrust.Name = "YeetForce"
        repeat
            localPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
            thrust.Location = target.Character.HumanoidRootPart.Position
            RunService.Heartbeat:Wait()
        until not target.Character:FindFirstChild("Head")
    else
        notify("Ce joueur est parti ou n'existe pas.", 3)
    end
end)

notify("Loaded By GJBBY", 5)
