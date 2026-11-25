--=============================================================
--  Server Joiner v3  |  Mobile panel + server list + checks
--=============================================================
local Players          = game:GetService("Players")
local TeleportService  = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local player           = Players.LocalPlayer

pcall(function() if _G.__JOINER_GUI then _G.__JOINER_GUI:Destroy() end end)

local RED   = Color3.fromRGB(235, 90, 90)
local GREEN = Color3.fromRGB(120, 205, 130)
local BLUE  = Color3.fromRGB(120, 190, 255)
local ORNG  = Color3.fromRGB(235, 175, 70)
local GREY  = Color3.fromRGB(150, 150, 165)

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
            dragging  = true; dragStart = input.Position; startPos = frame.Position
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
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                       startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local UUID = "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x"

local function parseInput(raw)
    raw = (raw or ""):gsub("%s+", "")
    local placeFromUrl = raw:match("roblox%.com/games/(%d+)")
    local jobFromUrl   = raw:match("[?&]jobId=([%w%-_]+)")
    local jobId = jobFromUrl or raw:match(UUID) or raw:match("([%w%-_]+)$") or ""
    return jobId, placeFromUrl
end

local function validJob(id) return #id >= 20 and id:match("^[%w%-_]+$") ~= nil end

local function httpGet(url)
    local req = (syn and syn.request) or (http and http.request)
        or http_request or request
    if not req then return nil end
    local ok, res = pcall(req, {Url = url, Method = "GET"})
    if ok and res and res.Body then return res.Body end
end

--================= UI =================
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
toggle.TextColor3 = BLUE
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 24
toggle.BorderSizePixel = 0
toggle.Parent = screen
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 16)
local tS = Instance.new("UIStroke", toggle); tS.Color = Color3.fromRGB(70,130,180); tS.Thickness = 2

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 320, 0, 366)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screen
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
local pS = Instance.new("UIStroke", panel); pS.Color = Color3.fromRGB(60,60,76); pS.Thickness = 1

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
joinBtn.Size = UDim2.new(1, -28, 0, 44)
joinBtn.Position = UDim2.new(0, 14, 0, 100)
joinBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 90)
joinBtn.Text = "JOIN"
joinBtn.Font = Enum.Font.GothamBold
joinBtn.TextSize = 15
joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
joinBtn.BorderSizePixel = 0
joinBtn.Parent = panel
Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 10)

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(0, 150, 0, 32)
scanBtn.Position = UDim2.new(0, 14, 0, 152)
scanBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
scanBtn.Text = "JobId'yi doğrula"
scanBtn.Font = Enum.Font.GothamMedium
scanBtn.TextSize = 12
scanBtn.TextColor3 = Color3.fromRGB(200, 200, 215)
scanBtn.BorderSizePixel = 0
scanBtn.Parent = panel
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 9)

local listBtn = Instance.new("TextButton")
listBtn.Size = UDim2.new(0, 128, 0, 32)
listBtn.Position = UDim2.new(1, -142, 0, 152)
listBtn.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
listBtn.Text = "Sunucuları listele"
listBtn.Font = Enum.Font.GothamMedium
listBtn.TextSize = 12
listBtn.TextColor3 = Color3.fromRGB(170, 200, 240)
listBtn.BorderSizePixel = 0
listBtn.Parent = panel
Instance.new("UICorner", listBtn).CornerRadius = UDim.new(0, 9)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -28, 0, 46)
status.Position = UDim2.new(0, 14, 0, 190)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.TextColor3 = GREY
status.Text = "Hazır."
status.TextWrapped = true
status.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -28, 0, 98)
list.Position = UDim2.new(0, 14, 0, 244)
list.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.Visible = false
list.Parent = panel
Instance.new("UICorner", list).CornerRadius = UDim.new(0, 10)
Instance.new("UIPadding", list).PaddingTop = UDim.new(0, 6)
Instance.new("UIListLayout", list).Padding = UDim.new(0, 5)

local function setStatus(msg, color)
    status.Text = msg
    status.TextColor3 = color or GREY
end

local open = false
local function setOpen(st)
    open = st
    if open then
        panel.Visible = true
        panel.Size = UDim2.new(0, 280, 0, 366)
        TweenService:Create(panel, TweenInfo.new(0.18), {Size = UDim2.new(0, 320, 0, 366)}):Play()
    else
        local t = TweenService:Create(panel, TweenInfo.new(0.12), {Size = UDim2.new(0, 280, 0, 366)})
        t:Play(); t.Completed:Connect(function() panel.Visible = false end)
    end
end

toggle.MouseButton1Click:Connect(function() setOpen(not open) end)
closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then setOpen(not open) end
end)

pasteBtn.MouseButton1Click:Connect(function()
    local ok, clip = pcall(function() return getclipboard() end)
    if ok and type(clip) == "string" and clip ~= "" then
        box.Text = clip:gsub("%s+", "")
        setStatus("Panodan alındı.", GREEN)
    else
        setStatus("Pano okunamadı.", ORNG)
    end
end)

--================= teleport =================
local busy = false

local FAIL = {
    ServerFull = "Sunucu dolu.", GameFull = "Oyun dolu.",
    SameServer = "Zaten o sunucudasın.", Restricted = "Erişim kısıtlı.",
    Unauthorized = "Teleport yetkisi yok.", TeleportFailed = "Roblox reddetti.",
    HTTPError = "Bağlantı hatası.",
}

