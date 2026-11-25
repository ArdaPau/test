--=============================================================
--  KASH MULTI  |  MIDNIGHT CRIMSON  |  MM2 EDITION
--  Luau ScreenGui (LocalScript / Executor)
--=============================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local HttpService        = game:GetService("HttpService")
local Workspace          = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end

--=============================================================
--  RENKLER (Midnight Crimson)
--=============================================================
local C = {
    window    = Color3.fromRGB(13, 13, 16),
    sidebar   = Color3.fromRGB(8, 8, 10),
    card      = Color3.fromRGB(20, 20, 24),
    dark      = Color3.fromRGB(23, 23, 23),
    darker    = Color3.fromRGB(11, 11, 14),
    red       = Color3.fromRGB(239, 68, 68),
    redDim    = Color3.fromRGB(127, 29, 29),
    redSoft   = Color3.fromRGB(60, 20, 22),
    text      = Color3.fromRGB(245, 245, 245),
    textDim   = Color3.fromRGB(163, 163, 163),
    textFaint = Color3.fromRGB(115, 115, 115),
    white     = Color3.fromRGB(255, 255, 255),
    border    = Color3.fromRGB(40, 40, 44),
    knobOff   = Color3.fromRGB(64, 64, 64),
}

--=============================================================
--  YARDIMCI FONKSİYONLAR
--=============================================================
local function new(class, props)
    local inst = Instance.new(class)
    if props then
        local parent = props.Parent
        props.Parent = nil
        for k, v in pairs(props) do inst[k] = v end
        inst.Parent = parent
    end
    return inst
end

local function corner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = inst
    return c
end

