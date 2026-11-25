--=============================================================
--  Job ID Joiner v2  |  Mobile executor panel (failsafe)
--=============================================================
local Players          = game:GetService("Players")
local TeleportService  = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local player           = Players.LocalPlayer

pcall(function() if _G.__JOINER_GUI then _G.__JOINER_GUI:Destroy() end end)

local function getParent()
    local ok, hui = pcall(function() return gethui() end)
    if ok and hui then return hui end
    local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and cg then return cg end
    return player:WaitForChild("PlayerGui")
end

local function makeDraggable(handle, frame)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- link / jobId ayıklama
local UUID = "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x"

local function parseInput(raw)
    raw = (raw or ""):gsub("%s+", "")
    local placeFromUrl = raw:match("roblox%.com/games/(%d+)")
    local jobFromUrl   = raw:match("[?&]jobId=([%w%-_]+)")
    local jobId = jobFromUrl
        or raw:match(UUID)
        or raw:match("([%w%-_]+)$")
        or ""
    return jobId, placeFromUrl
end

local function validJobId(id)
    if #id < 20 then return false end
    return id:match("^[%w%-_]+$") ~= nil
end

-- ---------------- UI ----------------
local screen = Instance.new("ScreenGui")
screen.Name = "JobJoiner"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.DisplayOrder = 999
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = getParent()
_G.__JOINER_GUI = screen

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0, 52, 0, 52)
toggle.AnchorPoint = Vector2.new(1, 0.5)
toggle.Position = UDim2.new(1, -16, 0.5, 0)
toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
toggle.Text = "J"
toggle.TextColor3 = Color3.fromRGB(120, 200, 255)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 24
toggle.BorderSizePixel = 0
toggle.Parent = screen
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 16)
local tS = Instance.new("UIStroke", toggle)
tS.Color = Color3.fromRGB(70, 130, 180); tS.Thickness = 2

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 300, 0, 196)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screen
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
local pS = Instance.new("UIStroke", panel)
pS.Color = Color3.fromRGB(60, 60, 76); pS.Thickness = 1

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundTransparency = 1
header.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(235, 235, 242)
title.Text = "Server Joiner"
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 34, 0, 34)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -6, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

makeDraggable(header, panel)

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -104, 0, 42)
box.Position = UDim2.new(0, 14, 0, 50)
box.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
box.BorderSizePixel = 0
box.PlaceholderText = "Job ID veya sunucu linki..."
box.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
box.Text = ""
box.ClearTextOnFocus = false
box.Font = Enum.Font.Gotham
box.TextSize = 13
box.TextColor3 = Color3.fromRGB(230, 230, 240)
box.TextXAlignment = Enum.TextXAlignment.Left
box.Parent = panel
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)
Instance.new("UIPadding", box).PaddingLeft = UDim.new(0, 10)

local pasteBtn = Instance.new("TextButton")
pasteBtn.Size = UDim2.new(0, 76, 0, 42)
pasteBtn.Position = UDim2.new(1, -90, 0, 50)
pasteBtn.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
pasteBtn.Text = "Yapıştır"
pasteBtn.Font = Enum.Font.GothamMedium
pasteBtn.TextSize = 13
pasteBtn.TextColor3 = Color3.fromRGB(170, 200, 240)
pasteBtn.BorderSizePixel = 0
pasteBtn.Parent = panel
Instance.new("UICorner", pasteBtn).CornerRadius = UDim.new(0, 10)

local joinBtn = Instance.new("TextButton")
joinBtn.Size = UDim2.new(1, -28, 0, 46)
joinBtn.Position = UDim2.new(0, 14, 0, 102)
joinBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 90)
joinBtn.Text = "JOIN"
joinBtn.Font = Enum.Font.GothamBold
joinBtn.TextSize = 15
joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
joinBtn.BorderSizePixel = 0
joinBtn.Parent = panel
Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 10)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -28, 0, 30)
status.Position = UDim2.new(0, 14, 0, 154)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextColor3 = Color3.fromRGB(150, 150, 165)
status.Text = "Hazır."
status.TextWrapped = true
status.Parent = panel

