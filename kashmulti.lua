if not game:IsLoaded() then game.Loaded:Wait() end
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local HttpService        = game:GetService("HttpService")
local TeleportService    = game:GetService("TeleportService")
local Workspace          = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end
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
local setStatus
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
        autoFlung = "selected",
        reflung = "flung!",
        choosePlayer = "Choose player",
        chooseChar = "Choose character",
        langChanged = "Language switched to English",
        flingNow = "Fling",
        flingAll = "Fling All",
        flingAllStart = "Flinging all players...",
        flingAllDone = "All players flung!",
        flingAllEmpty = "No players to fling",
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
        autoFlung = "seçildi",
        reflung = "flinglendi!",
        choosePlayer = "Choose player",
        chooseChar = "Karakter seç",
        langChanged = "Dil Türkçe olarak değiştirildi",
        flingNow = "Fling",
        flingAll = "Fling All",
        flingAllStart = "Tüm oyuncular flingleniyor...",
        flingAllDone = "Tüm oyuncular flinglendi!",
        flingAllEmpty = "Flinglenecek oyuncu yok",
        play = "Oynat",
        save = "Kaydet",
    },
}
local currentLang = "en"
local function t(val)
    if type(val) == "table" then return val[currentLang] or val.en or "" end
    return val or ""
end
local function defaultFlags()
    return {
        vision     = true,
        touchFling = false,
        antiFling  = false,
        walkFling  = false,
        orbit      = false,
        tbag       = false,
        farmBag    = false,
        farm       = false,
        xpKillAll  = false,
        xpHide     = false,
        xpShoot    = false,
        autoGun    = false,
        shortcutFling = false,
        shortcutShoot = false,
        showRoles     = true,
    }
end
local flags = defaultFlags()
local state = { selectedPlayer = nil, emotePlayer = nil }
local searchQuery = ""
local currentTab = "Vision"
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
                    active = false,
                },
                {
                    type = "toggle", id = "fling_shield", feature = "antiFling",
                    label = { en = "Anti-Fling Shield", tr = "Anti-Fling Shield" },
                    desc = { en = "Block incoming fling attacks", tr = "Gelen fling saldırısını kes" },
                    active = false,
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
                    type = "action", id = "fling_all",
                    label = { en = "Fling All", tr = "Hepsini Flingle" },
                    btn = { en = "Fling All", tr = "Flingle" },
                    desc = { en = "Flings every player one by one", tr = "Bütün oyuncuları teker teker fırlatır" },
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
                    type = "action", id = "emote_hump",
                    label = { en = "Hump", tr = "Dayama" },
                    btn = { en = "Play", tr = "Oynat" },
                },
                {
                    type = "action", id = "emote_hand",
                    label = { en = "Hand", tr = "El Hareketi" },
                    btn = { en = "Play", tr = "Oynat" },
                },
                {
                    type = "action", id = "emote_kick",
                    label = { en = "Flying Kick", tr = "Uçuran Tekme" },
                    btn = { en = "Kick", tr = "Tekme" },
                },
                {
                    type = "keybind_button", id = "emote_stop",
                    label = { en = "Stop Emote", tr = "Emote Durdur" },
                    btn = { en = "Stop Emote", tr = "Emote Durdur" },
                    key = "X",
                },
                {
                    type = "player_select", id = "emote_player",
                    label = { en = "Choose character", tr = "Karakter seç" },
                    selectedPlayer = nil, dropdownOpen = false,
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
                    active = false,
                },
            },
        },
        {
            id = "Player",
            icon = "⚙",
            badge = { en = "System", tr = "Sistem" },
            items = {
                {
                    type = "section", id = "sec_join",
                    label = { en = "Join Player", tr = "Oyuncuya Join" },
                },
                {
                    type = "join_player", id = "join_player",
                    label = { en = "Join by ID / nickname", tr = "ID / nick ile join" },
                    desc = {
                        en = "Teleports to that player's server if their joins are open",
                        tr = "Join açıksa oyuncunun sunucusuna ışınlanır",
                    },
                    placeholder = { en = "User ID or nickname...", tr = "ID veya nick..." },
                    btn = { en = "Join", tr = "Join" },
                },
                {
                    type = "toggle", id = "auto_gun", feature = "autoGun",
                    label = { en = "Auto grab gun", tr = "Auto grab gun" },
                    desc = { en = "Automatically pick up dropped gun", tr = "Düşen silahı otomatik al" },
                    active = false,
                },
                {
                    type = "keybind", id = "shoot_keybind",
                    label = { en = "Shoot murderer", tr = "Shoot murderer" },
                    desc = { en = "Only if you have a gun", tr = "Sadece silahın varsa" },
                    key = "G",
                },
                {
                    type = "action", id = "shoot_now",
                    label = { en = "Shoot murderer", tr = "Shoot murderer" },
                    btn = { en = "Shoot", tr = "Vur" },
                },
                {
                    type = "action", id = "save_config",
                    label = { en = "Save Config", tr = "Config Kaydet" },
                    btn = { en = "Save", tr = "Kaydet" },
                },
            },
        },
        {
            id = "Shortcuts",
            icon = "⭐",
            badge = { en = "Mobile", tr = "Mobil" },
            items = {
                {
                    type = "toggle", id = "sc_fling", feature = "shortcutFling",
                    label = { en = "Fling button", tr = "Fling butonu" },
                    desc = { en = "Adds a fling button to the screen", tr = "Ekrana fling butonu ekler" },
                    active = false,
                },
                {
                    type = "toggle", id = "sc_shoot", feature = "shortcutShoot",
                    label = { en = "Shoot murderer button", tr = "Shoot murderer button" },
                    desc = { en = "Adds a shoot button to the screen", tr = "Ekrana vur butonu ekler" },
                    active = false,
                },
                {
                    type = "toggle", id = "sc_roles", feature = "showRoles",
                    label = { en = "Show murderer & sheriff", tr = "Katil ve şerifi göster" },
                    desc = { en = "Shows roles with avatars at bottom right", tr = "Sağ altta avatar ve isimlerle gösterir" },
                    active = true,
                },
            },
        },
    }
