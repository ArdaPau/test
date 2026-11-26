local ids = {
    -- buraya test edecegin ID'leri yaz, her biri virgulle ayrilmis sayi:
    123456789,
    -- 987654321,
}

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local req = syn and syn.request or http_request or request or (http and http.request)

-- eski harness penceresini sil
local core = (gethui and gethui()) or game:GetService("CoreGui")
local old = core:FindFirstChild("EmoteHarness")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "EmoteHarness"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5000
gui.Parent = core

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(300, 60)
frame.Position = UDim2.new(1, -310, 0, 60)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
frame.BorderSizePixel = 0
frame.Parent = gui
local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = frame

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 3)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = frame

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 6)
pad.PaddingLeft = UDim.new(0, 6)
pad.PaddingRight = UDim.new(0, 6)
pad.PaddingBottom = UDim.new(0, 6)
pad.Parent = frame

local function addLine(text, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -12, 0, 13)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.Code
    l.TextSize = 10
    l.TextColor3 = color
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = false
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.Text = text
    l.LayoutOrder = #frame:GetChildren()
    l.Parent = frame
end

git = nil
local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
local animator = hum and hum:FindFirstChildOfClass("Animator")
if not animator then
    addLine("Karakter/Humanoid yok", Color3.fromRGB(239, 68, 68))
    return
end

local R15_BONES = { "UpperTorso", "LowerTorso", "RightUpperArm", "LeftUpperLeg", "Head" }

for _, id in ipairs(ids) do
    local url = "rbxassetid://" .. tostring(id)
    local info = req and "?" or "request yok"
    if req then
        local ok, res = pcall(function()
            return req({ Url = "https://assetdelivery.roblox.com/v1/asset?id=" .. tostring(id) })
        end)
        if not ok or not res or res.StatusCode ~= 200 then
            info = "ERISIM YOK (private/silinmis)"
        else
            local body = res.Body or ""
            local r15 = false
            for _, bone in ipairs(R15_BONES) do
                if string.find(body, bone, 1, true) then r15 = true break end
            end
            info = r15 and "R15 UYUMLU" or "R6-ONLY"
        end
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = url
    local okLoad, track = pcall(function() return animator:LoadAnimation(anim) end)
    local loadStr, okAll = "YUKLENEMEDI", false
    if okLoad and track then
        loadStr = string.format("YUKLENDI (%.1fs)", track.Length)
        okAll = (info == "R15 UYUMLU") and track.Length > 0
        track:Destroy()
    end
    anim:Destroy()

    addLine(string.format("%s | %s | %s", tostring(id), loadStr, info),
        okAll and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68))
end