local function setStatus(msg, color)
    status.Text = msg
    status.TextColor3 = color or Color3.fromRGB(150, 150, 165)
end

local open = false
local function setOpen(state)
    open = state
    if open then
        panel.Visible = true
        panel.Size = UDim2.new(0, 260, 0, 196)
        TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad),
            {Size = UDim2.new(0, 300, 0, 196)}):Play()
    else
        local t = TweenService:Create(panel, TweenInfo.new(0.12, Enum.EasingStyle.Quad),
            {Size = UDim2.new(0, 260, 0, 196)})
        t:Play()
        t.Completed:Connect(function() panel.Visible = false end)
    end
end

toggle.MouseButton1Click:Connect(function() setOpen(not open) end)
closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then setOpen(not open) end
end)

pasteBtn.MouseButton1Click:Connect(function()
    local ok, clip = pcall(function() return getclipboard() end)
    if ok and type(clip) == "string" and clip ~= "" then
        box.Text = clip:gsub("%s+", "")
        setStatus("Panodan alındı.", Color3.fromRGB(150, 200, 150))
    else
        setStatus("Pano okunamadı, elle yapıştır.", Color3.fromRGB(220, 170, 80))
    end
end)

-- ---------------- join ----------------
local busy = false

local function failMsg(reason, extra)
    busy = false
    local r = tostring(reason)
    local hint = ({
        ServerFull   = "Sunucu dolu.",
        GameFull     = "Oyun/place dolu.",
        SameServer   = "Zaten o sunucudasın.",
        Restricted   = "Erişim kısıtlı (private/premium).",
        Unauthorized = "Yetkisiz (teleport kapalı).",
        TeleportFailed = "Roblox teleportu reddetti.",
        HTTPError    = "Bağlantı hatası, tekrar dene.",
    })[r] or ("Teleport başarısız: " .. r)
    if extra and extra ~= "" then hint = hint .. " " .. tostring(extra) end
    setStatus(hint, Color3.fromRGB(230, 90, 90))
end

local function doJoin()
    if busy then return end
    local jobId, placeFromUrl = parseInput(box.Text)
    local placeId = placeFromUrl and tonumber(placeFromUrl) or game.PlaceId

    if not validJobId(jobId) then
        setStatus("Geçersiz Job ID ("..tostring(#jobId).." karakter).", Color3.fromRGB(230, 90, 90))
        return
    end

    busy = true
    setStatus("Bağlanılıyor... ("..placeId..")", Color3.fromRGB(120, 200, 255))

    local settled = false
    local conn

    local function finish()
        settled = true
        if conn then pcall(function() conn:Disconnect() end) end
        busy = false
    end

    conn = TeleportService.TeleportInitFailed:Connect(function(_, result, msg)
        if settled then return end
        settled = true
        pcall(function() conn:Disconnect() end)
        failMsg(result, msg)
    end)

    task.delay(12, function()
        if settled then return end
        finish()
        setStatus("Zaman aşımı: sunucu dolu, kapalı ya da jobId yanlış. Tekrar dene.",
            Color3.fromRGB(230, 170, 60))
    end)

    -- 1) klasik yöntem (mobilde daha güvenilir)
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
    end)

    -- 2) hata verdiyse TeleportAsync
    if not ok and not settled then
        local ok2, err2 = pcall(function()
            local opts = Instance.new("TeleportOptions")
            opts.ServerInstanceId = jobId
            TeleportService:TeleportAsync(placeId, {player}, opts)
        end)
        if not ok2 and not settled then
            finish()
            setStatus("Teleport hatası: "..tostring(err2 or err), Color3.fromRGB(230, 90, 90))
        end
    end
end

joinBtn.MouseButton1Click:Connect(doJoin)
box.FocusLost:Connect(function(enter) if enter then doJoin() end end)

setStatus("Hazır. Job ID gir ve JOIN'e bas.")