end
local tabs = defaultTabs()
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
local function getTargetPlayer(nearestFallback, preferEmote)
    local p
    if preferEmote then
        p = state.emotePlayer
        if not (p and p.Parent and p.Character) then p = state.selectedPlayer end
    else
        p = state.selectedPlayer
    end
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
            d.CanCollide = false
        end
    end
    local thrust = Instance.new("BodyThrust")
    thrust.Name = "KashYeet"
    thrust.Force = Vector3.new(9999, 9999, 9999)
    thrust.Location = thrp.Position
    thrust.Parent = hrp
    local startClock = os.clock()
    repeat
        if not target.Parent or not hrp.Parent then break end
        local tHRP = getHRP(target)
        if not tHRP then break end
        hrp.CFrame = tHRP.CFrame
        thrust.Location = tHRP.Position
        RunService.Heartbeat:Wait()
    until os.clock() - startClock > 0.6
    if thrust and thrust.Parent then thrust:Destroy() end
    if hrp and hrp.Parent then
        hrp.AssemblyAngularVelocity = Vector3.new()
        hrp.AssemblyLinearVelocity = Vector3.new()
        hrp.CFrame = savedCF
    end
    for part, st in pairs(collideStates) do
        if part.Parent then part.CanCollide = st end
    end
    flingBusy = false
end
local function tryFling(target)
    if not target or target == LocalPlayer then return end
    local last = flingDebounce[target]
    if last and (os.clock() - last) < 1 then return end
    flingDebounce[target] = os.clock()
    task.spawn(flingPlayer, target)
end
local function flingCurrent()
    local target = state.selectedPlayer
    if target and target.Parent and target.Character then
        tryFling(target)
        setStatus(target.Name .. " " .. UITEXT[currentLang].reflung)
        return
    end
    local near = getTargetPlayer(true)
    if near then
        tryFling(near)
        setStatus(near.Name .. " " .. UITEXT[currentLang].reflung)
    end
end
local flingAllRunning = false
local function flingAll()
    if flingAllRunning then return end
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(list, plr)
        end
    end
    if #list == 0 then
        setStatus(UITEXT[currentLang].flingAllEmpty)
        return
    end
    flingAllRunning = true
    task.spawn(function()
        setStatus(UITEXT[currentLang].flingAllStart)
        for _, plr in ipairs(list) do
            if plr.Parent and plr.Character and getHRP(plr) then
                while flingBusy do task.wait(0.05) end
                flingPlayer(plr)
                flingDebounce[plr] = os.clock()
                setStatus(plr.Name .. " " .. UITEXT[currentLang].reflung)
                task.wait(0.1)
            end
        end
        flingAllRunning = false
        setStatus(UITEXT[currentLang].flingAllDone)
    end)
end
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
local emoteOrigC0 = {}
local function getRig(char)
    local rig = {}
    for _, m in ipairs(char:GetDescendants()) do
        if m:IsA("Motor6D") then
            local key = string.gsub(m.Name, "%s", "")
            emoteOrigC0[key] = m.C0
            rig[key] = m
        end
    end
    return rig