local function stroke(inst, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or C.border
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

local function padding(inst, l, r, t, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = inst
    return p
end

local function makeText(parent, props)
    props = props or {}
    props.BackgroundTransparency = props.BackgroundTransparency or 1
    props.BorderSizePixel = 0
    props.Font = props.Font or Enum.Font.Gotham
    props.TextColor3 = props.TextColor3 or C.text
    props.TextSize = props.TextSize or 12
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    props.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
    props.Text = props.Text or ""
    props.Parent = parent
    return new("TextLabel", props)
end

--=============================================================
--  ÇEVİRİLER
--=============================================================
local UITEXT = {
    en = {
        searchPlaceholder = "Search...",
        activeSuffix = "Active",
        reset = "Reset",
        noMatch = "No modules match your search.",
        themeActive = "Midnight Crimson theme active",
        resetDone = "All settings reset to default",
        on = "Enabled",
        off = "Disabled",
        stateOn = "On",
        stateOff = "Off",
        pressKey = "Press a key for",
        keyAssigned = "keybound to",
        executed = "executed",
        stopped = "✓ Stopped",
        selectPlayerFirst = "Select a player from Choose player first",
        autoFlung = "selected and auto-flung!",
        reflung = "flung again!",
        choosePlayer = "Choose player",
        langChanged = "Language switched to English",
        flingNow = "Fling",
        play = "Play",
        save = "Save",
    },
    tr = {
        searchPlaceholder = "Modül ara...",
        activeSuffix = "Aktif",
        reset = "Sıfırla",
        noMatch = "Aramanızla eşleşen modül bulunamadı.",
        themeActive = "Midnight Crimson teması aktif",
        resetDone = "Tüm ayarlar varsayılana sıfırlandı",
        on = "Açıldı",
        off = "Kapatıldı",
        stateOn = "Açık",
        stateOff = "Kapalı",
        pressKey = "Tuşa basın:",
        keyAssigned = "tuşu atandı:",
        executed = "çalıştırıldı",
        stopped = "✓ Durduruldu",
        selectPlayerFirst = "Önce Choose player ile bir oyuncu seçin",
        autoFlung = "seçildi ve otomatik flinglendi!",
        reflung = "tekrar flinglendi!",
        choosePlayer = "Choose player",
        langChanged = "Dil Türkçe olarak değiştirildi",
        flingNow = "Fling",
        play = "Oynat",
        save = "Kaydet",
    },
}

local currentLang = "en"
local function t(val)
    if type(val) == "table" then return val[currentLang] or val.en or "" end
    return val or ""
end

--=============================================================
--  DURUM / FLAG'LER
--=============================================================
local function defaultFlags()
    return {
        vision     = true,
        touchFling = true,
        antiFling  = true,
        walkFling  = false,
        orbit      = false,
        tbag       = false,
        farmBag    = false,
        farm       = false,
        xpKillAll  = false,
        xpHide     = false,
        xpShoot    = true,
        autoGun    = true,
    }
end

local flags = defaultFlags()
local state = { selectedPlayer = nil }
local searchQuery = ""
local currentTab = "Vision"

--=============================================================
--  SEKME VERİSİ
--=============================================================
local function defaultTabs()
    return {
        {
            id = "Vision",
            icon = "👁",
            badge = { en = "ESP & Visuals", tr = "ESP & Görüş" },
            items = {
                {
                    type = "toggle", id = "vision_outlines", feature = "vision",
                    label = { en = "Player outlines", tr = "Player outlines" },
                    desc = {
                        en = "Through walls • Murderer: Red, Sheriff: Blue, Innocent: Green, None: Gray",
                        tr = "Duvar arkası • Katil: Kırmızı, Şerif: Mavi, Masum: Yeşil, Rolsüz: Gri",
                    },
                    active = true,
                },
                {
                    type = "keybind_button", id = "vision_toggle", feature = "vision",
                    label = { en = "Toggle Vision", tr = "Vision aç/kapat" },
                    btn = { en = "Vision", tr = "Vision" },
                    key = "V", active = true,
                },
            },
        },
        {
            id = "Fling",
            icon = "⚡",
            badge = { en = "Physics & Fling", tr = "Fizik & Fling" },
            items = {
                {
                    type = "toggle", id = "fling_touch", feature = "touchFling",
                    label = { en = "Touch Fling", tr = "Touch Fling" },
                    desc = { en = "Fling players on contact", tr = "Temas eden oyuncuyu fırlat" },
                    active = true,
                },
                {
                    type = "toggle", id = "fling_shield", feature = "antiFling",
                    label = { en = "Anti-Fling Shield", tr = "Anti-Fling Shield" },
                    desc = { en = "Block incoming fling attacks", tr = "Gelen fling saldırısını kes" },
                    active = true,
                },
                {
                    type = "toggle", id = "fling_walk", feature = "walkFling",
                    label = { en = "Walk Fling", tr = "Walk Fling" },
                    desc = { en = "Passive collision while walking", tr = "Yürürken pasif çarpışma" },
                    active = false,
                },
                {
                    type = "keybind", id = "fling_keybind",
                    label = { en = "Fling Keybind", tr = "Fling Tuşu" },
                    key = "F",
                },
                {
                    type = "player_fling", id = "fling_player",
                    label = { en = "Choose player", tr = "Choose player" },
                    selectedPlayer = nil, dropdownOpen = false,
                },
            },
        },
        {
            id = "Emotes",
            icon = "🙂",
            badge = { en = "Animations", tr = "Animasyon" },
            items = {
                {
                    type = "toggle", id = "emote_orbit", feature = "orbit",
                    label = { en = "Orbit player", tr = "Orbit player" },
                    desc = { en = "Turns around a player like an orbit", tr = "Oyuncunun etrafında yörünge gibi döner" },
                    active = false,
                },
                {
                    type = "toggle", id = "emote_tbag", feature = "tbag",
                    label = { en = "Tbag player", tr = "Tbag player" },
                    desc = { en = "Teleports behind the player and wiggles", tr = "Oyuncunun arkasına ışınlanıp hareket eder" },
                    active = false,
                },
                {
                    type = "action", id = "emote_zen",
                    label = { en = "Zen", tr = "Zen" },
                    btn = { en = "Play", tr = "Oynat" },
                },
                {
                    type = "action", id = "emote_floss",
                    label = { en = "Floss", tr = "Floss" },
                    btn = { en = "Play", tr = "Oynat" },
                },
                {
                    type = "keybind_button", id = "emote_stop",
                    label = { en = "Stop Emote", tr = "Emote Durdur" },
                    btn = { en = "Stop Emote", tr = "Emote Durdur" },
                    key = "X",
                },
            },
        },
        {
            id = "Farm",
            icon = "💰",
            badge = { en = "Auto Farm", tr = "Otomatik Kas" },
            items = {
                {
                    type = "select", id = "farm_style",
                    label = { en = "Farmstyle", tr = "Farmstyle" },
                    options = {
                        { id = "fly", en = "Fly", tr = "Fly" },
                        { id = "teleport", en = "Teleport", tr = "Teleport" },
                    },
                    selected = "fly",
                },
                {
                    type = "toggle", id = "farm_bag", feature = "farmBag",
                    label = { en = "Fling murderer when full bag", tr = "Fling murderer when full bag" },
                    desc = { en = "Auto-fling murderer once bag is full", tr = "Çanta dolunca katili fırlat" },
                    active = false,
                },
                {
                    type = "toggle", id = "farm_toggle", feature = "farm",
                    label = { en = "Toggle Farm on / off", tr = "Toggle Farm on / off" },
                    desc = { en = "Start or stop auto farming", tr = "Otomatik farmı başlat/durdur" },
                    active = false,
                },
                {
                    type = "section", id = "sec_xp",
                    label = { en = "XP Farm", tr = "XP Farm" },
                },
                {
                    type = "toggle", id = "xp_killall", feature = "xpKillAll",
                    label = { en = "Auto Kill all when Murderer", tr = "Auto Kill all when Murderer" },
                    desc = { en = "Eliminate all players as Murderer", tr = "Katil olunca herkesi öldür" },
                    active = false,
                },
                {
                    type = "toggle", id = "xp_hide", feature = "xpHide",
                    label = { en = "Auto hide underground when innocent", tr = "Auto hide underground when innocent" },
                    desc = { en = "Stay safely underground as Innocent", tr = "Masumken yer altına saklan" },
                    active = false,
                },
                {
                    type = "toggle", id = "xp_shoot", feature = "xpShoot",
                    label = { en = "Auto shoot murderer", tr = "Auto shoot murderer" },
                    desc = { en = "Automatically shoot murderer as Sheriff", tr = "Şerifken katili otomatik vur" },
                    active = true,
                },
            },
        },
        {
            id = "Automation",
            icon = "⚙",
            badge = { en = "System", tr = "Sistem" },
            items = {
                {
                    type = "toggle", id = "auto_gun", feature = "autoGun",
                    label = { en = "Auto grab gun", tr = "Auto grab gun" },
                    desc = { en = "Automatically pick up dropped gun", tr = "Düşen silahı otomatik al" },
                    active = true,
                },
                {
                    type = "action", id = "save_config",
                    label = { en = "Save Config", tr = "Config Kaydet" },
                    btn = { en = "Save", tr = "Kaydet" },
                },
            },
        },
    }
end

local tabs = defaultTabs()

--=============================================================
--  MM2 YARDIMCILARI
--=============================================================
local function getHRP(plr)
    plr = plr or LocalPlayer
    local char = plr.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHum(plr)
    plr = plr or LocalPlayer
    local char = plr.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function hasItem(plr, itemName)
    local char = plr.Character
    if char and char:FindFirstChild(itemName) then return true end
    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp and bp:FindFirstChild(itemName) then return true end
    return false
end

local ROLE_COLORS = {
    Murderer = Color3.fromRGB(239, 68, 68),
    Sheriff  = Color3.fromRGB(59, 130, 246),
    Innocent = Color3.fromRGB(34, 197, 94),
    None     = Color3.fromRGB(115, 115, 115),
}

local roundActive = false

local function refreshRoundState()
    roundActive = false
    for _, plr in ipairs(Players:GetPlayers()) do
        if hasItem(plr, "Knife") or hasItem(plr, "Gun") then
            roundActive = true
            break
        end
    end
end

local function getRole(plr)
    if not plr then return "None" end

    local attr = plr:GetAttribute("Role")
    if type(attr) == "string" and ROLE_COLORS[attr] then return attr end

    local roles = ReplicatedStorage:FindFirstChild("Roles")
    if roles then
        local v = roles:FindFirstChild(plr.Name)
        if v and v:IsA("ValueBase") and type(v.Value) == "string" and ROLE_COLORS[v.Value] then
            return v.Value
        end
    end

    if hasItem(plr, "Knife") then return "Murderer" end
    if hasItem(plr, "Gun")   then return "Sheriff"  end
    if roundActive and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        return "Innocent"
    end
    return "None"
end

local function getTargetPlayer(nearestFallback)
    local p = state.selectedPlayer
    if p and p.Parent and p.Character then return p end
    if not nearestFallback then return nil end
    local hrp = getHRP()
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local thrp = getHRP(plr)
            if thrp then
                local d = (thrp.Position - hrp.Position).Magnitude
                if d < bestDist then best, bestDist = plr, d end
            end
        end
    end
    return best
end

--=============================================================
--  FLING (MM2 UYUMLU)
--=============================================================
local flingBusy = false
local flingDebounce = {}

local function flingPlayer(target)
    if not target or target == LocalPlayer then return end
    if flingBusy then return end
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local thrp = getHRP(target)
    if not (hrp and thrp) then return end

    flingBusy = true

    local savedCF = hrp.CFrame
    local collideStates = {}
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then
            collideStates[d] = d.CanCollide
            d.CanCollide = false -- noclip
        end
    end

    pcall(function()
        -- Hedefin HRP'sinin içine ışınlan
        hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, 0)

        -- Yüksek hızlı dönüş (fling'in kalbi)
        local bav = Instance.new("BodyAngularVelocity")
        bav.AngularVelocity = Vector3.new(0, 50000, 0)
        bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bav.Parent = hrp

        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Parent = hrp

        task.wait(0.12)
        bav:Destroy()
        bv:Destroy()
    end)

    -- Eski konuma dön + hızları sıfırla (kendini haritadan atmaz)
    if hrp and hrp.Parent then
        hrp.AssemblyAngularVelocity = Vector3.new()
        hrp.AssemblyLinearVelocity = Vector3.new()
        hrp.CFrame = savedCF
    end

    for part, state_ in pairs(collideStates) do
        if part.Parent then part.CanCollide = state_ end
    end

    task.wait(0.05)
    flingBusy = false
end

local function tryFling(target)
    if not target or target == LocalPlayer then return end
    local last = flingDebounce[target]
    if last and (os.clock() - last) < 1 then return end
    flingDebounce[target] = os.clock()
    task.spawn(flingPlayer, target)
end

--=============================================================
--  VISION (Highlight / Outline)
--=============================================================
local hlFolder = Instance.new("Folder")
hlFolder.Name = "KashMulti_Highlights"
hlFolder.Parent = Workspace

local hlCache = {}

local function clearHighlights()
    for plr, hl in pairs(hlCache) do
        if hl and hl.Parent then hl:Destroy() end
        hlCache[plr] = nil
    end
end

local function updateHighlights()
    refreshRoundState()
    for plr, hl in pairs(hlCache) do
        if not plr.Parent or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
            if hl and hl.Parent then hl:Destroy() end
            hlCache[plr] = nil
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hl = hlCache[plr]
                if not hl or not hl.Parent then
                    hl = Instance.new("Highlight")
                    hl.Name = "KashMultiVision"
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.FillTransparency = 1
                    hl.OutlineTransparency = 0
                    hl.Adornee = char
                    hl.Parent = hlFolder
                    hlCache[plr] = hl
                end
                hl.Adornee = char
                hl.OutlineColor = ROLE_COLORS[getRole(plr)] or ROLE_COLORS.None
            end
        end
    end
end

--=============================================================
--  EMOTELAR / ORBIT / TBAG
--=============================================================
local EMOTES = {
    Zen   = "rbxassetid://5211750376",
    Floss = "rbxassetid://5915779726",
}

local emoteTrack = nil

local function playEmote(name)
    local hum = getHum()
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end
    local anim = Instance.new("Animation")
    anim.AnimationId = EMOTES[name] or name
    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    if ok and track then
        if emoteTrack then pcall(function() emoteTrack:Stop() end) end
        emoteTrack = track
        pcall(function() track:Play() end)
    end
end

local function stopEmotes()
    if emoteTrack then
        pcall(function() emoteTrack:Stop() end)
        emoteTrack = nil
    end
    flags.orbit = false
    flags.tbag = false
    for _, tab in ipairs(tabs) do
        for _, item in ipairs(tab.items) do
            if item.feature == "orbit" or item.feature == "tbag" then item.active = false end
        end
    end
end

--=============================================================
--  FARM / XP YARDIMCILARI
--=============================================================
local function findNearestCoin()
    local hrp = getHRP()
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and string.find(string.lower(obj.Name), "coin", 1, true) then
            local d = (obj.Position - hrp.Position).Magnitude
            if d < bestDist then best, bestDist = obj, d end
        end
    end
    return best
end

local function touchFire(part)
    if firetouchinterest and part then
        local hrp = getHRP()
        if hrp then
            pcall(firetouchinterest, hrp, part, 0)
            pcall(firetouchinterest, hrp, part, 1)
        end
    end
end

local function getCoinCount()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            if v:IsA("ValueBase") and type(v.Value) == "number" then
                return v.Value
            end
        end
    end
    return 0
end

local FULL_BAG = 25

local function findMurderer()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and getRole(plr) == "Murderer" then return plr end
    end
    return nil
end

local function equipTool(name)
    local char = LocalPlayer.Character
    if not char then return nil end
    local tool = char:FindFirstChild(name)
    if not tool then
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then
            tool = bp:FindFirstChild(name)
            if tool then
                local hum = getHum()
                if hum then pcall(function() hum:EquipTool(tool) end) end
            end
        end
    end
    return tool
end

local function activateTool(tool)
    if tool and tool:IsA("Tool") then
        pcall(function() tool:Activate() end)
    end
end

--=============================================================
--  UI İNŞASI
--=============================================================
local ui = {}
local function setStatus(msg)
    if ui.statusLabel then ui.statusLabel.Text = msg or "" end
end

local WINDOW_W, WINDOW_H = 660, 404
local SIDEBAR_W = 176

local guiParent
local okGui = pcall(function()
    guiParent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not okGui or not guiParent then
    guiParent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Eski sürümü temizle
pcall(function()
    local old = guiParent:FindFirstChild("KashMulti")
    if old then old:Destroy() end
end)

local screenGui = new("ScreenGui", {
    Name = "KashMulti",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
    Parent = guiParent,
})
ui.screenGui = screenGui

-- Ana pencere
local window = new("Frame", {
    Size = UDim2.fromOffset(WINDOW_W, WINDOW_H),
    Position = UDim2.new(0.5, -WINDOW_W / 2, 0.5, -WINDOW_H / 2),
    BackgroundColor3 = C.window,
    BorderSizePixel = 0,
    Parent = screenGui,
})
corner(window, 10)
stroke(window, C.red, 1, 0.7)
ui.window = window

-- Stage (arka plan parlaması, pencereyle birlikte hareket eder)
local stage = new("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    ZIndex = 0,
    Parent = window,
})

local glowTop = new("Frame", {
    Size = UDim2.fromOffset(190, 190),
    Position = UDim2.fromOffset(-60, -60),
    BackgroundColor3 = C.red,
    BackgroundTransparency = 0.9,
    ZIndex = 0,
    Parent = stage,
})
corner(glowTop, 95)

local glowBottom = new("Frame", {
    Size = UDim2.fromOffset(210, 210),
    Position = UDim2.new(1, -150, 1, -150),
    BackgroundColor3 = C.redDim,
    BackgroundTransparency = 0.85,
    ZIndex = 0,
    Parent = stage,
})
corner(glowBottom, 105)

-- Mobil / LDPlayer için sürüklenebilir KM aç/kapa butonu
local floatBtn = new("TextButton", {
    Size = UDim2.fromOffset(40, 40),
    Position = UDim2.new(0, 16, 0.5, -20),
    BackgroundColor3 = C.sidebar,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Text = "KM",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = C.red,
    Parent = screenGui,
})
corner(floatBtn, 10)
stroke(floatBtn, C.red, 1.5, 0.35)

do
    local fDrag, fStart, fPos, moved = false, nil, nil, false
    floatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            fDrag = true
            moved = false
            fStart = input.Position
            fPos = floatBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    fDrag = false
                    if not moved then
                        window.Visible = not window.Visible
                    end
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if fDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - fStart
            if delta.Magnitude > 5 then moved = true end
            floatBtn.Position = UDim2.new(fPos.X.Scale, fPos.X.Offset + delta.X, fPos.Y.Scale, fPos.Y.Offset + delta.Y)
        end
    end)
end

--=============================================================
--  SOL SIDEBAR
--=============================================================
local sidebar = new("Frame", {
    Size = UDim2.new(0, SIDEBAR_W, 1, 0),
    BackgroundColor3 = C.sidebar,
    BorderSizePixel = 0,
    Parent = window,
})
corner(sidebar, 10)
-- sağ kenar köşelerini düzeltmek için maske
local sidebarMask = new("Frame", {
    Size = UDim2.new(0, SIDEBAR_W, 1, 0),
    BackgroundTransparency = 1,
    Parent = window,
})

local sideLine = new("Frame", {
    Size = UDim2.new(0, 1, 1, -20),
    Position = UDim2.new(0, SIDEBAR_W - 1, 0, 10),
    BackgroundColor3 = C.red,
    BackgroundTransparency = 0.85,
    BorderSizePixel = 0,
    Parent = window,
})

-- Marka
local brand = new("Frame", {
    Size = UDim2.new(1, -20, 0, 40),
    Position = UDim2.fromOffset(10, 8),
    BackgroundTransparency = 1,
    Parent = sidebar,
})
ui.brand = brand

local brandIcon = new("Frame", {
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.new(0, 4, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundColor3 = C.red,
    BackgroundTransparency = 0.8,
    Parent = brand,
})
corner(brandIcon, 8)
stroke(brandIcon, C.red, 1, 0.6)
makeText(brandIcon, {
    Size = UDim2.fromScale(1, 1),
    Text = "⚡",
    TextSize = 14,
    TextColor3 = C.red,
    TextXAlignment = Enum.TextXAlignment.Center,
})

makeText(brand, {
    Position = UDim2.fromOffset(40, 0),
    Size = UDim2.new(1, -40, 0, 17),
    Text = "Kash Multi",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = C.white,
})

makeText(brand, {
    Position = UDim2.fromOffset(40, 18),
    Size = UDim2.new(1, -40, 0, 14),
    Text = "v2.4 Crimson",
    Font = Enum.Font.Code,
    TextSize = 10,
    TextColor3 = C.red,
})

local brandLine = new("Frame", {
    Size = UDim2.new(1, -8, 0, 1),
    Position = UDim2.fromOffset(4, 50),
    BackgroundColor3 = C.red,
    BackgroundTransparency = 0.85,
    BorderSizePixel = 0,
    Parent = sidebar,
})

-- Sekme listesi
local tabList = new("Frame", {
    Size = UDim2.new(1, -20, 1, -160),
    Position = UDim2.fromOffset(10, 58),
    BackgroundTransparency = 1,
    Parent = sidebar,
})
ui.tabList = tabList
new("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = tabList,
})

-- Footer
local footer = new("Frame", {
    Size = UDim2.new(1, -20, 0, 78),
    Position = UDim2.new(0, 10, 1, -10),
    AnchorPoint = Vector2.new(0, 1),
    BackgroundTransparency = 1,
    Parent = sidebar,
})
ui.footer = footer

local footerLine = new("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = C.red,
    BackgroundTransparency = 0.85,
    BorderSizePixel = 0,
    Parent = footer,
})

local langRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 26),
    Position = UDim2.fromOffset(0, 10),
    BackgroundTransparency = 1,
    Parent = footer,
})
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = langRow,
})

local function makeLangButton(lang, label, order)
    local btn = new("TextButton", {
        Size = UDim2.new(0.5, -2, 1, 0),
        LayoutOrder = order,
        BackgroundColor3 = C.dark,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = langRow,
    })
    corner(btn, 6)
    local st = stroke(btn, C.border, 1, 0)
    local txt = makeText(btn, {
        Size = UDim2.fromScale(1, 1),
        Text = label,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = C.textDim,
    })
    btn.MouseButton1Click:Connect(function()
        currentLang = lang
        updateChrome()
        updateActiveCount()
        renderTabs()
        renderContent()
        setStatus(UITEXT[currentLang].langChanged)
    end)
    return btn, st, txt
end

local langButtons = {}
do
    local b1, s1, t1 = makeLangButton("en", "English", 1)
    local b2, s2, t2 = makeLangButton("tr", "Türkçe", 2)
    langButtons.en = { btn = b1, stroke = s1, text = t1 }
    langButtons.tr = { btn = b2, stroke = s2, text = t2 }
end

local activeRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 18),
    Position = UDim2.fromOffset(0, 44),
    BackgroundTransparency = 1,
    Parent = footer,
})