local function joinServer(jobId, placeId)
    if busy then return end
    busy = true

    if jobId == game.JobId then
        busy = false
        setStatus("Zaten bu sunucudasın.", ORNG)
        return
    end

    setStatus("İstek gönderiliyor...", BLUE)

    local settled = false
    local conn

    local function done() busy = false end
    local function fail(reason, extra)
        settled = true
        if conn then pcall(function() conn:Disconnect() end) end
        done()
        local msg = FAIL[tostring(reason)] or ("Hata: " .. tostring(reason))
        if extra and extra ~= "" then msg = msg .. " (" .. tostring(extra) .. ")" end
        setStatus(msg, RED)
    end

    conn = TeleportService.TeleportInitFailed:Connect(function(plr, result, msg)
        if plr ~= player or settled then return end
        fail(result, msg)
    end)

    -- hata gelmezse 6s sonra ikinci API'yi dene (sessiz executor'larda işe yarar)
    task.delay(6, function()
        if settled then return end
        local okB = pcall(function()
            TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
        end)
        if not okB then return end
    end)

    -- 1. deneme: TeleportAsync
    local usedAsync = pcall(function()
        if not TeleportService.TeleportAsync then error("no async") end
        local o = Instance.new("TeleportOptions")
        o.ServerInstanceId = jobId
        TeleportService:TeleportAsync(placeId, {player}, o)
    end)

    if not usedAsync then
        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
        end)
        if not ok then
            settled = true
            if conn then conn:Disconnect() end
            done()
            setStatus("Çağrı başarısız: " .. tostring(err), RED)
            return
        end
    end

    setStatus("İstek gönderildi. Yanıt bekleniyor...", BLUE)
end

local function currentTarget()
    local jobId, place = parseInput(box.Text)
    if not validJob(jobId) then
        setStatus("Geçersiz Job ID (uzunluk: " .. #jobId .. ", 36 olmalı).", RED)
        return nil
    end
    local placeId = place and tonumber(place) or game.PlaceId
    if placeId ~= game.PlaceId then
        setStatus("UYARI: JobId başka oyuna ait (" .. placeId .. "). Yine de deniyorum...", ORNG)
        task.wait(0.9)
    end
    return jobId, placeId
end

--================= sunucu listesi / doğrulama =================
local function clearList()
    for _, c in ipairs(list:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
end

local function addRow(text, jobId, placeId)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, -12, 0, 32)
    row.BackgroundColor3 = Color3.fromRGB(44, 48, 62)
    row.Text = "  " .. text
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.Font = Enum.Font.Code
    row.TextSize = 11
    row.TextColor3 = Color3.fromRGB(215, 225, 240)
    row.BorderSizePixel = 0
    row.Parent = list
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    row.MouseButton1Click:Connect(function()
        joinServer(jobId, placeId)
    end)
end

local function fetchServers(placeId, wantedId)
    local body = httpGet(("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&sortOrder=Desc"):format(placeId))
    if not body then
        setStatus("HTTP yok: executor 'request' desteklemiyor. Yine de JOIN deneyebilirsin.", ORNG)
        return
    end
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or not data or not data.data then
        setStatus("Liste alınamadı (oyun gizli olabilir).", ORNG)
        return
    end

    clearList()
    local servers = data.data
    local found = false

    for _, s in ipairs(servers) do
        if wantedId and s.id == wantedId then found = true end
    end

    if wantedId then
        if found then
            setStatus("✔ JobId listede VAR. Sunucuya dokunup gir.", GREEN)
        else
            setStatus("✘ JobId listede YOK -> private, eski ya da yanlış kopyalanmış.", RED)
        end
    else
        setStatus(#servers .. " açık sunucu bulundu. Dokun -> gir.", GREEN)
    end

    if #servers == 0 then
        setStatus("Açık sunucu yok. Oyun başlatmıyor olabilir.", ORNG)
        return
    end

    for _, s in ipairs(servers) do
        local ping = s.ping and (tostring(s.ping) .. "ms") or "-"
        addRow(("%s/%s  %s  %s"):format(s.playing, s.maxPlayers, ping, s.id:sub(1, 8)),
               s.id, placeId)
    end

    list.CanvasSize = UDim2.new(0, 0, 0, #servers * 37 + 8)
    list.Visible = true
end

listBtn.MouseButton1Click:Connect(function()
    setStatus("Sunucu listesi çekiliyor...", BLUE)
    task.spawn(function() fetchServers(game.PlaceId) end)
end)

scanBtn.MouseButton1Click:Connect(function()
    local jobId, placeId = currentTarget()
    if not jobId then return end
    setStatus("Doğrulanıyor...", BLUE)
    task.spawn(function() fetchServers(placeId, jobId) end)
end)

joinBtn.MouseButton1Click:Connect(function()
    local jobId, placeId = currentTarget()
    if not jobId then return end
    joinServer(jobId, placeId)
end)
box.FocusLost:Connect(function(e)
    if not e then return end
    local jobId, placeId = currentTarget()
    if jobId then joinServer(jobId, placeId) end
end)

setStatus("Mevcut sunucu: " .. game.JobId:sub(1, 8) .. "\nJob ID gir, JOIN'e bas.", GREY)