end
local function charHRP(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return (hum and hum.RootPart) or (char and char:FindFirstChild("HumanoidRootPart"))
end
local function joint(rig, name, cf)
    local motor = rig[name]
    if motor and motor.Parent then
        -- Poz SADECE C0 uzerinden uygulanir. Transform da yazilirsa aci iki kez
        -- uygulanir: Part1 = Part0 * C0 * Transform * C1^-1
        motor.Transform = CFrame.identity
        local orig = emoteOrigC0[name]
        if orig then
            pcall(function() motor.C0 = orig * cf end)
        end
    end
end
local function resetRig(rig)
    for name, motor in pairs(rig) do
        if motor.Parent then
            motor.Transform = CFrame.identity
            local orig = emoteOrigC0[name]
            if orig then
                pcall(function() motor.C0 = orig end)
            end
        end
    end
end
local KICK_CYCLE = 1.4
local emoteKickCycle = -1
local function kickExtend(time)
    local phase = time % KICK_CYCLE
    if phase < 0.12 then
        return (phase / 0.12) * 0.2
    elseif phase < 0.34 then
        return 1
    elseif phase < 0.7 then
        return math.max(0, 1 - (phase - 0.34) / 0.36)
    end
    return 0
end
local emoteDefs = {
    Zen = {
        pose = function(rig, time)
            local breathe = math.sin(time * 2) * 0.04
            joint(rig, "Waist", CFrame.new(0, -0.25, 0) * CFrame.Angles(math.rad(10), 0, 0))
            joint(rig, "RootJoint", CFrame.new(0, breathe, 0))
            joint(rig, "Neck", CFrame.Angles(math.rad(-8), 0, 0))
            joint(rig, "LeftShoulder", CFrame.Angles(math.rad(10), math.rad(25), math.rad(-70)))
            joint(rig, "RightShoulder", CFrame.Angles(math.rad(10), math.rad(-25), math.rad(70)))
            joint(rig, "LeftElbow", CFrame.Angles(0, math.rad(-80), 0))
            joint(rig, "RightElbow", CFrame.Angles(0, math.rad(80), 0))
            joint(rig, "LeftWrist", CFrame.Angles(0, 0, math.rad(-25 + breathe * 120)))
            joint(rig, "RightWrist", CFrame.Angles(0, 0, math.rad(25 - breathe * 120)))
            joint(rig, "LeftHip", CFrame.Angles(math.rad(-65), 0, math.rad(30)))
            joint(rig, "RightHip", CFrame.Angles(math.rad(-65), 0, math.rad(-30)))
            joint(rig, "LeftKnee", CFrame.Angles(math.rad(85), 0, 0))
            joint(rig, "RightKnee", CFrame.Angles(math.rad(85), 0, 0))
        end,
    },
    Floss = {
        pose = function(rig, time)
            local w = math.sin(time * 9)
            joint(rig, "Waist", CFrame.Angles(0, math.rad(w * 18), 0))
            joint(rig, "RootJoint", CFrame.new(w * 0.1, math.abs(w) * 0.15, 0))
            joint(rig, "LeftShoulder", CFrame.Angles(0, 0, math.rad(-80 - w * 55)))
            joint(rig, "RightShoulder", CFrame.Angles(0, 0, math.rad(80 + w * 55)))
            joint(rig, "LeftElbow", CFrame.Angles(0, math.rad(-20), 0))
            joint(rig, "RightElbow", CFrame.Angles(0, math.rad(20), 0))
            joint(rig, "LeftHip", CFrame.Angles(0, math.rad(w * 12), math.rad(-w * 18)))
            joint(rig, "RightHip", CFrame.Angles(0, math.rad(w * 12), math.rad(-w * 18)))
        end,
    },
    Hump = {
        position = function(hrp, thrp, time)
            local thrust = math.sin(time * 11) * 0.32
            hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, 1.1 + thrust)
            hrp.AssemblyLinearVelocity = Vector3.new()
        end,
        pose = function(rig, time)
            local w = math.sin(time * 11)
            joint(rig, "Waist", CFrame.new(0, 0, w * 0.12) * CFrame.Angles(math.rad(16 + w * 6), 0, 0))
            joint(rig, "RootJoint", CFrame.new(0, 0, w * 0.18))
            joint(rig, "Neck", CFrame.Angles(math.rad(-10), 0, 0))
            joint(rig, "LeftShoulder", CFrame.Angles(math.rad(20), math.rad(55), math.rad(-30)))
            joint(rig, "RightShoulder", CFrame.Angles(math.rad(20), math.rad(-55), math.rad(30)))
            joint(rig, "LeftElbow", CFrame.Angles(0, math.rad(-45), 0))
            joint(rig, "RightElbow", CFrame.Angles(0, math.rad(45), 0))
            joint(rig, "LeftHip", CFrame.Angles(math.rad(-10), 0, math.rad(8)))
            joint(rig, "RightHip", CFrame.Angles(math.rad(-10), 0, math.rad(-8)))
            joint(rig, "LeftKnee", CFrame.Angles(math.rad(25), 0, 0))
            joint(rig, "RightKnee", CFrame.Angles(math.rad(25), 0, 0))
        end,
    },
    Hand = {
        position = function(hrp, thrp, time)
            local stand = thrp.Position + thrp.CFrame.LookVector * 2.6
            local pos = Vector3.new(stand.X, hrp.Position.Y, stand.Z)
            local look = Vector3.new(thrp.Position.X, hrp.Position.Y, thrp.Position.Z)
            if (look - pos).Magnitude > 0.1 then
                hrp.CFrame = CFrame.lookAt(pos, look)
                hrp.AssemblyLinearVelocity = Vector3.new()
            end
        end,
        pose = function(rig, time)
            local w = math.sin(time * 10)
            joint(rig, "RightShoulder", CFrame.Angles(math.rad(55), math.rad(-10), math.rad(62 + w * 14)))
            joint(rig, "RightElbow", CFrame.Angles(0, math.rad(70 + w * 30), 0))
            joint(rig, "RightWrist", CFrame.Angles(math.rad(w * 35), 0, 0))
            joint(rig, "LeftShoulder", CFrame.Angles(0, math.rad(18), math.rad(-22)))
            joint(rig, "LeftElbow", CFrame.Angles(0, math.rad(-30), 0))
            joint(rig, "Neck", CFrame.Angles(math.rad(12), 0, 0))
            joint(rig, "Waist", CFrame.Angles(math.rad(4), 0, 0))
        end,
    },
    Kick = {
        position = function(hrp, thrp, time)
            local ext = kickExtend(time)
            local stand = thrp.Position + thrp.CFrame.LookVector * (3 - 0.8 * ext)
            local pos = Vector3.new(stand.X, hrp.Position.Y, stand.Z)
            local look = Vector3.new(thrp.Position.X, hrp.Position.Y, thrp.Position.Z)
            if (look - pos).Magnitude > 0.1 then
                hrp.CFrame = CFrame.lookAt(pos, look)
                hrp.AssemblyLinearVelocity = Vector3.new()
            end
        end,
        pose = function(rig, time)
            local ext = kickExtend(time)
            local armSwing = math.sin(time * 10) * 6
            joint(rig, "RightHip", CFrame.Angles(math.rad(-95 * ext - 5), 0, math.rad(-8 * ext)))
            joint(rig, "RightKnee", CFrame.Angles(math.rad(20 + 10 * ext), 0, 0))
            joint(rig, "LeftHip", CFrame.Angles(math.rad(10 * ext), 0, math.rad(6)))
            joint(rig, "LeftKnee", CFrame.Angles(math.rad(15 * ext), 0, 0))
            joint(rig, "Waist", CFrame.Angles(math.rad(6 * ext), math.rad(12 * ext), 0))
            joint(rig, "LeftShoulder", CFrame.Angles(math.rad(35 * ext), math.rad(30), math.rad(-30 - armSwing)))
            joint(rig, "RightShoulder", CFrame.Angles(math.rad(-25 * ext), math.rad(-25), math.rad(25)))
            joint(rig, "LeftElbow", CFrame.Angles(0, math.rad(-40), 0))
        end,
        tick = function(time, target, char)
            local cycle = math.floor(time / KICK_CYCLE)
            if kickExtend(time) < 0.8 or cycle == emoteKickCycle then return end
            emoteKickCycle = cycle
            if not target or not target.Parent or not target.Character then return end
            local thrp = getHRP(target)
            local hrp = charHRP(char)
            if not thrp or not hrp then return end
            local dir = thrp.Position - hrp.Position
            if dir.Magnitude < 0.05 then dir = thrp.CFrame.LookVector end
            dir = dir.Unit
            pcall(function()
                thrp.AssemblyLinearVelocity = dir * 90 + Vector3.new(0, 45, 0)
                thrp.AssemblyAngularVelocity = Vector3.new(math.random(-6, 6), math.random(-6, 6), math.random(-6, 6))
            end)
            tryFling(target)
        end,
    },
}
local emoteRig, emoteClock, emoteAnimate, emoteTrackConn
local emoteChar, emoteTarget
local emoteGen = 0
local emoteWarned = false
local function stopProcedural()
    emoteGen = emoteGen + 1
    if emoteTrackConn then
        pcall(function() emoteTrackConn:Disconnect() end)
        emoteTrackConn = nil
    end
    if emoteRig then resetRig(emoteRig); emoteRig = nil end
    if emoteAnimate and emoteAnimate.Parent then
        pcall(function() emoteAnimate.Disabled = false end)
    end
    emoteAnimate = nil
    emoteChar = nil
    emoteTarget = nil
    emoteKickCycle = -1