local dot = new("Frame", {
    Size = UDim2.fromOffset(7, 7),
    Position = UDim2.new(0, 8, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundColor3 = C.red,
    BorderSizePixel = 0,
    Parent = activeRow,
})
corner(dot, 4)

ui.activeCount = makeText(activeRow, {
    Position = UDim2.fromOffset(22, 0),
    Size = UDim2.new(1, -22, 1, 0),
    Text = "0 Active",
    TextSize = 10,
    TextColor3 = C.textDim,
})

makeText(activeRow, {
    Size = UDim2.new(0, 60, 1, 0),
    Position = UDim2.new(1, -60, 0, 0),
    Text = "RShift",
    Font = Enum.Font.Code,
    TextSize = 10,
    TextColor3 = C.textFaint,
    TextXAlignment = Enum.TextXAlignment.Right,
})

--=============================================================
--  SAĞ PANEL (MAIN)
--=============================================================
local main = new("Frame", {
    Size = UDim2.new(1, -SIDEBAR_W, 1, 0),
    Position = UDim2.fromOffset(SIDEBAR_W, 0),
    BackgroundTransparency = 1,
    Parent = window,
})

-- Header
local header = new("Frame", {
    Size = UDim2.new(1, -28, 0, 32),
    Position = UDim2.fromOffset(14, 10),
    BackgroundTransparency = 1,
    Parent = main,
})

local headerLeft = new("Frame", {
    Size = UDim2.new(0, 260, 1, 0),
    BackgroundTransparency = 1,
    Parent = header,
})
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = headerLeft,
})