end
local function startProcedural(name, char, partner)
    local def = emoteDefs[name]
    if not def or not char then return false end
    stopProcedural()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local rig = getRig(char)
    local has = false
    for _ in pairs(rig) do has = true break end
    if not has then return false end
    local gen = emoteGen
    emoteRig = rig
    emoteChar = char
    emoteTarget = partner
    emoteClock = 0
    emoteKickCycle = -1
    emoteWarned = false
    -- 1) Oyun animasyonlarini durdur: idle/walk pozun uzerine yazmasin
    pcall(function()
        for _, tr in ipairs(hum:GetPlayingAnimationTracks()) do
            tr:Stop(0)
        end
    end)
    local animator = hum:FindFirstChildOfClass("Animator")
    if animator then
        pcall(function()
            for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
                tr:Stop(0)
            end
        end)
        pcall(function()
            emoteTrackConn = animator.AnimationPlayed:Connect(function(track)
                if emoteChar == char and emoteRig then
                    pcall(function() track:Stop(0) end)
                end
            end)
        end)
    end
    local animate = char:FindFirstChild("Animate")
    if animate then
        emoteAnimate = animate
        pcall(function() animate.Disabled = true end)
    end
    -- 2) Ilk pozu hemen uygula: dongu calismasa bile poz gorunur kalir
    if def.pose then pcall(def.pose, rig, 0) end
    -- 3) Heartbeat dongusu. Pozlar Motor6D.C0'a yazildigi icin Animator'in render
    --    zamanlamasi onemli degil; BindToRenderStep'e ihtiyac yok.
    task.spawn(function()
        local last = os.clock()
        while gen == emoteGen do
            RunService.Heartbeat:Wait()
            if gen ~= emoteGen then break end
            local ch, target = emoteChar, emoteTarget
            if not ch or not ch.Parent then break end
            local h2 = ch:FindFirstChildOfClass("Humanoid")
            if not h2 or h2.Health <= 0 then break end
            local now = os.clock()
            local dt = now - last
            last = now
            if dt <= 0 or dt > 0.5 then dt = 1 / 60 end
            emoteClock = emoteClock + dt
            local frameOk, frameErr = pcall(function()
                if def.pose then def.pose(rig, emoteClock) end
                if def.tick then def.tick(emoteClock, target, ch) end
                if def.position and ch == LocalPlayer.Character and not flingBusy then
                    local hrp = charHRP(ch)
                    local thrp = target and getHRP(target)
                    if hrp and hrp.Parent and thrp and thrp.Parent then
                        def.position(hrp, thrp, emoteClock)
                    end
                end
            end)
            if not frameOk and not emoteWarned then
                emoteWarned = true
                pcall(warn, "[KashMulti] Emote hatasi: " .. tostring(frameErr))
            end
        end
        if gen == emoteGen then stopProcedural() end
    end)
    return true
end
local function stopEmotes()
    stopProcedural()
    flags.orbit = false
    flags.tbag = false
    for _, tab in ipairs(tabs) do
        for _, item in ipairs(tab.items) do
            if item.feature == "orbit" or item.feature == "tbag" then item.active = false end
        end
    end
end
local function playEmote(name)
    local target = state.emotePlayer
    if not (target and target.Parent and target.Character) then target = LocalPlayer end
    local char = target.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum or hum.Health <= 0 then
        setStatus(currentLang == "tr" and "Karakter bulunamadı" or "Character not found")
        return false
    end
    if not startProcedural(name, char) then
        setStatus(currentLang == "tr" and "Karakter eklemleri (Motor6D) bulunamadı"
            or "Character joints (Motor6D) not found")
        return false
    end
    setStatus((currentLang == "tr" and "Emote: " or "Emote: ") .. name)
    return true
end
local function playPartnerEmote(name)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum or hum.Health <= 0 then
        setStatus(currentLang == "tr" and "Karakter bulunamadı" or "Character not found")
        return false
    end
    local partner = getTargetPlayer(true, true)
    if not partner or not getHRP(partner) then
        setStatus(currentLang == "tr" and "Önce bir oyuncu seç (Choose character)"
            or "Select a player first (Choose character)")
        return false
    end
    -- Orbit / tbag ile çakışmasın
    stopEmotes()
    if not startProcedural(name, char, partner) then
        setStatus(currentLang == "tr" and "Karakter eklemleri (Motor6D) bulunamadı"
            or "Character joints (Motor6D) not found")
        return false
    end
    setStatus((name == "Kick" and (currentLang == "tr" and "Tekme: " or "Kick: ")
        or (currentLang == "tr" and "Emote: " or "Emote: ")) .. partner.Name)
    return true
end
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
local shootBusy = false
local function shootMurderer()
    if shootBusy then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum or hum.Health <= 0 then return end
    refreshRoundState()
    local murderer = findMurderer()
    if not murderer then setStatus("No murderer found") return end
    local thrp = getHRP(murderer)
    local hrp = getHRP()
    if not thrp or not hrp then return end
    local gun = char:FindFirstChild("Gun")
    if not gun then
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        gun = bp and bp:FindFirstChild("Gun")
        if gun then pcall(function() hum:EquipTool(gun) end) end
    end
    if not gun then setStatus("You need a gun") return end
    shootBusy = true
    local saved = hrp.CFrame
    for _ = 1, 4 do
        thrp = getHRP(murderer)
        if not thrp or hum.Health <= 0 then break end
        local standPos = (thrp.CFrame * CFrame.new(0, 0, 7)).Position
        hrp.CFrame = CFrame.lookAt(standPos, thrp.Position)
        hrp.AssemblyLinearVelocity = Vector3.new()
        task.wait(0.08)
        pcall(function() gun:Activate() end)
        task.wait(0.08)
    end
    task.wait(0.12)
    if hrp and hrp.Parent then
        hrp.CFrame = saved
        hrp.AssemblyLinearVelocity = Vector3.new()
        hrp.AssemblyAngularVelocity = Vector3.new()
    end
    shootBusy = false
    setStatus("Shot at " .. murderer.Name)
end
local function joinText(en, tr)
    return currentLang == "tr" and tr or en
end
local function getRequestFunc()
    return (syn and syn.request) or (http and http.request) or request or http_request
end
local function httpJson(method, url, body)
    local req = getRequestFunc()
    if not req then return nil, "nohttp" end
    local ok, response = pcall(function()
        return req({
            Url = url,
            Method = method,
            Headers = { ["Content-Type"] = "application/json" },
            Body = body and HttpService:JSONEncode(body) or nil,
        })
    end)
    if not ok or not response then return nil, "request" end
    if response.StatusCode and response.StatusCode ~= 200 then
        return nil, "status:" .. tostring(response.StatusCode)
    end
    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    if not decodeOk or type(data) ~= "table" then return nil, "decode" end
    return data
end
local function resolveUserId(query)
    query = tostring(query or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if query == "" then return nil, "empty" end

    -- Doğrudan sunucudaki bir oyuncuyla eşleşiyor mu?
    local inServer = Players:FindFirstChild(query)
    if inServer and inServer.UserId then return inServer.UserId end

    -- Profil linki içinden ID çek
    local fromUrl = query:match("/users/(%d+)")
    if fromUrl then return tonumber(fromUrl) end

    -- Sayısal ID
    local asNumber = tonumber(query)
    if asNumber and asNumber > 0 and asNumber % 1 == 0 then
        return math.floor(asNumber)
    end

    -- Nickname -> UserId
    local ok, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(query)
    end)
    if ok and userId and userId > 0 then return userId end

    -- Son çare: roproxy kullanıcı arama API'si
    local data = httpJson("GET", "https://users.roproxy.com/v1/users/search?keyword="
        .. HttpService:UrlEncode(query) .. "&limit=10")
    if data and type(data.data) == "table" then
        local lower = string.lower(query)
        for _, user in ipairs(data.data) do
            if type(user.name) == "string" and string.lower(user.name) == lower and user.id then
                return user.id
            end
        end
        if data.data[1] and data.data[1].id then
            return data.data[1].id
        end
    end
    return nil, "notfound"
end
local function getPresence(userId)
    local data = httpJson("POST", "https://presence.roproxy.com/v1/presence/users", {
        userIds = { userId },
    })
    if data and type(data.userPresences) == "table" and data.userPresences[1] then
        return data.userPresences[1]
    end
    return nil
end
-- Hedef sunucu listede varsa doluluk oranini kontrol eder (en fazla 3 sayfa).
-- Liste alinamaz/sunucu bulunamazsa nil doner (karar teleport olayina birakilir).
local function getServerFill(placeId, jobId)
    local cursor = ""
    for _ = 1, 3 do
        local url = string.format("https://games.roproxy.com/v1/games/%s/servers/Public?limit=100",
            tostring(placeId))
        if cursor ~= "" then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
        local data = httpJson("GET", url)
        if not data or type(data.data) ~= "table" then return nil end
        for _, server in ipairs(data.data) do
            if server.id == jobId then
                local playing = tonumber(server.playing)
                local maxPlayers = tonumber(server.maxPlayers)
                if playing and maxPlayers and maxPlayers > 0 then
                    return playing >= maxPlayers
                end
                return nil
            end
        end
        cursor = data.nextPageCursor
        if not cursor or cursor == "" then break end
    end
    return nil
end
local joinBusy = false
local function joinByQuery(query, onStatus)
    local function status(msg)
        if onStatus then onStatus(msg) end
        setStatus(msg)
    end
    if joinBusy then return end
    query = tostring(query or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if query == "" then
        status(joinText("Enter an ID or nickname", "Bir ID veya nick gir"))
        return
    end
    joinBusy = true
    status(joinText("Searching user...", "Kullanıcı aranıyor..."))
    local userId, reason = resolveUserId(query)
    if not userId then
        joinBusy = false
        if reason == "notfound" then
            status(joinText("User not found", "Kullanıcı bulunamadı"))
        else
            status(joinText("Could not resolve user (HTTP unsupported?)",
                "Kullanıcı çözülemedi (HTTP desteklenmiyor olabilir)"))
        end
        return
    end
    if Players:GetPlayerByUserId(userId) then
        joinBusy = false
        status(joinText("You are already in the same server", "Zaten aynı sunucudasınız"))
        return
    end
    status(joinText("Checking presence...", "Presence kontrol ediliyor..."))
    local presence = getPresence(userId)
    if not presence then
        joinBusy = false
        status(joinText("Could not fetch presence (rate limit?)",
            "Presence alınamadı (rate limit olabilir)"))
        return
    end
    if presence.userPresenceType ~= 2 then
        joinBusy = false
        status(joinText("User is not in a game right now", "Oyuncu şu an oyunda değil"))
        return
    end
    local placeId = presence.placeId
    local jobId = presence.gameId
    if not jobId or not placeId then
        joinBusy = false
        status(joinText("Joins are closed (Who can join me)",
            "Join kapalı olabilir (Who can join me)"))
        return
    end
    if jobId == game.JobId and placeId == game.PlaceId then
        joinBusy = false
        status(joinText("You are already in the same server", "Zaten aynı sunucudasınız"))
        return
    end
    status(string.format(joinText("Joining user %s...", "Kullanıcının sunucusuna bağlanılıyor: %s"),
        tostring(userId)))
    -- Sunucu dolu mu? (roproxy sunucu listesinden kontrol; bulunamazsa sessizce devam)
    local fullCheck = getServerFill(placeId, jobId)
    if fullCheck then
        joinBusy = false
        status(joinText("Server is full - try again", "Sunucu dolu - tekrar dene"))
        return
    end
    -- Her deneme icin tek kullanimlik hata dinleyicisi + zaman asimi:
    -- boylece "Joining..." yazisi sonsuza kadar asili kalmaz ve "sunucu dolu" bildirilir.
    local done = false
    local failConn
    local function finish(msg)
        if done then return end
        done = true
        joinBusy = false
        if failConn then
            pcall(function() failConn:Disconnect() end)
            failConn = nil
        end
        if msg then status(msg) end
    end
    local function failureText(resultName, message)
        local name = tostring(resultName or "")
        local lower = string.lower(tostring(message or ""))
        if string.find(name, "GameFull", 1, true) or string.find(lower, "full", 1, true) then
            return joinText("Server is full - try again", "Sunucu dolu - tekrar dene")
        elseif string.find(name, "GameNotFound", 1, true) then
            return joinText("Server no longer exists", "Sunucu artık yok")
        elseif string.find(name, "Unauthorized", 1, true) then
            return joinText("Join is restricted (friends only?)", "Katılım kısıtlı (sadece arkadaşlar?)")
        end
        return joinText("Teleport failed: ", "Işınlanma hatası: ")
            .. tostring(message or resultName or "?")
    end
    pcall(function()
        failConn = TeleportService.TeleportInitFailed:Connect(function(plr, result, message)
            if plr ~= LocalPlayer or done then return end
            finish(failureText(result, message))
        end)
    end)
    local attemptOk = false
    -- Istemciden en guvenilir yol: belirli sunucuya TeleportToPlaceInstance
    attemptOk = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
    end)
    -- Yedek yol: TeleportAsync + TeleportOptions.ServerInstanceId
    if not attemptOk and type(TeleportService.TeleportAsync) == "function" then
        attemptOk = pcall(function()
            local options = Instance.new("TeleportOptions")
            options.ServerInstanceId = jobId
            TeleportService:TeleportAsync(placeId, { LocalPlayer }, options)
        end)
    end
    if not attemptOk then
        finish(joinText("Teleport request rejected", "Işınlanma isteği reddedildi"))
        return
    end
    status(string.format(joinText("Joining user %s... waiting for server",
        "Bağlanılıyor: %s ... sunucu yanıtı bekleniyor"), tostring(userId)))
    -- 10 sn icinde hedef sunucuya gecmediysek: sunucu dolu / yanit vermiyor
    task.delay(10, function()
        if done then return end
        if game.JobId ~= jobId or game.PlaceId ~= placeId then
            finish(joinText("No response - server may be full", "Yanıt yok - sunucu dolu olabilir"))
        else
            -- artik hedef sunucudayiz, isinlanma gerceklesti
            finish()
        end
    end)