ui.title = makeText(headerLeft, {
    Size = UDim2.new(0, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.X,
    LayoutOrder = 1,
    Text = "Vision",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = C.white,
})

ui.badge = makeText(headerLeft, {
    Size = UDim2.new(0, 0, 0, 18),
    AutomaticSize = Enum.AutomaticSize.X,
    LayoutOrder = 2,
    Text = "ESP & Visuals",
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(252, 165, 165),
    BackgroundTransparency = 0.85,
    BackgroundColor3 = C.red,
    TextXAlignment = Enum.TextXAlignment.Center,
})
corner(ui.badge, 9)
stroke(ui.badge, C.red, 1, 0.75)
padding(ui.badge, 8, 8, 0, 0)

-- Search
local searchWrap = new("Frame", {
    Size = UDim2.fromOffset(150, 26),
    Position = UDim2.new(1, 0, 0.5, 0),
    AnchorPoint = Vector2.new(1, 0.5),
    BackgroundColor3 = C.dark,
    BorderSizePixel = 0,
    Parent = header,
})
corner(searchWrap, 6)
stroke(searchWrap, C.red, 1, 0.8)

makeText(searchWrap, {
    Position = UDim2.fromOffset(8, 0),
    Size = UDim2.fromOffset(16, 26),
    Text = "🔍",
    TextSize = 11,
    TextColor3 = C.textFaint,
})

local searchBox = new("TextBox", {
    Position = UDim2.fromOffset(26, 0),
    Size = UDim2.new(1, -32, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextColor3 = C.text,
    PlaceholderColor3 = C.textFaint,
    PlaceholderText = "Search...",
    Text = "",
    ClearTextOnFocus = false,
    Parent = searchWrap,
})
ui.searchBox = searchBox

local headerLine = new("Frame", {
    Size = UDim2.new(1, -28, 0, 1),
    Position = UDim2.fromOffset(14, 48),
    BackgroundColor3 = C.red,
    BackgroundTransparency = 0.85,
    BorderSizePixel = 0,
    Parent = main,
})

-- İçerik
local contentScroll = new("ScrollingFrame", {
    Position = UDim2.fromOffset(14, 56),
    Size = UDim2.new(1, -28, 1, -96),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.red,
    ScrollBarImageTransparency = 0.55,
    VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
    ClipsDescendants = true,
    Parent = main,
})
ui.contentScroll = contentScroll

new("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = contentScroll,
})

-- Status bar
local statusLine = new("Frame", {
    Size = UDim2.new(1, -28, 0, 1),
    Position = UDim2.new(0, 14, 1, -38),
    BackgroundColor3 = C.red,
    BackgroundTransparency = 0.85,
    BorderSizePixel = 0,
    Parent = main,
})

local statusBar = new("Frame", {
    Size = UDim2.new(1, -28, 0, 24),
    Position = UDim2.new(0, 14, 1, -34),
    BackgroundTransparency = 1,
    Parent = main,
})

ui.statusLabel = makeText(statusBar, {
    Size = UDim2.new(1, -60, 1, 0),
    Text = "Midnight Crimson theme active",
    TextSize = 10,
    TextColor3 = C.textFaint,
    TextTruncate = Enum.TextTruncate.AtEnd,
})

local resetBtn = new("TextButton", {
    Size = UDim2.new(0, 50, 1, 0),
    Position = UDim2.new(1, -50, 0, 0),
    BackgroundTransparency = 1,
    Text = "Reset",
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextColor3 = C.red,
    AutoButtonColor = false,
    Parent = statusBar,
})
ui.resetBtn = resetBtn

--=============================================================
--  RENDER: SEKME LİSTESİ
--=============================================================
local renderTabs, renderContent, updateActiveCount, updateChrome, renderAll

renderTabs = function()
    for _, ch in ipairs(ui.tabList:GetChildren()) do
        if ch:IsA("TextButton") then ch:Destroy() end
    end

    for i, tab in ipairs(tabs) do
        local isActive = (tab.id == currentTab)
        local activeInTab = 0
        for _, item in ipairs(tab.items) do
            if item.active == true and (item.type == "toggle" or item.type == "keybind_button") then
                activeInTab = activeInTab + 1
            end
        end

        local btn = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            LayoutOrder = i,
            BackgroundColor3 = isActive and C.redSoft or C.sidebar,
            BackgroundTransparency = isActive and 0 or 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            Parent = ui.tabList,
        })
        corner(btn, 8)
        if isActive then stroke(btn, C.red, 1, 0.6) end

        makeText(btn, {
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.fromOffset(18, 32),
            Text = tab.icon,
            TextSize = 13,
            TextColor3 = isActive and C.red or C.textDim,
        })

        makeText(btn, {
            Position = UDim2.fromOffset(32, 0),
            Size = UDim2.new(1, -70, 1, 0),
            Text = tab.id,
            Font = isActive and Enum.Font.GothamBold or Enum.Font.GothamMedium,
            TextSize = 11,
            TextColor3 = isActive and C.red or C.textDim,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })

        if activeInTab > 0 then
            local badge = makeText(btn, {
                Size = UDim2.fromOffset(20, 16),
                Position = UDim2.new(1, -26, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                Text = tostring(activeInTab),
                Font = Enum.Font.Code,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextColor3 = isActive and Color3.fromRGB(252, 165, 165) or C.textFaint,
            })
            if isActive then
                badge.BackgroundColor3 = C.red
                badge.BackgroundTransparency = 0.75
                corner(badge, 4)
            end
        end

        btn.MouseButton1Click:Connect(function()
            currentTab = tab.id
            renderTabs()
            renderContent()
        end)
    end
end

--=============================================================
--  RENDER: KARTLAR
--=============================================================
local CARD_H = {
    toggle = 54,
    select = 62,
    keybind = 40,
    keybind_button = 60,
    action = 40,
    section = 22,
}

local function applyHover(card, st)
    card.MouseEnter:Connect(function()
        TweenService:Create(st, TweenInfo.new(0.15), {
            Color = C.red,
            Transparency = 0.55,
        }):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(st, TweenInfo.new(0.15), {
            Color = C.border,
            Transparency = 0,
        }):Play()
    end)
end

local function baseCard(parent, width, height)
    local holder = new("Frame", {
        Size = UDim2.new(width or 1, width and -4 or 0, 0, height),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    local card = new("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.card,
        BorderSizePixel = 0,
        Parent = holder,
    })
    corner(card, 8)
    local st = stroke(card, C.border, 1, 0)
    applyHover(card, st)
    return holder, card
end

local function buildToggle(item, parent, width)
    local holder, card = baseCard(parent, width, CARD_H.toggle)

    makeText(card, {
        Position = UDim2.fromOffset(10, 9),
        Size = UDim2.new(1, -60, 0, 15),
        Text = t(item.label),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = C.text,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    makeText(card, {
        Position = UDim2.fromOffset(10, 27),
        Size = UDim2.new(1, -60, 0, 13),
        Text = t(item.desc or ""),
        TextSize = 9,
        TextColor3 = C.textFaint,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local sw = new("TextButton", {
        Position = UDim2.new(1, -10, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Size = UDim2.fromOffset(36, 20),
        BackgroundColor3 = item.active and C.red or C.knobOff,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = card,
    })
    corner(sw, 10)

    local knob = new("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(0, item.active and 18 or 2, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = C.white,
        BorderSizePixel = 0,
        Parent = sw,
    })
    corner(knob, 8)

    sw.MouseButton1Click:Connect(function()
        item.active = not item.active
        if item.feature then
            flags[item.feature] = item.active
            syncFeature(item.feature, item.active)
            onFlagChanged(item.feature, item.active)
        end
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = UDim2.new(0, item.active and 18 or 2, 0.5, 0),
        }):Play()
        TweenService:Create(sw, TweenInfo.new(0.15), {
            BackgroundColor3 = item.active and C.red or C.knobOff,
        }):Play()

        setStatus(string.format("%s: %s", t(item.label),
            item.active and UITEXT[currentLang].on or UITEXT[currentLang].off))
        updateActiveCount()
        renderTabs()
    end)

    return holder
end

local function buildSelect(item, parent, width)
    local holder, card = baseCard(parent, width, CARD_H.select)

    makeText(card, {
        Position = UDim2.fromOffset(10, 8),
        Size = UDim2.new(1, -20, 0, 15),
        Text = t(item.label),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = C.text,
    })

    local row = new("Frame", {
        Position = UDim2.fromOffset(10, 28),
        Size = UDim2.new(1, -20, 0, 24),
        BackgroundTransparency = 1,
        Parent = card,
    })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 4),
        Parent = row,
    })

    local buttons = {}
    local function paint()
        for id, data in pairs(buttons) do
            local selected = (item.selected == id)
            data.btn.BackgroundColor3 = selected and C.redSoft or C.dark
            data.btn.BackgroundTransparency = selected and 0 or 0
            data.stroke.Color = selected and C.red or C.border
            data.stroke.Transparency = selected and 0.6 or 0
            data.text.TextColor3 = selected and Color3.fromRGB(252, 165, 165) or C.textDim
            data.text.Font = selected and Enum.Font.GothamBold or Enum.Font.GothamMedium
        end
    end

    for i, opt in ipairs(item.options) do
        local b = new("TextButton", {
            Size = UDim2.new(0.5, -2, 1, 0),
            LayoutOrder = i,
            BackgroundColor3 = C.dark,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            Parent = row,
        })
        corner(b, 6)
        local st = stroke(b, C.border, 1, 0)
        local txt = makeText(b, {
            Size = UDim2.fromScale(1, 1),
            Text = t(opt),
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextColor3 = C.textDim,
        })
        buttons[opt.id] = { btn = b, stroke = st, text = txt }
        b.MouseButton1Click:Connect(function()
            item.selected = opt.id
            paint()
            setStatus(string.format("%s: %s", t(item.label), t(opt)))
        end)
    end
    paint()

    return holder
end

local function buildKeybind(item, parent, fullWidth)
    local holder, card = baseCard(parent, fullWidth and 1 or 0.5, CARD_H.keybind)

    makeText(card, {
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Text = t(item.label),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = C.text,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local keyBtn = new("TextButton", {
        Size = UDim2.fromOffset(34, 18),
        Position = UDim2.new(1, -10, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = C.dark,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "[" .. tostring(item.key) .. "]",
        Font = Enum.Font.Code,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(252, 165, 165),
        Parent = card,
    })
    corner(keyBtn, 5)
    stroke(keyBtn, C.red, 1, 0.75)

    keyBtn.MouseButton1Click:Connect(function()
        keyBtn.Text = "[...]"
        setStatus(string.format("%s %s", UITEXT[currentLang].pressKey, t(item.label)))
        ui.waitingKey = function(keyName)
            item.key = keyName
            keyBtn.Text = "[" .. keyName .. "]"
            setStatus(string.format("%s %s [%s]", t(item.label), UITEXT[currentLang].keyAssigned, keyName))
        end
    end)

    return holder
end

local function buildKeybindButton(item, parent, width)
    local holder, card = baseCard(parent, width, CARD_H.keybind_button)
    local hasState = (item.active ~= nil)

    makeText(card, {
        Position = UDim2.fromOffset(10, 7),
        Size = UDim2.new(1, -60, 0, 15),
        Text = t(item.label),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = C.text,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local keyBtn = new("TextButton", {
        Size = UDim2.fromOffset(34, 18),
        Position = UDim2.new(1, -10, 0, 8),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = C.dark,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "[" .. tostring(item.key) .. "]",
        Font = Enum.Font.Code,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(252, 165, 165),
        Parent = card,
    })
    corner(keyBtn, 5)
    stroke(keyBtn, C.red, 1, 0.75)

    keyBtn.MouseButton1Click:Connect(function()
        keyBtn.Text = "[...]"
        setStatus(string.format("%s %s", UITEXT[currentLang].pressKey, t(item.label)))
        ui.waitingKey = function(keyName)
            item.key = keyName
            keyBtn.Text = "[" .. keyName .. "]"
            setStatus(string.format("%s %s [%s]", t(item.label), UITEXT[currentLang].keyAssigned, keyName))
        end
    end)

    local mobileBtn = new("TextButton", {
        Position = UDim2.fromOffset(10, 28),
        Size = UDim2.new(1, -20, 0, 24),
        BackgroundColor3 = (hasState and item.active) and C.red or (hasState and C.knobOff or C.redSoft),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = card,
    })
    corner(mobileBtn, 6)
    if not hasState or not item.active then
        stroke(mobileBtn, C.red, 1, 0.65)
    end

    local mobileText = makeText(mobileBtn, {
        Size = UDim2.fromScale(1, 1),
        Text = hasState
            and string.format("%s: %s", t(item.btn), item.active and UITEXT[currentLang].stateOn or UITEXT[currentLang].stateOff)
            or t(item.btn),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = hasState and (item.active and C.white or C.textDim) or Color3.fromRGB(252, 165, 165),
    })
    mobileBtn.TextTransparency = 1
    mobileBtn.Text = ""

    local function refreshMobile()
        mobileBtn.BackgroundColor3 = (hasState and item.active) and C.red or (hasState and C.knobOff or C.redSoft)
        mobileText.TextColor3 = hasState and (item.active and C.white or C.textDim) or Color3.fromRGB(252, 165, 165)
        mobileText.Text = hasState
            and string.format("%s: %s", t(item.btn), item.active and UITEXT[currentLang].stateOn or UITEXT[currentLang].stateOff)
            or t(item.btn)
    end

    mobileBtn.MouseButton1Click:Connect(function()
        if hasState then
            item.active = not item.active
            if item.feature then
                flags[item.feature] = item.active
                syncFeature(item.feature, item.active)
                onFlagChanged(item.feature, item.active)
            end
            refreshMobile()
            setStatus(string.format("%s: %s", t(item.label),
                item.active and UITEXT[currentLang].on or UITEXT[currentLang].off))
            updateActiveCount()
            renderTabs()
        else
            if item.id == "emote_stop" then stopEmotes() end
            local original = t(item.btn)
            mobileText.Text = UITEXT[currentLang].stopped
            setStatus(string.format("%s %s", t(item.label), UITEXT[currentLang].executed))
            task.delay(0.75, function()
                if mobileText and mobileText.Parent then mobileText.Text = original end
            end)
        end
    end)

    return holder
end

local function buildAction(item, parent, width)
    local holder, card = baseCard(parent, width, CARD_H.action)

    makeText(card, {
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Text = t(item.label),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = C.text,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local btn = new("TextButton", {
        Size = UDim2.fromOffset(62, 22),
        Position = UDim2.new(1, -10, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = C.redSoft,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = card,
    })
    corner(btn, 6)
    stroke(btn, C.red, 1, 0.65)

    local btnText = makeText(btn, {
        Size = UDim2.fromScale(1, 1),
        Text = t(item.btn),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = Color3.fromRGB(252, 165, 165),
    })

    btn.MouseButton1Click:Connect(function()
        if item.id == "emote_zen" then
            playEmote("Zen")
        elseif item.id == "emote_floss" then
            playEmote("Floss")
        elseif item.id == "save_config" then
            saveConfig()
        end
        btnText.Text = "✓"
        setStatus(string.format("%s %s", t(item.label), UITEXT[currentLang].executed))
        task.delay(0.75, function()
            if btnText and btnText.Parent then btnText.Text = t(item.btn) end
        end)
    end)

    return holder
end

local function buildPlayerFling(item, parent)
    local isOpen = item.dropdownOpen
    local playerList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(playerList, p) end
    end
    table.sort(playerList, function(a, b) return string.lower(a.Name) < string.lower(b.Name) end)

    local cols = 3
    local rows = math.max(1, math.ceil(#playerList / cols))
    local listH = isOpen and (rows * 30 + 4) or 0
    local cardH = 10 + 32 + 8 + (isOpen and (listH + 8) or 0) + 28 + 10

    local holder, card = baseCard(parent, 1, cardH)
    padding(card, 10, 10, 10, 10)
    local layout = new("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = card,
    })

    -- Dropdown butonu
    local dropBtn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        LayoutOrder = 1,
        BackgroundColor3 = C.dark,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = card,
    })
    corner(dropBtn, 6)
    stroke(dropBtn, C.red, 1, 0.75)

    local labelTxt = makeText(dropBtn, {
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -34, 1, 0),
        Text = item.selectedPlayer
            and (t(item.label) .. ": " .. item.selectedPlayer)
            or t(item.label),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = C.text,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    makeText(dropBtn, {
        Size = UDim2.fromOffset(16, 32),
        Position = UDim2.new(1, -22, 0, 0),
        Text = isOpen and "▲" or "▼",
        TextSize = 9,
        TextColor3 = C.red,
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    dropBtn.MouseButton1Click:Connect(function()
        item.dropdownOpen = not item.dropdownOpen
        renderContent()
    end)

    -- Oyuncu listesi
    if isOpen then
        local grid = new("Frame", {
            Size = UDim2.new(1, 0, 0, listH),
            LayoutOrder = 2,
            BackgroundColor3 = C.darker,
            BorderSizePixel = 0,
            Parent = card,
        })
        corner(grid, 6)
        stroke(grid, C.red, 1, 0.7)
        local gl = new("UIGridLayout", {
            CellSize = UDim2.new(1 / cols, -4, 0, 26),
            CellPadding = UDim2.new(0, 4, 0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = grid,
        })
        padding(grid, 4, 4, 4, 4)

        if #playerList == 0 then
            makeText(grid, {
                Size = UDim2.new(1, 0, 0, 26),
                Text = "—",
                TextSize = 10,
                TextColor3 = C.textFaint,
                TextXAlignment = Enum.TextXAlignment.Center,
                LayoutOrder = 1,
            })
        end

        for i, plr in ipairs(playerList) do
            local isSel = (item.selectedPlayer == plr.Name)
            local opt = new("TextButton", {
                Size = UDim2.fromScale(1, 1),
                LayoutOrder = i,
                BackgroundColor3 = isSel and C.redSoft or C.card,
                BackgroundTransparency = isSel and 0 or 1,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                Parent = grid,
            })
            corner(opt, 4)
            if isSel then stroke(opt, C.red, 1, 0.6) end
            makeText(opt, {
                Size = UDim2.fromScale(1, 1),
                Text = plr.Name,
                TextSize = 9,
                TextColor3 = isSel and Color3.fromRGB(252, 165, 165) or C.textDim,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextTruncate = Enum.TextTruncate.AtEnd,
            })
            opt.MouseButton1Click:Connect(function()
                item.selectedPlayer = plr.Name
                item.dropdownOpen = false
                state.selectedPlayer = plr
                setStatus(string.format("%s %s", plr.Name, UITEXT[currentLang].autoFlung))
                renderContent()
                tryFling(plr) -- seçildiği an otomatik fling
            end)
        end
    end

    -- Fling butonu
    local flingBtn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 28),
        LayoutOrder = 10,
        BackgroundColor3 = C.red,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = card,
    })
    corner(flingBtn, 6)
    makeText(flingBtn, {
        Size = UDim2.fromScale(1, 1),
        Text = UITEXT[currentLang].flingNow,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = C.white,
    })

    flingBtn.MouseButton1Click:Connect(function()
        local target = state.selectedPlayer
        if not target or not target.Parent then
            setStatus(UITEXT[currentLang].selectPlayerFirst)
            return
        end
        setStatus(string.format("%s %s", target.Name, UITEXT[currentLang].reflung))
        tryFling(target)
    end)

    return holder
end

local function buildSection(item, parent)
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, CARD_H.section),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    makeText(holder, {
        Position = UDim2.fromOffset(2, 0),
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = string.upper(t(item.label)),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = C.red,
    })
    local line = new("Frame", {
        Size = UDim2.new(1, -110, 0, 1),
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = C.red,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        Parent = holder,
    })
    return holder
end

--=============================================================
--  RENDER: İÇERİK
--=============================================================
local function buildCard(item, parent, width)
    if item.type == "toggle" then return buildToggle(item, parent, width)
    elseif item.type == "select" then return buildSelect(item, parent, width)
    elseif item.type == "keybind" then return buildKeybind(item, parent, width ~= nil)
    elseif item.type == "keybind_button" then return buildKeybindButton(item, parent, width)
    elseif item.type == "action" then return buildAction(item, parent, width)
    elseif item.type == "section" then return buildSection(item, parent)
    elseif item.type == "player_fling" then return buildPlayerFling(item, parent)
    end
    return nil
end

renderContent = function()
    local tab
    for _, tb in ipairs(tabs) do
        if tb.id == currentTab then tab = tb break end
    end
    if not tab then return end

    -- Header
    ui.title.Text = tab.id
    ui.badge.Text = t(tab.badge)

    -- Temizle
    for _, ch in ipairs(ui.contentScroll:GetChildren()) do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end

    -- Filtrele
    local filtered = {}
    for _, item in ipairs(tab.items) do
        if searchQuery == "" then
            table.insert(filtered, item)
        elseif item.type ~= "section" then
            local lbl = string.lower(t(item.label))
            local dsc = item.desc and string.lower(t(item.desc)) or ""
            if string.find(lbl, searchQuery, 1, true) or string.find(dsc, searchQuery, 1, true) then
                table.insert(filtered, item)
            end
        end
    end

    if #filtered == 0 then
        local empty = new("Frame", {
            Size = UDim2.new(1, 0, 0, 80),
            BackgroundTransparency = 1,
            Parent = ui.contentScroll,
        })
        makeText(empty, {
            Size = UDim2.fromScale(1, 1),
            Text = UITEXT[currentLang].noMatch,
            TextSize = 11,
            TextColor3 = C.textFaint,
            TextXAlignment = Enum.TextXAlignment.Center,
        })
        return
    end

    -- Yerleşim: toggles 2'li, geri kalan tam genişlik
    local pendingToggles = {}
    local order = 0

    local function flushToggles()
        if #pendingToggles == 0 then return end
        order = order + 1
        local row = new("Frame", {
            Size = UDim2.new(1, 0, 0, CARD_H.toggle),
            LayoutOrder = order,
            BackgroundTransparency = 1,
            Parent = ui.contentScroll,
        })
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = row,
        })
        for i, it in ipairs(pendingToggles) do
            local h = buildToggle(it, row, 0.5)
            h.LayoutOrder = i
        end
        pendingToggles = {}
    end

    for _, item in ipairs(filtered) do
        if item.type == "toggle" then
            table.insert(pendingToggles, item)
            if #pendingToggles == 2 then flushToggles() end
        else
            flushToggles()
            order = order + 1
            local h = buildCard(item, ui.contentScroll, nil)
            if h then h.LayoutOrder = order end
        end
    end
    flushToggles()
end

--=============================================================
--  SIDEBAR / CHROME GÜNCELLEMELERİ
--=============================================================
updateActiveCount = function()
    local count = 0
    for _, tab in ipairs(tabs) do
        for _, item in ipairs(tab.items) do
            if item.active == true and (item.type == "toggle" or item.type == "keybind_button") then
                count = count + 1
            end
        end
    end
    if ui.activeCount then
        ui.activeCount.Text = count .. " " .. UITEXT[currentLang].activeSuffix
    end
end

updateChrome = function()
    local txt = UITEXT[currentLang]
    if ui.searchBox then ui.searchBox.PlaceholderText = txt.searchPlaceholder end
    if ui.resetBtn then ui.resetBtn.Text = txt.reset end
    if ui.title then ui.title.Text = currentTab end
    for lang, data in pairs(langButtons) do
        local selected = (lang == currentLang)
        data.btn.BackgroundColor3 = selected and C.redSoft or C.dark
        data.stroke.Color = selected and C.red or C.border
        data.stroke.Transparency = selected and 0.6 or 0
        data.text.TextColor3 = selected and Color3.fromRGB(252, 165, 165) or C.textDim
        data.text.Font = selected and Enum.Font.GothamBold or Enum.Font.GothamMedium
    end
end

renderAll = function()
    updateChrome()
    updateActiveCount()
    renderTabs()
    renderContent()
end

--=============================================================
--  FLAG DEĞİŞİM KANCALARI
--=============================================================
function syncFeature(feature, value)
    for _, tab in ipairs(tabs) do
        for _, item in ipairs(tab.items) do
            if item.feature == feature and item.active ~= nil then
                item.active = value
            end
        end
    end
end

function onFlagChanged(feature, value)
    if feature == "vision" and not value then
        clearHighlights()
    elseif (feature == "orbit" or feature == "tbag") and not value then
        local hrp = getHRP()
        if hrp then
            hrp.AssemblyAngularVelocity = Vector3.new()
        end
    end
end

--=============================================================
--  CONFIG KAYDETME
--=============================================================
function saveConfig()
    local data = { lang = currentLang }
    for _, tab in ipairs(tabs) do
        for _, item in ipairs(tab.items) do
            if item.id then
                data[item.id] = {
                    active = item.active,
                    key = item.key,
                    selected = item.selected,
                    player = item.selectedPlayer,
                }
            end
        end
    end
    local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
    if ok and writefile then
        pcall(writefile, "KashMulti_Config.json", json)
    end
end

--=============================================================
--  SÜRÜKLEME + RShift
--=============================================================
local dragging, dragStart, startPos
local function makeDraggable(frame)
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
end

makeDraggable(brandLine)
makeDraggable(sidebar)
makeDraggable(headerLine)

UserInputService.InputChanged:Connect(function(input)
    if dragging then
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end
end)

--=============================================================
--  TUŞ ATAMALARI
--=============================================================
local keybindItems = {}
local function rebuildKeybindCache()
    keybindItems = {}
    for _, tab in ipairs(tabs) do
        for _, item in ipairs(tab.items) do
            if item.key and (item.type == "keybind" or item.type == "keybind_button") then
                table.insert(keybindItems, item)
            end
        end
    end
end

local function handleKeybind(item)
    if item.id == "vision_toggle" then
        flags.vision = not flags.vision
        syncFeature("vision", flags.vision)
        onFlagChanged("vision", flags.vision)
        setStatus(string.format("%s: %s", t(item.label),
            flags.vision and UITEXT[currentLang].on or UITEXT[currentLang].off))
    elseif item.id == "fling_keybind" then
        flags.touchFling = not flags.touchFling
        syncFeature("touchFling", flags.touchFling)
        setStatus(string.format("%s: %s", t(item.label),
            flags.touchFling and UITEXT[currentLang].on or UITEXT[currentLang].off))
    elseif item.id == "emote_stop" then
        stopEmotes()
        setStatus(string.format("%s %s", t(item.label), UITEXT[currentLang].executed))
    end
    updateActiveCount()
    renderTabs()
    renderContent()
end

UserInputService.InputBegan:Connect(function(input, gpe)
    -- Tuş atama modu
    if ui.waitingKey and input.UserInputType == Enum.UserInputType.Keyboard then
        local keyName = input.KeyCode.Name
        local fn = ui.waitingKey
        ui.waitingKey = nil
        fn(keyName)
        return
    end

    -- RShift: pencere aç/kapat
    if input.KeyCode == Enum.KeyCode.RightShift then
        window.Visible = not window.Visible
        return
    end

    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if UserInputService:GetFocusedTextBox() then return end

    for _, item in ipairs(keybindItems) do
        if item.key and input.KeyCode.Name == string.upper(item.key) then
            handleKeybind(item)
            return
        end
    end
end)

--=============================================================
--  ÖZELLİK DÖNGÜLERİ
--=============================================================
-- Vision
task.spawn(function()
    while true do
        task.wait(0.25)
        if flags.vision then
            updateHighlights()
        end
    end
end)

-- Touch Fling bağlantısı (respawn'da yeniden kurulur)
local touchConn
local function setupTouchFling()
    if touchConn then touchConn:Disconnect() end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    touchConn = hrp.Touched:Connect(function(hit)
        if not flags.touchFling then return end
        local model = hit:FindFirstAncestorOfClass("Model")
        if not model then
            model = hit.Parent
        end
        if model and model ~= char then
            local plr = Players:GetPlayerFromCharacter(model)
            if plr and plr ~= LocalPlayer then
                tryFling(plr)
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    setupTouchFling()
end)
task.spawn(setupTouchFling)

-- Anti-Fling / Walk Fling / Orbit / Tbag
local walkAccum = 0
local orbitAngle = 0
local tbagClock = 0

RunService.Heartbeat:Connect(function(dt)
    local hrp = getHRP()

    -- Anti-Fling Shield
    if flags.antiFling and hrp and not flingBusy then
        local ang = hrp.AssemblyAngularVelocity
        if ang.Magnitude > 1 then
            hrp.AssemblyAngularVelocity = Vector3.new()
        end
        local lin = hrp.AssemblyLinearVelocity
        if lin.Magnitude > 110 then
            hrp.AssemblyLinearVelocity = lin.Unit * 60
        end
    end

    -- Walk Fling
    if flags.walkFling and hrp then
        walkAccum = walkAccum + dt
        if walkAccum >= 0.3 then
            walkAccum = 0
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local thrp = getHRP(plr)
                    if thrp and (thrp.Position - hrp.Position).Magnitude <= 6 then
                        tryFling(plr)
                    end
                end
            end
        end
    end

    -- Orbit
    if flags.orbit and hrp then
        local target = getTargetPlayer(true)
        local thrp = target and getHRP(target)
        if thrp then
            orbitAngle = orbitAngle + dt * 3
            local offset = CFrame.new(math.cos(orbitAngle) * 6, 2, math.sin(orbitAngle) * 6)
            hrp.CFrame = thrp.CFrame * offset
            hrp.AssemblyLinearVelocity = Vector3.new()
        end
    end

    -- Tbag
    if flags.tbag and not flags.orbit and hrp then
        local target = getTargetPlayer(true)
        local thrp = target and getHRP(target)
        if thrp then
            tbagClock = tbagClock + dt
            local wiggle = math.abs(math.sin(tbagClock * 10)) * 1.6
            hrp.CFrame = thrp.CFrame * CFrame.new(0, 0.5 - wiggle, 3)
            hrp.AssemblyLinearVelocity = Vector3.new()
        end
    end
end)

-- Farm döngüsü
task.spawn(function()
    while true do
        task.wait(0.12)
        if flags.farm then
            local hrp = getHRP()
            if hrp then
                local coin = findNearestCoin()
                if coin then
                    local styleItem
                    for _, tab in ipairs(tabs) do
                        for _, item in ipairs(tab.items) do
                            if item.id == "farm_style" then styleItem = item end
                        end
                    end
                    local style = styleItem and styleItem.selected or "fly"
                    local dest = CFrame.new(coin.Position + Vector3.new(0, 1.5, 0))
                    if style == "teleport" then
                        hrp.CFrame = dest
                    else
                        hrp.CFrame = hrp.CFrame:Lerp(dest, 0.35)
                        hrp.AssemblyLinearVelocity = Vector3.new()
                    end
                    touchFire(coin)
                end
            end
        end
    end
end)

-- Fling murderer when full bag
task.spawn(function()
    while true do
        task.wait(0.8)
        if flags.farmBag and getCoinCount() >= FULL_BAG then
            local murderer = findMurderer()
            if murderer then tryFling(murderer) end
        end
    end
end)

-- XP Farm döngüsü
task.spawn(function()
    while true do
        task.wait(0.35)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if char and hum and hum.Health > 0 then
            refreshRoundState()
            local role = getRole(LocalPlayer)

            -- Auto hide underground
            if flags.xpHide and role == "Innocent" and hrp then
                hrp.CFrame = CFrame.new(0, -60, 0)
            end

            -- Auto kill all as murderer
            if flags.xpKillAll and role == "Murderer" and hrp then
                local knife = equipTool("Knife")
                local nearest, bestDist = nil, math.huge
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then
                        local thrp = getHRP(plr)
                        if thrp then
                            local d = (thrp.Position - hrp.Position).Magnitude
                            if d < bestDist then nearest, bestDist = plr, d end
                        end
                    end
                end
                if nearest then
                    local thrp = getHRP(nearest)
                    if thrp then
                        if bestDist > 4 then
                            hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, 2.5)
                        else
                            activateTool(knife)
                        end
                    end
                end
            end

            -- Auto shoot murderer
            if flags.xpShoot and hrp then
                local murderer = findMurderer()
                local gun = char:FindFirstChild("Gun")
                if murderer and gun then
                    local thrp = getHRP(murderer)
                    if thrp then
                        hrp.CFrame = CFrame.lookAt(hrp.Position, thrp.Position)
                        activateTool(gun)
                    end
                elseif murderer then
                    local bpGun = LocalPlayer:FindFirstChildOfClass("Backpack")
                    if bpGun and bpGun:FindFirstChild("Gun") then
                        equipTool("Gun")
                    end
                end
            end
        end
    end
end)

-- Auto grab gun
task.spawn(function()
    while true do
        task.wait(0.5)
        if flags.autoGun then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and not char:FindFirstChild("Gun") then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name == "GunDrop" then
                        hrp.CFrame = CFrame.new(obj.Position + Vector3.new(0, 2, 0))
                        touchFire(obj)
                        break
                    end
                end
            end
        end
    end
end)

--=============================================================
--  ETKİLEŞİMLER
--=============================================================
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchQuery = string.lower(searchBox.Text)
    renderContent()
end)

resetBtn.MouseButton1Click:Connect(function()
    tabs = defaultTabs()
    flags = defaultFlags()
    state.selectedPlayer = nil
    searchQuery = ""
    searchBox.Text = ""
    clearHighlights()
    stopEmotes()
    rebuildKeybindCache()
    setStatus(UITEXT[currentLang].resetDone)
    renderAll()
end)

--=============================================================
--  BAŞLAT
--=============================================================
rebuildKeybindCache()
renderAll()
setStatus(UITEXT[currentLang].themeActive)

-- Config yükleme (varsa)
pcall(function()
    if readfile and isfile and isfile("KashMulti_Config.json") then
        local json = readfile("KashMulti_Config.json")
        local data = HttpService:JSONDecode(json)
        for _, tab in ipairs(tabs) do
            for _, item in ipairs(tab.items) do
                local saved = item.id and data[item.id]
                if saved then
                    if saved.active ~= nil and item.active ~= nil then
                        item.active = saved.active
                        if item.feature then flags[item.feature] = saved.active end
                    end
                    if saved.key then item.key = saved.key end
                    if saved.selected then item.selected = saved.selected end
                end
            end
        end
        if data.lang then currentLang = data.lang end
        renderAll()
    end
end)