end
local ui = {}
setStatus = function(msg)
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
local flingShortBtn, shootShortBtn, rolesPanel, murdererRow, sheriffRow
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
local function shortcutButton(label, yOff)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(96, 38),
        Position = UDim2.new(1, -16, 1, yOff),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = C.red,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = label,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = C.white,
        Visible = false,
        Parent = screenGui,
    })
    corner(b, 8)
    stroke(b, C.red, 1.5, 0.4)
    return b
end
flingShortBtn = shortcutButton("Fling", -16)
shootShortBtn = shortcutButton("Shoot", -62)
flingShortBtn.MouseButton1Click:Connect(function() flingCurrent() end)
shootShortBtn.MouseButton1Click:Connect(function() task.spawn(shootMurderer) end)
local thumbCache = {}
local function avatarImage(userId)
    if thumbCache[userId] then return thumbCache[userId] end
    local ok, content = pcall(function()
        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)
    if ok and content then
        thumbCache[userId] = content
        return content
    end
    return nil
end
rolesPanel = new("Frame", {
    Size = UDim2.fromOffset(180, 62),
    Position = UDim2.new(1, -16, 1, -112),
    AnchorPoint = Vector2.new(1, 1),
    BackgroundColor3 = C.window,
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    Visible = false,
    Parent = screenGui,
})
corner(rolesPanel, 8)
stroke(rolesPanel, C.red, 1, 0.6)
local function roleRow(y)
    local row = new("Frame", {
        Size = UDim2.new(1, -16, 0, 26),
        Position = UDim2.fromOffset(8, y),
        BackgroundTransparency = 1,
        Parent = rolesPanel,
    })
    local img = new("ImageLabel", {
        Size = UDim2.fromOffset(22, 22),
        Position = UDim2.fromOffset(0, 2),
        BackgroundColor3 = C.darker,
        BorderSizePixel = 0,
        Image = "",
        Parent = row,
    })
    corner(img, 11)
    local name = makeText(row, {
        Position = UDim2.fromOffset(30, 0),
        Size = UDim2.new(1, -30, 1, 0),
        Text = "—",
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextColor3 = C.textDim,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    return { row = row, img = img, name = name }
end
murdererRow = roleRow(6)
sheriffRow = roleRow(34)
local sidebar = new("Frame", {
    Size = UDim2.new(0, SIDEBAR_W, 1, 0),
    BackgroundColor3 = C.sidebar,
    BorderSizePixel = 0,
    Parent = window,
})
corner(sidebar, 10)
new("Frame", {
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
local footer = new("Frame", {
    Size = UDim2.new(1, -20, 0, 78),
    Position = UDim2.new(0, 10, 1, -10),
    AnchorPoint = Vector2.new(0, 1),
    BackgroundTransparency = 1,
    Parent = sidebar,
})
ui.footer = footer
new("Frame", {
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
local main = new("Frame", {
    Size = UDim2.new(1, -SIDEBAR_W, 1, 0),
    Position = UDim2.fromOffset(SIDEBAR_W, 0),
    BackgroundTransparency = 1,
    Parent = window,
})
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
new("Frame", {
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
local CARD_H = {
    toggle = 54,
    select = 62,
    keybind = 40,
    keybind_button = 60,
    action = 40,
    section = 22,
    join_player = 96,
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
    local height = item.desc and 52 or CARD_H.keybind
    local holder, card = baseCard(parent, fullWidth and 1 or 0.5, height)
    makeText(card, {
        Position = UDim2.fromOffset(10, 7),
        Size = UDim2.new(1, -60, 0, 15),
        Text = t(item.label),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = C.text,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    if item.desc then
        makeText(card, {
            Position = UDim2.fromOffset(10, 26),
            Size = UDim2.new(1, -60, 0, 13),
            Text = t(item.desc),
            TextSize = 9,
            TextColor3 = C.textFaint,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
    end
    local keyBtn = new("TextButton", {
        Size = UDim2.fromOffset(34, 18),
        Position = UDim2.new(1, -10, 0, 9),
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
        if item.id == "fling_all" then
            btnText.Text = "✓"
            task.delay(0.75, function()
                if btnText and btnText.Parent then btnText.Text = t(item.btn) end
            end)
            flingAll()
            return
        end
        local emoteHandled = false
        local actionOk = true
        if item.id == "emote_zen" then
            emoteHandled = true
            actionOk = playEmote("Zen")
        elseif item.id == "emote_floss" then
            emoteHandled = true
            actionOk = playEmote("Floss")
        elseif item.id == "emote_hump" then
            emoteHandled = true
            actionOk = playPartnerEmote("Hump")
        elseif item.id == "emote_hand" then
            emoteHandled = true
            actionOk = playPartnerEmote("Hand")
        elseif item.id == "emote_kick" then
            emoteHandled = true
            actionOk = playPartnerEmote("Kick")
        elseif item.id == "save_config" then
            saveConfig()
        elseif item.id == "shoot_now" then
            task.spawn(shootMurderer)
        end
        btnText.Text = actionOk and "✓" or "✕"
        -- Emote fonksiyonlari kendi durum mesajini yazar; burada ezilmemeli
        if not emoteHandled then
            setStatus(string.format("%s %s", t(item.label), UITEXT[currentLang].executed))
        end
        task.delay(0.75, function()
            if btnText and btnText.Parent then btnText.Text = t(item.btn) end
        end)
    end)
    return holder
end
local function playerDropdown(item, parent, cardH, listH, onPick)
    local isOpen = item.dropdownOpen
    local playerList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(playerList, p) end
    end
    table.sort(playerList, function(a, b) return string.lower(a.Name) < string.lower(b.Name) end)
    local cols = 3
    local holder, card = baseCard(parent, 1, cardH)
    padding(card, 10, 10, 10, 10)
    new("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = card,
    })
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
    makeText(dropBtn, {
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
        new("UIGridLayout", {
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
                onPick(plr)
                renderContent()
            end)
        end
    end
    return holder, card
end
local function buildPlayerFling(item, parent)
    local isOpen = item.dropdownOpen
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then count = count + 1 end end
    local listH = isOpen and (math.max(1, math.ceil(count / 3)) * 30 + 4) or 0
    local cardH = 10 + 32 + 8 + (isOpen and (listH + 8) or 0) + 28 + 10
    local holder, card = playerDropdown(item, parent, cardH, listH, function(plr)
        state.selectedPlayer = plr
        setStatus(plr.Name .. " " .. UITEXT[currentLang].autoFlung)
    end)
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
        flingCurrent()
    end)
    return holder
end
local function buildPlayerSelect(item, parent)
    local isOpen = item.dropdownOpen
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then count = count + 1 end end
    local listH = isOpen and (math.max(1, math.ceil(count / 3)) * 30 + 4) or 0
    local cardH = 10 + 32 + 8 + (isOpen and (listH + 8) or 0) + 10
    local holder = playerDropdown(item, parent, cardH, listH, function(plr)
        state.emotePlayer = plr
        setStatus(plr.Name .. " " .. UITEXT[currentLang].autoFlung)
    end)
    return holder
end
local function buildJoinPlayer(item, parent)
    local holder, card = baseCard(parent, nil, CARD_H.join_player)
    padding(card, 10, 10, 8, 8)
    makeText(card, {
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -90, 0, 15),
        Text = t(item.label),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = C.text,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    makeText(card, {
        Position = UDim2.fromOffset(0, 16),
        Size = UDim2.new(1, 0, 0, 13),
        Text = t(item.desc or ""),
        TextSize = 9,
        TextColor3 = C.textFaint,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    local inputBox = new("TextBox", {
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, -86, 0, 28),
        BackgroundColor3 = C.darker,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.text,
        PlaceholderColor3 = C.textFaint,
        PlaceholderText = t(item.placeholder or ""),
        Text = item.input or "",
        ClearTextOnFocus = false,
        Parent = card,
    })
    corner(inputBox, 6)
    stroke(inputBox, C.border, 1, 0)
    padding(inputBox, 8, 8, 0, 0)
    local joinBtn = new("TextButton", {
        Position = UDim2.new(1, -78, 0, 34),
        Size = UDim2.fromOffset(78, 28),
        BackgroundColor3 = C.red,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = card,
    })
    corner(joinBtn, 6)
    makeText(joinBtn, {
        Size = UDim2.fromScale(1, 1),
        Text = t(item.btn),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = C.white,
    })
    local statusLabel = makeText(card, {
        Position = UDim2.fromOffset(0, 68),
        Size = UDim2.new(1, 0, 0, 14),
        Text = item.joinStatus or "",
        TextSize = 9,
        TextColor3 = item.joinStatus and Color3.fromRGB(252, 165, 165) or C.textFaint,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    local function pushStatus(msg)
        item.joinStatus = msg
        if statusLabel.Parent then
            statusLabel.Text = msg
            statusLabel.TextColor3 = Color3.fromRGB(252, 165, 165)
        end
    end
    local function attemptJoin()
        if joinBusy then
            pushStatus(joinText("Please wait, joining...", "Bekle, bağlanılıyor..."))
            return
        end
        pushStatus(joinText("Searching user...", "Kullanıcı aranıyor..."))
        task.spawn(function()
            joinByQuery(inputBox.Text, pushStatus)
        end)
    end
    inputBox:GetPropertyChangedSignal("Text"):Connect(function()
        item.input = inputBox.Text
    end)
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then attemptJoin() end
    end)
    joinBtn.MouseButton1Click:Connect(attemptJoin)
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
    new("Frame", {
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
local function buildCard(item, parent, width)
    if item.type == "toggle" then return buildToggle(item, parent, width)
    elseif item.type == "select" then return buildSelect(item, parent, width)
    elseif item.type == "keybind" then return buildKeybind(item, parent, width ~= nil)
    elseif item.type == "keybind_button" then return buildKeybindButton(item, parent, width)
    elseif item.type == "action" then return buildAction(item, parent, width)
    elseif item.type == "section" then return buildSection(item, parent)
    elseif item.type == "player_fling" then return buildPlayerFling(item, parent)
    elseif item.type == "player_select" then return buildPlayerSelect(item, parent)
    elseif item.type == "join_player" then return buildJoinPlayer(item, parent)
    end
    return nil
end
renderContent = function()
    local tab
    for _, tb in ipairs(tabs) do
        if tb.id == currentTab then tab = tb break end
    end
    if not tab then return end
    ui.title.Text = tab.id
    ui.badge.Text = t(tab.badge)
    for _, ch in ipairs(ui.contentScroll:GetChildren()) do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
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
    elseif feature == "shortcutFling" and flingShortBtn then
        flingShortBtn.Visible = value
    elseif feature == "shortcutShoot" and shootShortBtn then
        shootShortBtn.Visible = value
    elseif feature == "showRoles" and rolesPanel then
        rolesPanel.Visible = value
    end
end
local function applyUiFlags()
    if flingShortBtn then flingShortBtn.Visible = flags.shortcutFling == true end
    if shootShortBtn then shootShortBtn.Visible = flags.shortcutShoot == true end
    if rolesPanel then rolesPanel.Visible = flags.showRoles == true end
end
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
local dragging, dragStart, startPos
local function makeDraggable(frame)
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if conn then conn:Disconnect() end
                end
            end)
        end
    end)
end
makeDraggable(window)
makeDraggable(stage)
makeDraggable(header)
makeDraggable(headerLine)
makeDraggable(brandLine)
makeDraggable(sidebar)
makeDraggable(brand)
makeDraggable(tabList)
UserInputService.InputChanged:Connect(function(input)
    if dragging and not UserInputService:GetFocusedTextBox() then
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if delta.Magnitude > 2 then
                window.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end
end)
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
        flingCurrent()
    elseif item.id == "shoot_keybind" then
        task.spawn(shootMurderer)
    elseif item.id == "emote_stop" then
        stopEmotes()
        setStatus(string.format("%s %s", t(item.label), UITEXT[currentLang].executed))
    end
    updateActiveCount()
    renderTabs()
    renderContent()
end
UserInputService.InputBegan:Connect(function(input, gpe)
    if ui.waitingKey and input.UserInputType == Enum.UserInputType.Keyboard then
        local keyName = input.KeyCode.Name
        local fn = ui.waitingKey
        ui.waitingKey = nil
        fn(keyName)
        return
    end
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
task.spawn(function()
    while true do
        task.wait(0.25)
        if flags.vision then
            updateHighlights()
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(1)
        if flags.showRoles and rolesPanel then
            local mur, shf
            for _, plr in ipairs(Players:GetPlayers()) do
                local r = getRole(plr)
                if r == "Murderer" then mur = plr
                elseif r == "Sheriff" then shf = plr end
            end
            if mur then
                murdererRow.name.Text = mur.Name
                murdererRow.name.TextColor3 = ROLE_COLORS.Murderer
                local img = avatarImage(mur.UserId)
                murdererRow.img.Image = img or ""
            else
                murdererRow.name.Text = "—"
                murdererRow.name.TextColor3 = C.textFaint
                murdererRow.img.Image = ""
            end
            if shf then
                sheriffRow.name.Text = shf.Name
                sheriffRow.name.TextColor3 = ROLE_COLORS.Sheriff
                local img = avatarImage(shf.UserId)
                sheriffRow.img.Image = img or ""
            else
                sheriffRow.name.Text = "—"
                sheriffRow.name.TextColor3 = C.textFaint
                sheriffRow.img.Image = ""
            end
        end
    end
end)
local hidden = false
local hideCF = CFrame.new(0, -60, 0)
local touchConn
local function setupTouchFling()
    if touchConn then touchConn:Disconnect() end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    touchConn = hrp.Touched:Connect(function(hit)
        if not flags.touchFling then return end
        local model = hit:FindFirstAncestorOfClass("Model") or hit.Parent
        if model and model ~= char then
            local plr = Players:GetPlayerFromCharacter(model)
            if plr and plr ~= LocalPlayer then
                tryFling(plr)
            end
        end
    end)
end
LocalPlayer.CharacterAdded:Connect(function()
    hidden = false
    stopProcedural()
    task.wait(1)
    setupTouchFling()
end)
task.spawn(setupTouchFling)
local walkAccum = 0
local orbitAngle = 0
local tbagClock = 0
RunService.Heartbeat:Connect(function(dt)
    local hrp = getHRP()
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
    if flags.walkFling and hrp and not hidden then
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
    if flags.orbit and hrp and not hidden then
        local target = getTargetPlayer(true, true)
        local thrp = target and getHRP(target)
        if thrp then
            orbitAngle = orbitAngle + dt * 3
            local offset = CFrame.new(math.cos(orbitAngle) * 6, 2, math.sin(orbitAngle) * 6)
            hrp.CFrame = thrp.CFrame * offset
            hrp.AssemblyLinearVelocity = Vector3.new()
        end
    end
    if flags.tbag and not flags.orbit and hrp and not hidden then
        local target = getTargetPlayer(true, true)
        local thrp = target and getHRP(target)
        if thrp then
            tbagClock = tbagClock + dt
            local wiggle = math.abs(math.sin(tbagClock * 10)) * 1.6
            hrp.CFrame = thrp.CFrame * CFrame.new(0, 0.5 - wiggle, 3)
            hrp.AssemblyLinearVelocity = Vector3.new()
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(0.12)
        if flags.farm and not hidden then
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
task.spawn(function()
    while true do
        task.wait(0.8)
        if flags.farmBag and getCoinCount() >= FULL_BAG then
            local murderer = findMurderer()
            if murderer then tryFling(murderer) end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(0.35)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if char and hum and hum.Health > 0 and hrp then
            refreshRoundState()
            local role = getRole(LocalPlayer)
            if flags.xpHide and role == "Innocent" then
                if not hidden then
                    hidden = true
                    hideCF = CFrame.new(hrp.Position.X, -60, hrp.Position.Z)
                    hrp.AssemblyLinearVelocity = Vector3.new()
                    hrp.AssemblyAngularVelocity = Vector3.new()
                    hrp.CFrame = hideCF
                    hrp.Anchored = true
                end
            else
                if hidden then
                    hidden = false
                    if hrp and hrp.Parent then hrp.Anchored = false end
                end
            end
            if flags.xpKillAll and role == "Murderer" and hrp and not hidden then
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
            if flags.xpShoot and hrp and not hidden then
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
task.spawn(function()
    while true do
        task.wait(0.5)
        if flags.autoGun and not hidden then
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
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchQuery = string.lower(searchBox.Text)
    renderContent()
end)
resetBtn.MouseButton1Click:Connect(function()
    tabs = defaultTabs()
    flags = defaultFlags()
    state.selectedPlayer = nil
    state.emotePlayer = nil
    searchQuery = ""
    searchBox.Text = ""
    clearHighlights()
    stopEmotes()
    if hidden then
        local hrp = getHRP()
        if hrp then hrp.Anchored = false end
        hidden = false
    end
    applyUiFlags()
    rebuildKeybindCache()
    setStatus(UITEXT[currentLang].resetDone)
    renderAll()
end)
rebuildKeybindCache()
renderAll()
applyUiFlags()
setStatus(UITEXT[currentLang].themeActive)
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
        applyUiFlags()
    end
end)
