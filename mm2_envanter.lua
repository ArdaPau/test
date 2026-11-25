--[[
  mm2_envanter.lua — MM2 envanterini EKRAN OKUMADAN, executor içinden okur.

  Nasıl çalışır:
    1) VERİ MODU: MM2'nin yerel eşya veritabanını (Database.Sync / GetSyncData) yükler,
       oyunun envanter/profil RemoteFunction'ını (GetProfileData / GetFullInventory vb.) bulur
       ve envanteri doğrudan sunucu verisinden okur. Menü açmaz, tıklama/piksel yok.
    2) GUI MODU (isteğe bağlı yedek, varsayılan kapalı): veri modu bulunamazsa ve gui_modu=true
       yapılırsa oyuncu profilini GUI nesneleri üzerinden okur.
    3) Masaüstündeki bot (bot.py) HTTP / HTTPS tünel köprüsü üzerinden iş verir.
       Ek olarak oyun içi sohbete "/inv nick" yazınca da okur.

  Kullanım (Delta / GitHub):
    _G.MM2_URL = "https://....trycloudflare.com"
    loadstring(game:HttpGet("RAW_LINK"))()

  Konsol API'si:
    MM2_ENVANTER.oku("nick")     -> eşya listesi (tablo)
    MM2_ENVANTER.yazdir("nick")  -> özeti konsola bas
    MM2_ENVANTER.teshis()        -> bulunan remote/veritabanı/GUI yapısını dök
    MM2_ENVANTER.durdur()        -> döngüyü kapat

  Eşya biçimi: {name="Luger", rarity="godly", chroma=false, pet=false, qty=1}
]]

if _G.MM2_ENVANTER and _G.MM2_ENVANTER.durdur then pcall(_G.MM2_ENVANTER.durdur) end

local AYAR = {
    port = 8765,            -- bot.py'deki bridge_port ile aynı olmalı
    host = nil,             -- nil: emülatör için 10.0.2.2, sonra 127.0.0.1 denenir; PC'nin LAN IP'si de yazılabilir
    url = _G.MM2_URL,       -- HTTPS tünel için (ör. "https://xxx.trycloudflare.com"); _G.MM2_URL ile de verilebilir
    ad = nil,               -- script adı; nil = yerel oyuncunun adı
    chat_komut = "/inv",    -- oyun içi komut
    veri_modu = true,       -- oyunun kendi verisinden (remote) doğrudan oku
    gui_modu = false,       -- kapalı: ekranda profil/GUI açmaz; yedek gerekirse true yapılabilir
    veri_suresi = 15,       -- ilk remote keşfi için saniye bütçesi
    kaydirma_bekle = 0.2,   -- GUI modunda her kaydırmadan sonra bekleme
    kaydirma_deneme = 60,   -- en fazla kaç kaydırma
    poll_araligi = 0.4,     -- bot köprüsünü yoklama aralığı
    ayrinti = true,         -- konsola bilgi yaz
}

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Yerel = Players.LocalPlayer
local AD = AYAR.ad or (Yerel and Yerel.Name) or "script"
local SURUM = "script-v3"

local function yaz(...)
    if AYAR.ayrinti then print("[mm2-envanter]", ...) end
end

-- ===== 2) KÖPRÜ (HTTP / HTTPS TÜNEL) =====================================
local http = (syn and syn.request) or (http and http.request) or http_request or request

local ADRESLER = { "10.0.2.2", "127.0.0.1" }
if AYAR.url and AYAR.url ~= "" then ADRESLER = { AYAR.url }
elseif AYAR.host then ADRESLER = { AYAR.host, "127.0.0.1" } end
local aktif_adres = nil

local function adres_etiket(adres)
    if type(adres) == "string" and adres:match("^https?://") then return adres end
    return ("%s:%d"):format(tostring(adres), AYAR.port)
end

local function tek_adres(adres, yol, govde)
    if not http then return nil end
    local tam_url = (adres:match("^https?://") and (adres:gsub("/+$", "") .. yol))
        or ("http://%s:%d%s"):format(adres, AYAR.port, yol)
    local ok, cevap = pcall(http, {
        Url = tam_url,
        Method = govde and "POST" or "GET",
        Headers = { ["Content-Type"] = "application/json" },
        Body = govde and HttpService:JSONEncode(govde) or nil,
    })
    if not ok or type(cevap) ~= "table" then return nil end
    if (cevap.StatusCode or 0) ~= 200 then return nil end
    local ok2, veri = pcall(HttpService.JSONDecode, HttpService, cevap.Body or "")
    return ok2 and veri or {}
end

local function kopru(yol, govde)
    if aktif_adres then
        local cevap = tek_adres(aktif_adres, yol, govde)
        if cevap then return cevap end
        aktif_adres = nil
    end
    for _, adres in ipairs(ADRESLER) do
        local cevap = tek_adres(adres, yol, govde)
        if cevap then
            if aktif_adres ~= adres then
                aktif_adres = adres
                yaz("bot adresi: " .. adres_etiket(adres))
            end
            return cevap
        end
    end
    return nil
end

local function logla(mesaj)
    yaz(mesaj)
    pcall(kopru, "/log", { name = AD, msg = tostring(mesaj) })
end

local function ad_kodla(metin)
    return (HttpService:UrlEncode(metin))
end

-- ===== 3) ORTAK YARDIMCILAR ==============================================
local RARITY = {
    common = true, uncommon = true, rare = true, legendary = true, godly = true,
    ancient = true, unique = true, vintage = true, chroma = true, misc = true,
}
local RARITY_ESLEME = {
    godly = "godly", ancient = "ancient", legendary = "legendary", rare = "rare",
    uncommon = "uncommon", common = "common", unique = "unique", vintage = "vintage",
    chroma = "chroma", pet = "pet", godlys = "godly", legendarys = "legendary",
    classic = "vintage",
}

local function nadirlik_duzelt(deger)
    if type(deger) ~= "string" then return nil end
    local s = deger:lower():gsub("^%s+", ""):gsub("%s+$", "")
    return RARITY_ESLEME[s] or (RARITY[s] and s or nil)
end

local function metin_temiz(deger)
    return type(deger) == "string" and (deger:gsub("^%s+", ""):gsub("%s+$", "")) or nil
end

local function chroma_ayir(ad)
    if type(ad) ~= "string" then return nil, false end
    local temiz = ad:gsub("^%s+", ""):gsub("%s+$", "")
    if temiz:match("^[Cc]hroma%s+") then return (temiz:gsub("^[Cc]hroma%s+", "")), true end
    return temiz, false
end

local function birlestir(liste)
    local harita, sira = {}, {}
    for _, e in ipairs(liste or {}) do
        if type(e) == "table" and type(e.name) == "string" and e.name ~= "" then
            local rar = e.rarity or "misc"
            local chr = e.chroma == true
            local pet = e.pet == true
            local anahtar = ("%s|%s|%s|%s"):format(e.name:lower(), rar, tostring(chr), tostring(pet))
            local v = harita[anahtar]
            if v then
                v.qty = v.qty + (e.qty or 1)
            else
                harita[anahtar] = { name = e.name, rarity = rar, chroma = chr, pet = pet, qty = e.qty or 1 }
                sira[#sira + 1] = harita[anahtar]
            end
        end
    end
    table.sort(sira, function(a, b)
        if a.pet ~= b.pet then return not a.pet end
        if a.rarity ~= b.rarity then return a.rarity < b.rarity end
        return a.name < b.name
    end)
    return sira
end

local function oyuncu_bul(nick)
    if type(nick) ~= "string" or nick == "" then return nil end
    local hedef = nick:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == hedef or (p.DisplayName and p.DisplayName:lower() == hedef) then return p end
    end
    return nil
end

local function bekle(kosul, saniye)
    local bitis = os.clock() + (saniye or 1)
    while os.clock() < bitis do
        local sonuc = kosul()
        if sonuc then return sonuc end
        task.wait(0.1)
    end
    return nil
end

-- ===== 4) VERİ MODU: MM2 veritabanı + sunucu envanter tablosu ============
local VERI = { uzak = nil, arg = nil, son_rapor = "" }
local DB = { yuklendi = false, yukleniyor = false, silah = {}, pet = {}, silah_n = 0, pet_n = 0 }

-- Zaman aşımlı RemoteFunction çağrısı: cevap vermeyen remote scripti dondurmaz.
local function cagir(uzak, arglar, zaman_asimi)
    local bitti, sonuc = false, nil
    task.spawn(function()
        local ok, res = pcall(function() return uzak:InvokeServer(table.unpack(arglar)) end)
        if ok then sonuc = res end
        bitti = true
    end)
    local bitis = os.clock() + (zaman_asimi or 1.8)
    while not bitti and os.clock() < bitis do task.wait(0.05) end
    if not bitti then return nil, true end
    return sonuc, false
end

local function db_ekle(tablo, pet_mi)
    if type(tablo) ~= "table" then return 0 end
    local eklenen = 0
    for id, bilgi in pairs(tablo) do
        if type(id) == "string" and type(bilgi) == "table" then
            local ham_ad = bilgi.ItemName or bilgi.Name or bilgi.DisplayName
            local rar = nadirlik_duzelt(bilgi.Rarity or bilgi.RarityName or bilgi.Tier)
            if (type(ham_ad) == "string" and #ham_ad >= 1) or rar then
                local ad_ham = (type(ham_ad) == "string" and ham_ad ~= "") and ham_ad or id
                local temiz, ad_chroma = chroma_ayir(ad_ham)
                local id_k = id:lower()
                local chroma = ad_chroma or bilgi.Chroma == true or bilgi.IsChroma == true
                    or id_k:find("chroma", 1, true) ~= nil
                local itype = type(bilgi.ItemType) == "string" and bilgi.ItemType:lower() or nil
                local bu_pet = pet_mi or itype == "pet" or bilgi.Pet == true or bilgi.IsPet == true
                local hedef = bu_pet and DB.pet or DB.silah
                if not hedef[id_k] then
                    hedef[id_k] = {
                        name = temiz,
                        rarity = rar or "misc",
                        chroma = chroma,
                        pet = bu_pet,
                    }
                    eklenen = eklenen + 1
                end
            end
        end
    end
    return eklenen
end

-- MM2 istemcisindeki eşya/pet veritabanını (ItemID -> görünen ad + nadirlik) yükler
local function db_yukle()
    if DB.yuklendi then return end
    if DB.yukleniyor then
        local bitis = os.clock() + 4
        while DB.yukleniyor and os.clock() < bitis do task.wait(0.05) end
        return
    end
    DB.yukleniyor = true
    local kokler = {}
    for _, ad in ipairs({ "Database", "Modules" }) do
        local k = ReplicatedStorage:FindFirstChild(ad)
        if k then kokler[#kokler + 1] = k end
    end
    for _, kok in ipairs(kokler) do
        for _, d in ipairs(kok:GetDescendants()) do
            if d:IsA("ModuleScript") then
                local ad = d.Name:lower()
                if ad == "item" or ad == "items" or ad == "weapon" or ad == "weapons"
                    or ad == "pet" or ad == "pets" or ad == "sync" or ad == "itemdatabase" then
                    local ok, veri = pcall(require, d)
                    if ok and type(veri) == "table" then
                        if ad == "sync" then
                            DB.silah_n = DB.silah_n + db_ekle(veri.Item or veri.Items or veri.Weapons, false)
                            DB.pet_n = DB.pet_n + db_ekle(veri.Pets or veri.Pet, true)
                        elseif ad == "pet" or ad == "pets" then
                            DB.pet_n = DB.pet_n + db_ekle(veri, true)
                        else
                            DB.silah_n = DB.silah_n + db_ekle(veri, false)
                        end
                    end
                end
            end
        end
    end
    -- Modüllerden dolmadıysa MM2'nin GetSyncData remote'u ile dene
    if DB.silah_n == 0 or DB.pet_n == 0 then
        for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
            if d:IsA("RemoteFunction") and d.Name:lower():find("syncdata", 1, true) then
                if DB.silah_n == 0 then
                    local v = cagir(d, { "Item" }, 2)
                    if type(v) == "table" then
                        local n = db_ekle(v, false)
                        if n == 0 and type(v.Item) == "table" then n = db_ekle(v.Item, false) end
                        DB.silah_n = DB.silah_n + n
                    end
                end
                if DB.pet_n == 0 then
                    local v = cagir(d, { "Pets" }, 2)
                    if type(v) == "table" then
                        local n = db_ekle(v, true)
                        if n == 0 and type(v.Pets) == "table" then n = db_ekle(v.Pets, true) end
                        DB.pet_n = DB.pet_n + n
                    end
                end
                break
            end
        end
    end
    DB.yuklendi = true
    DB.yukleniyor = false
    if DB.silah_n > 0 or DB.pet_n > 0 then
        logla(("MM2 veritabanı yüklendi: %d silah, %d pet"):format(DB.silah_n, DB.pet_n))
    end
end

local function db_bul(id, pet_tercih)
    if type(id) ~= "string" then return nil end
    local k = id:lower()
    if pet_tercih then return DB.pet[k] or DB.silah[k] end
    return DB.silah[k] or DB.pet[k]
end

local AD_ALAN = { "Name", "ItemName", "name", "itemName", "Item", "Id", "id" }
local NADIRLIK_ALAN = { "Rarity", "rarity", "RarityName", "rarityName", "Tier", "tier", "Quality" }
local ADET_ALAN = { "Amount", "amount", "Count", "count", "Quantity", "quantity", "Qty", "qty",
                    "Copies", "Duplicates", "Stack", "stack" }

-- Silah/pet dışındaki kozmetik ve donanım alt dallarını atla (çift sayım ve çöp önlenir)
local ATLA_DAL = {
    equipped = true, equip = true, radios = true, radio = true,
    effects = true, effect = true, emotes = true, emote = true,
    perks = true, perk = true, toys = true, toy = true,
    powers = true, power = true, badges = true, codes = true,
    settings = true, stats = true, achievements = true, quests = true,
    battlepass = true, shop = true, boxes = true, salvage = true,
    materials = true, recipes = true, passes = true, gamepasses = true,
}

-- Sayısal oyuncu istatistikleri eşya sanılmasın
local ISTATISTIK_YASAK = {
    coins = true, gems = true, xp = true, exp = true, level = true, prestige = true,
    elite = true, kills = true, wins = true, murders = true, deaths = true, cash = true,
    gold = true, tokens = true, candies = true, snowtokens = true, eggs = true,
    beachballs = true, time = true, timestamp = true, userid = true, id = true,
    version = true, count = true, total = true, max = true, slots = true,
    capacity = true, rank = true, score = true, tier = true, season = true,
    pass = true, tierlevel = true, daily = true, streak = true, lastlogin = true,
    joined = true, playtime = true, rounds = true, innocent = true, sheriff = true,
    murderer = true, hero = true,
}

local function alan_bul(tablo, alanlar, tip)
    for _, k in ipairs(alanlar) do
        local v = tablo[k]
        if tip == nil or type(v) == tip then
            if v ~= nil and v ~= "" then return v end
        end
    end
    return nil
end

local function nadirlik_alani(tablo)
    for _, k in ipairs(NADIRLIK_ALAN) do
        local v = tablo[k]
        if type(v) == "string" and v ~= "" then return v end
        if type(v) == "table" then
            local ic = v.Name or v.name or v.Value or v.value
            if type(ic) == "string" and ic ~= "" then return ic end
        end
    end
    return nil
end

local function esya_mi(tablo)
    if type(tablo) ~= "table" then return false end
    local ad = alan_bul(tablo, AD_ALAN, "string")
    if not ad or #ad < 2 then return false end
    return nadirlik_alani(tablo) ~= nil or alan_bul(tablo, ADET_ALAN, "number") ~= nil
        or tablo.Chroma == true or tablo.Pet == true or tablo.IsPet == true
end

local function envanter_baglami(baglam)
    return baglam:find("weapon", 1, true) ~= nil
        or baglam:find("pet", 1, true) ~= nil
        or baglam:find("knife", 1, true) ~= nil
        or baglam:find("gun", 1, true) ~= nil
        or baglam:find("owned", 1, true) ~= nil
        or baglam:find("inv", 1, true) ~= nil
        or baglam:find("item", 1, true) ~= nil
end

local function varsayilan_ad_duzelt(id)
    if id == "DefaultKnife" then return "Default Knife" end
    if id == "DefaultGun" then return "Default Gun" end
    return id
end

local function id_ekle(cikti, id, adet, pet_baglam)
    local kayit = db_bul(id, pet_baglam)
    if kayit then
        cikti[#cikti + 1] = {
            name = kayit.name,
            rarity = kayit.rarity,
            chroma = kayit.chroma,
            pet = pet_baglam or kayit.pet,
            qty = math.max(math.floor(adet), 1),
        }
        return true
    end
    local temiz, ad_chroma = chroma_ayir(varsayilan_ad_duzelt(id))
    local id_k = id:lower()
    local pet = pet_baglam
    if temiz:find("(Pet)", 1, true) then pet = true; temiz = (temiz:gsub("%s*%(Pet%)", "")) end
    cikti[#cikti + 1] = {
        name = temiz,
        rarity = "misc",
        chroma = ad_chroma or id_k:find("chroma", 1, true) ~= nil,
        pet = pet,
        qty = math.max(math.floor(adet), 1),
    }
    return true
end

-- Hem MM2'nin [ItemID] = adet haritalarını (Weapons.Owned / Pets.Owned) hem de nesne dizilerini okur.
local function topla(deger, baglam, cikti, derinlik, gorulen)
    if type(deger) ~= "table" or derinlik > 6 or gorulen[deger] then return end
    gorulen[deger] = true

    -- 1) Nesne biçimi: { Name="Luger", Rarity="Godly", Amount=2 }
    if esya_mi(deger) then
        local ham = alan_bul(deger, AD_ALAN, "string")
        local kayit = db_bul(ham, baglam:find("pet", 1, true) ~= nil)
        local ad, chroma = chroma_ayir(kayit and kayit.name or ham)
        local pet = baglam:find("pet", 1, true) ~= nil or deger.Pet == true or deger.IsPet == true
            or (kayit and kayit.pet == true) or false
        if ad:find("(Pet)", 1, true) then pet = true; ad = (ad:gsub("%s*%(Pet%)", "")) end
        local adet = alan_bul(deger, ADET_ALAN, "number") or 1
        if type(adet) == "table" then adet = 1 end
        cikti[#cikti + 1] = {
            name = ad,
            rarity = nadirlik_duzelt(nadirlik_alani(deger)) or (kayit and kayit.rarity) or "misc",
            chroma = chroma or (deger.Chroma == true or deger.IsChroma == true) or (kayit and kayit.chroma == true) or false,
            pet = pet,
            qty = math.max(math.floor(adet), 1),
        }
        return
    end

    local pet_baglam = baglam:find("pet", 1, true) ~= nil
    local env_icinde = envanter_baglami(baglam)
    local db_var = (DB.silah_n > 0 or DB.pet_n > 0)

    for k, v in pairs(deger) do
        if type(k) == "string" then
            local kk = k:lower()
            if ATLA_DAL[kk] then
                -- Kozmetik / Equipped dalını atla
            elseif type(v) == "number" then
                if v >= 1 and v < 1000000 and v == math.floor(v) and not ISTATISTIK_YASAK[kk] then
                    if db_bul(k, pet_baglam) ~= nil then
                        id_ekle(cikti, k, v, pet_baglam)
                    elseif env_icinde and (not db_var or #k >= 2) then
                        -- DB yüklenmediyse veya yeni bir eşyaysa envanter dalından yine de al
                        id_ekle(cikti, k, v, pet_baglam)
                    end
                end
            elseif v == true then
                if db_bul(k, pet_baglam) ~= nil then
                    id_ekle(cikti, k, 1, pet_baglam)
                end
            elseif type(v) == "table" then
                -- { ["Luger"] = { Amount = 2 } } gibi anahtar-ID + alt tablo biçimi
                local alt_adet = alan_bul(v, ADET_ALAN, "number")
                if alt_adet and alt_adet >= 1 and not esya_mi(v) and (db_bul(k, pet_baglam) ~= nil or env_icinde) then
                    id_ekle(cikti, k, alt_adet, pet_baglam)
                else
                    topla(v, baglam .. " " .. kk, cikti, derinlik + 1, gorulen)
                end
            end
        elseif type(k) == "number" then
            if type(v) == "table" then
                topla(v, baglam, cikti, derinlik + 1, gorulen)
            elseif type(v) == "string" and env_icinde and db_bul(v, pet_baglam) ~= nil then
                id_ekle(cikti, v, 1, pet_baglam)
            end
        end
    end
end

local function tablodan_oku(sonuc)
    local liste = {}
    if sonuc ~= nil then topla(sonuc, "", liste, 0, {}) end
    return liste
end

local function imza(liste)
    local parca = {}
    for _, e in ipairs(liste) do parca[#parca + 1] = e.name:lower() .. ":" .. e.qty end
    table.sort(parca)
    return table.concat(parca, ",")
end

local function tablo_ozet(v)
    if v == nil then return "nil" end
    if type(v) ~= "table" then return type(v) end
    local anahtarlar = {}
    for k in pairs(v) do
        anahtarlar[#anahtarlar + 1] = tostring(k)
        if #anahtarlar >= 6 then break end
    end
    return "table{" .. table.concat(anahtarlar, ",") .. "}"
end

local ON_EK = { "inv", "profile", "data", "weapon", "item", "get", "fetch", "own" }
local YASAK_REMOTE = {
    "sync", "shop", "buy", "purchase", "unbox", "crate", "box", "code", "redeem",
    "trade", "equip", "craft", "salvage", "delete", "sell", "kick", "ban", "report",
    "chat", "spin", "gift", "pass", "donate", "prompt", "setting", "mute",
    "radio", "emote", "perk", "effect", "coin", "gem", "xp", "quest", "daily",
    "leaderboard", "server", "teleport", "vote", "map", "round", "role",
}

local function remote_puani(d)
    local tam = d:GetFullName():lower()
    local ad = d.Name:lower()
    for _, y in ipairs(YASAK_REMOTE) do
        if ad:find(y, 1, true) then return -1 end
    end
    if ad:find("fullinventory", 1, true) or ad:find("profiledata", 1, true)
        or ad:find("playerprofile", 1, true) or ad:find("getinventory", 1, true)
        or ad:find("playerinventory", 1, true) then
        return 100
    end
    if ad:find("inventory", 1, true) or ad:find("profile", 1, true) then return 80 end
    if tam:find("inventory", 1, true) or tam:find("profile", 1, true) then return 70 end
    if ad:find("getdata", 1, true) or ad:find("playerdata", 1, true) then return 50 end
    for _, onek in ipairs(ON_EK) do
        if ad:find(onek, 1, true) then return 20 end
    end
    return -1
end

local function adaylar()
    local liste = {}
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d:IsA("RemoteFunction") then
            local p = remote_puani(d)
            if p >= 0 then liste[#liste + 1] = { r = d, p = p } end
        end
    end
    table.sort(liste, function(a, b)
        if a.p ~= b.p then return a.p > b.p end
        return a.r.Name < b.r.Name
    end)
    local sonuc = {}
    for _, x in ipairs(liste) do sonuc[#sonuc + 1] = x.r end
    return sonuc
end

-- MM2 öncelik sırası: GetProfileData / GetFullInventory genelde oyuncu adı (string) veya Player alır.
local ARG_ORNEKLERI = {
    function(p) return { p.Name } end,
    function(p) return { p } end,
    function(p) return { p.UserId } end,
    function(p) return { "GetInventory", p.Name } end,
    function(p) return { "GetInventory", p } end,
    function(p) return { p.Name, "Inventory" } end,
}

local function farkli_mi(uzak, ornek, hedef, hedef_imza, hedef_sayi)
    local denenecek = {}
    if hedef ~= Yerel then denenecek[#denenecek + 1] = Yerel end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= hedef and p ~= Yerel then
            denenecek[#denenecek + 1] = p
            if #denenecek >= 3 then break end
        end
    end
    if #denenecek == 0 then return hedef_sayi < 400 end
    for _, diger in ipairs(denenecek) do
        local ham = cagir(uzak, ornek(diger), 1.5)
        if ham ~= nil then
            local diger_liste = tablodan_oku(ham)
            if imza(diger_liste) ~= hedef_imza then return true end
        end
    end
    return false
end

local function veri_ogren(hedef)
    db_yukle()
    local bitis = os.clock() + AYAR.veri_suresi
    local liste_aday = adaylar()
    local rapor = { ("db=%d/%d"):format(DB.silah_n, DB.pet_n) }
    local aday_adlari = {}
    for idx = 1, math.min(#liste_aday, 8) do aday_adlari[#aday_adlari + 1] = liste_aday[idx].Name end
    rapor[#rapor + 1] = "adaylar=" .. (#aday_adlari > 0 and table.concat(aday_adlari, ",") or "yok")

    local donus_not = {}
    for _, uzak in ipairs(liste_aday) do
        for i, ornek in ipairs(ARG_ORNEKLERI) do
            if os.clock() > bitis then
                rapor[#rapor + 1] = "zaman_asimi"
                VERI.son_rapor = table.concat(rapor, " | ")
                return nil
            end
            local ham, ta = cagir(uzak, ornek(hedef), 1.5)
            if ta then
                -- Bu remote cevap vermiyor; diğer argümanlarla vakit kaybetme
                if #donus_not < 4 then donus_not[#donus_not + 1] = uzak.Name .. "(timeout)" end
                break
            end
            if ham ~= nil then
                local liste = tablodan_oku(ham)
                if #donus_not < 4 then
                    donus_not[#donus_not + 1] = ("%s(%d)->%s[%d]"):format(uzak.Name, i, tablo_ozet(ham), #liste)
                end
                if #liste > 0 then
                    local h_imza = imza(liste)
                    if farkli_mi(uzak, ornek, hedef, h_imza, #liste) then
                        VERI.uzak, VERI.arg = uzak, i
                        logla(("veri kaynağı: %s (argüman %d, %d eşya)"):format(uzak:GetFullName(), i, #liste))
                        return liste
                    end
                    break -- oyuncuya göre değişmeyen sabit tablo
                end
            end
        end
    end
    if #donus_not > 0 then rapor[#rapor + 1] = "donus=" .. table.concat(donus_not, "; ") end
    VERI.son_rapor = table.concat(rapor, " | ")
    logla("veri modu bulunamadı: " .. VERI.son_rapor)
    return nil
end

local function veri_oku(oyuncu)
    if not AYAR.veri_modu then return nil end
    db_yukle()
    if VERI.uzak then
        local ham, ta = cagir(VERI.uzak, ARG_ORNEKLERI[VERI.arg](oyuncu), 4)
        if not ta and ham ~= nil then
            local liste = tablodan_oku(ham)
            if #liste > 0 or type(ham) == "table" then return liste end
        end
        VERI.uzak, VERI.arg = nil, nil  -- kaynak artık cevap vermiyor: yeniden öğren
    end
    return veri_ogren(oyuncu)
end

-- ===== 5) GUI MODU (isteğe bağlı yedek: AYAR.gui_modu = true) ============
local NADIRLIK_RENK = {
    godly = Color3.fromRGB(253, 1, 178), ancient = Color3.fromRGB(90, 10, 235),
    legendary = Color3.fromRGB(196, 6, 9), rare = Color3.fromRGB(0, 200, 0),
    uncommon = Color3.fromRGB(1, 253, 253), common = Color3.fromRGB(100, 100, 100),
    unique = Color3.fromRGB(239, 139, 0), vintage = Color3.fromRGB(230, 200, 0),
}
local RENK_TOLERANS = 0.12

local function rar_renk_bul(renk)
    local en_iyi, en_iyi_fark = nil, RENK_TOLERANS
    if typeof(renk) ~= "Color3" then return nil end
    for ad, hedef in pairs(NADIRLIK_RENK) do
        local fark = math.max(math.abs(renk.R - hedef.R), math.abs(renk.G - hedef.G), math.abs(renk.B - hedef.B))
        if fark < en_iyi_fark then en_iyi, en_iyi_fark = ad, fark end
    end
    return en_iyi
end

local function player_gui()
    return Yerel and Yerel:FindFirstChildOfClass("PlayerGui")
end

local function gorunur(nesne)
    local kok, n = player_gui(), nesne
    while n and n ~= kok do
        if n:IsA("GuiObject") and n.Visible == false then return false end
        if n:IsA("LayerCollector") and n.Enabled == false then return false end
        n = n.Parent
    end
    return true
end

local function dugme_metni(d)
    if d:IsA("TextButton") then return metin_temiz(d.Text) end
    local et = d:FindFirstChildOfClass("TextLabel")
    return et and metin_temiz(et.Text) or nil
end

local function dugme_bul(kok, metin, tam)
    local hedef = metin:lower()
    for _, d in ipairs(kok:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and gorunur(d) then
            local yazi = dugme_metni(d)
            if yazi then
                local t = yazi:lower()
                if tam and t == hedef then return d end
                if not tam and t:find(hedef, 1, true) then return d end
            end
        end
    end
    return nil
end

local function tikla(nesne)
    if not nesne then return false end
    local oldu = false
    if firesignal then
        if pcall(firesignal, nesne.MouseButton1Click) then oldu = true end
        if pcall(firesignal, nesne.Activated) then oldu = true end
    end
    return oldu
end

local function oyuncu_satiri(oyuncu)
    local pg = player_gui()
    if not pg then return nil end
    local hedef_ad = oyuncu.Name:lower()
    local hedef_gor = (oyuncu.DisplayName or ""):lower()
    local isimler = {}
    for _, p in ipairs(Players:GetPlayers()) do
        isimler[p.Name:lower()] = true
        if p.DisplayName then isimler[p.DisplayName:lower()] = true end
    end
    local gruplar = {}
    for _, e in ipairs(pg:GetDescendants()) do
        if (e:IsA("TextLabel") or e:IsA("TextButton")) and gorunur(e) then
            local sade = (metin_temiz(e.Text) or ""):lower():gsub("^%[.-%]%s*", "")
            if isimler[sade] then
                local kap = e.Parent or e
                for _ = 1, 4 do if kap and kap.Parent then kap = kap.Parent end end
                gruplar[kap] = gruplar[kap] or { n = 0, etiket = {} }
                if not gruplar[kap].etiket[sade] then
                    gruplar[kap].n = gruplar[kap].n + 1
                    gruplar[kap].etiket[sade] = e
                end
            end
        end
    end
    local en_iyi, en_iyi_n = nil, 0
    for kap, bilgi in pairs(gruplar) do
        if bilgi.n > en_iyi_n then en_iyi, en_iyi_n = kap, bilgi.n end
    end
    if not en_iyi then return nil end
    return gruplar[en_iyi].etiket[hedef_ad] or gruplar[en_iyi].etiket[hedef_gor]
end

local function satira_tikla(etiket)
    local n = etiket
    while n and not (n:IsA("TextButton") or n:IsA("ImageButton")) do n = n.Parent end
    if n then return tikla(n) end
    if etiket.Parent and firesignal then
        pcall(firesignal, etiket.Parent.MouseButton1Click)
        pcall(firesignal, etiket.Parent.Activated)
        return true
    end
    return false
end

local KATEGORI = { "weapons", "pets", "radios", "items", "emotes", "effects", "inventory" }

local function panel_bul()
    local pg = player_gui()
    if not pg then return nil end
    local dugmeler = {}
    for _, ad in ipairs(KATEGORI) do
        local d = dugme_bul(pg, ad, true) or dugme_bul(pg, ad, false)
        if d then dugmeler[#dugmeler + 1] = d end
    end
    if #dugmeler == 0 then return nil end
    local ata = dugmeler[1]
    for _ = 1, 10 do
        if not ata.Parent then break end
        local hepsi = true
        for _, d in ipairs(dugmeler) do
            if d ~= ata and not d:IsDescendantOf(ata) then hepsi = false; break end
        end
        if hepsi then break end
        ata = ata.Parent
    end
    return ata
end

local function izgara_bul(kok)
    local en_iyi, en_iyi_puan = nil, 0
    for _, d in ipairs(kok:GetDescendants()) do
        if (d:IsA("ScrollingFrame") or d:IsA("Frame")) and gorunur(d) then
            local hucre, yazi = 0, 0
            for _, c in ipairs(d:GetChildren()) do
                if c:IsA("GuiObject") then
                    local n = 0
                    for _, t in ipairs(c:GetDescendants()) do
                        if t:IsA("TextLabel") and #(metin_temiz(t.Text) or "") > 1 then n = n + 1 end
                    end
                    if n > 0 then hucre = hucre + 1; yazi = yazi + n end
                end
            end
            if hucre >= 2 then
                local puan = yazi + (d:IsA("ScrollingFrame") and 50 or 0)
                if puan > en_iyi_puan then en_iyi, en_iyi_puan = d, puan end
            end
        end
    end
    return en_iyi
end

local function hucre_oku(hucre)
    local etiketler = {}
    if hucre:IsA("TextButton") or hucre:IsA("TextLabel") then etiketler[1] = hucre end
    for _, t in ipairs(hucre:GetDescendants()) do
        if t:IsA("TextLabel") and gorunur(t) then etiketler[#etiketler + 1] = t end
    end
    if #etiketler == 0 then return nil end
    local adet, chroma = 1, false
    for _, t in ipairs(etiketler) do
        local yazi = metin_temiz(t.Text) or ""
        local k = yazi:lower()
        local x1 = yazi:match("^[xX×]%s*(%d+)$")
        local x2 = yazi:match("^(%d+)%s*[xX×]$")
        if k == "chroma" then chroma = true
        elseif x1 then adet = tonumber(x1)
        elseif x2 then adet = tonumber(x2) end
    end
    local ad = ""
    for _, t in ipairs(etiketler) do
        local yazi = metin_temiz(t.Text) or ""
        local k = yazi:lower()
        local sayi = yazi:match("^[xX×]%s*%d+$") or yazi:match("^%d+%s*[xX×]$")
        if k ~= "chroma" and not sayi and k ~= "equipped" and k ~= "favorite" and #yazi > #ad then
            ad = yazi
        end
    end
    if #ad < 2 then return nil end
    local nadirlik = nil
    for _, t in ipairs(etiketler) do
        if not nadirlik and t.BackgroundTransparency < 0.6 then nadirlik = rar_renk_bul(t.BackgroundColor3) end
        if not nadirlik then
            local kontur = t:FindFirstChildOfClass("UIStroke")
            if kontur then nadirlik = rar_renk_bul(kontur.Color) end
        end
    end
    if not nadirlik and hucre.BackgroundTransparency < 0.6 then nadirlik = rar_renk_bul(hucre.BackgroundColor3) end
    local temiz, ad_chroma = chroma_ayir(ad)
    return { name = temiz, rarity = nadirlik or "misc", chroma = chroma or ad_chroma, pet = false,
             qty = math.max(adet or 1, 1) }
end

local function izgara_tara(kok, pet)
    local grid = izgara_bul(kok)
    if not grid then return {} end
    local sf = grid:IsA("ScrollingFrame") and grid or grid:FindFirstChildWhichIsA("ScrollingFrame", true)
    local harita, sira = {}, {}
    local function tara()
        local yeni = 0
        local kaydirma = sf and sf.CanvasPosition.Y or 0
        for _, c in ipairs(grid:GetChildren()) do
            if c:IsA("GuiObject") and gorunur(c) then
                local e = hucre_oku(c)
                if e then
                    e.pet = pet or e.pet
                    local icerik = c.AbsolutePosition.Y - kaydirma
                    local anahtar = ("%s|%s|%s|%d|%d"):format(e.name:lower(), e.rarity, tostring(e.chroma),
                        math.floor(icerik / 24), math.floor(c.AbsolutePosition.X / 24))
                    local eski = harita[anahtar]
                    if eski then
                        if e.qty > eski.qty then eski.qty = e.qty end
                    else
                        harita[anahtar] = e
                        sira[#sira + 1] = e
                        yeni = yeni + 1
                    end
                end
            end
        end
        return yeni
    end
    tara()
    if not sf then return sira end
    local bos = 0
    for _ = 1, AYAR.kaydirma_deneme do
        local son = math.max(sf.AbsoluteCanvasSize.Y - sf.AbsoluteSize.Y, 0)
        if sf.CanvasPosition.Y >= son - 1 then break end
        local adim = math.max(sf.AbsoluteSize.Y * 0.8, 120)
        sf.CanvasPosition = Vector2.new(sf.CanvasPosition.X, math.min(sf.CanvasPosition.Y + adim, son))
        task.wait(AYAR.kaydirma_bekle)
        if tara() == 0 then
            bos = bos + 1
            if bos >= 3 then break end
        else
            bos = 0
        end
    end
    return sira
end

local YASAK_SEKME = { weapons = true, weapon = true, pets = true, pet = true, radios = true,
                      items = true, emotes = true, effects = true, close = true, equip = true }

local function sekme_dugmeleri(ata)
    local grid = izgara_bul(ata)
    local dugmeler = {}
    for _, d in ipairs(ata:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and gorunur(d)
            and not (grid and d:IsDescendantOf(grid)) then
            local yazi = dugme_metni(d)
            if yazi and #yazi >= 3 then dugmeler[#dugmeler + 1] = d end
        end
    end
    local en_iyi, en_iyi_n = nil, 0
    for _, a in ipairs(dugmeler) do
        local grup = {}
        for _, b in ipairs(dugmeler) do
            if math.abs(a.AbsolutePosition.Y - b.AbsolutePosition.Y) < 12 then grup[#grup + 1] = b end
        end
        if #grup > en_iyi_n then en_iyi, en_iyi_n = grup, #grup end
    end
    if en_iyi_n < 2 then return {} end
    local sonuc = {}
    for _, d in ipairs(en_iyi) do
        local k = (dugme_metni(d) or ""):lower()
        if not YASAK_SEKME[k] and not k:find("close", 1, true) and not k:find("equip", 1, true) then
            sonuc[#sonuc + 1] = d
        end
    end
    table.sort(sonuc, function(a, b) return a.AbsolutePosition.X < b.AbsolutePosition.X end)
    if #sonuc < 2 then return {} end
    return sonuc
end

local function kapat(ata)
    local adaylar_k = {}
    for _, d in ipairs(ata:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and gorunur(d) then
            local k = (dugme_metni(d) or ""):lower()
            local ad = (d.Name or ""):lower()
            if k == "x" or k == "×" or k == "✕" or k == "close" or ad:find("close", 1, true) then
                adaylar_k[#adaylar_k + 1] = d
            end
        end
    end
    if adaylar_k[1] then
        tikla(adaylar_k[1]); task.wait(0.4)
        return
    end
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyDownEvent(Enum.KeyCode.Escape, false, true, game)
        vim:SendKeyUpEvent(Enum.KeyCode.Escape, false, true, game)
    end)
    task.wait(0.3)
end

local function gui_oku(oyuncu)
    if not AYAR.gui_modu then return nil, nil end
    local pg = player_gui()
    if not pg then return nil, "PlayerGui yok" end

    local etiket = oyuncu_satiri(oyuncu)
    if not etiket then
        local acici = dugme_bul(pg, "players", true) or dugme_bul(pg, "player list", false)
        if acici then tikla(acici); task.wait(0.6) end
        etiket = bekle(function() return oyuncu_satiri(oyuncu) end, 1.5)
    end
    if not etiket then return nil, oyuncu.Name .. " oyuncu listesinde bulunamadı" end
    if not satira_tikla(etiket) then return nil, "oyuncu satırına tıklanamadı" end

    local profil = bekle(function() return dugme_bul(pg, "profile", true) end, 2.5)
        or bekle(function() return dugme_bul(pg, "profile", false) end, 1)
    if not profil then return nil, "Profile butonu çıkmadı" end
    tikla(profil); task.wait(0.8)

    local ata = bekle(function() return panel_bul() end, 3)
    if not ata then return nil, "profil paneli açılmadı" end
    task.wait(0.3)

    local liste, onceki = {}, ""
    local function sayfa_ekle(pet)
        local parca = izgara_tara(ata, pet)
        if #parca == 0 then return end
        local imza_ = imza(parca)
        if imza_ == onceki then return end
        onceki = imza_
        for _, e in ipairs(parca) do liste[#liste + 1] = e end
    end

    local silah = dugme_bul(ata, "weapons", true) or dugme_bul(ata, "weapon", false)
    if silah then
        tikla(silah); task.wait(0.6)
        local sekmeler = sekme_dugmeleri(ata)
        if #sekmeler > 0 then
            for _, s in ipairs(sekmeler) do
                tikla(s); task.wait(0.5)
                sayfa_ekle(false)
            end
        else
            sayfa_ekle(false)
        end
    end

    local pet_dugme = dugme_bul(ata, "pets", true) or dugme_bul(ata, "pet", false)
    if pet_dugme then
        tikla(pet_dugme); task.wait(0.6)
        sayfa_ekle(true)
    end

    kapat(ata)
    if #liste == 0 then return nil, "envanter panelinde eşya okunamadı" end
    return birlestir(liste)
end

-- ===== 6) ROZET: sağ altta "Inv" ==========================================
local rozet_gui, rozet_etiket
local RENK_OK = Color3.fromRGB(130, 255, 150)
local RENK_BEKLE = Color3.fromRGB(255, 215, 120)
local RENK_HATA = Color3.fromRGB(255, 120, 120)

local function rozet(goster)
    if goster == false then
        pcall(function() if rozet_gui then rozet_gui:Destroy() end end)
        rozet_gui, rozet_etiket = nil, nil
        return
    end
    pcall(function()
        local pg = player_gui()
        if not pg or rozet_gui then return end
        local eski = pg:FindFirstChild("MM2EnvanterRozet")
        if eski then eski:Destroy() end
        rozet_gui = Instance.new("ScreenGui")
        rozet_gui.Name = "MM2EnvanterRozet"
        rozet_gui.ResetOnSpawn = false
        rozet_gui.IgnoreGuiInset = true
        rozet_gui.DisplayOrder = 1000
        rozet_gui.Parent = pg
        rozet_etiket = Instance.new("TextLabel")
        rozet_etiket.Size = UDim2.new(0, 134, 0, 26)
        rozet_etiket.Position = UDim2.new(1, -148, 1, -100)
        rozet_etiket.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        rozet_etiket.BackgroundTransparency = 0.15
        rozet_etiket.TextSize = 14
        rozet_etiket.Font = Enum.Font.GothamBold
        rozet_etiket.TextColor3 = RENK_OK
        rozet_etiket.Text = "Inv v3 • yüklendi"
        rozet_etiket.Parent = rozet_gui
        local kose = Instance.new("UICorner")
        kose.CornerRadius = UDim.new(0, 6)
        kose.Parent = rozet_etiket
    end)
end

local function rozet_yaz(metin, renk)
    pcall(function()
        if not rozet_etiket then return end
        rozet_etiket.Text = "Inv v3 • " .. metin
        rozet_etiket.TextColor3 = renk or RENK_OK
    end)
end

-- ===== 7) OKU ============================================================
local function oku(nick)
    local oyuncu = oyuncu_bul(nick)
    if not oyuncu then
        rozet_yaz("bulunamadı", RENK_HATA)
        return nil, ("%s sunucuda bulunamadı"):format(tostring(nick))
    end
    rozet_yaz("okuyor", RENK_BEKLE)
    local basla = os.clock()

    local esyalar = veri_oku(oyuncu)
    if esyalar and #esyalar > 0 then
        yaz(("%s: veri modu, %d çeşit, %.2f sn"):format(oyuncu.Name, #esyalar, os.clock() - basla))
        rozet_yaz("okundu")
        return birlestir(esyalar)
    end

    if AYAR.gui_modu then
        local gui_esyalar, hata = gui_oku(oyuncu)
        if gui_esyalar and #gui_esyalar > 0 then
            yaz(("%s: GUI modu, %d çeşit, %.2f sn"):format(oyuncu.Name, #gui_esyalar, os.clock() - basla))
            rozet_yaz("okundu")
            return gui_esyalar
        end
        rozet_yaz("okunamadı", RENK_HATA)
        local detay = (hata or "GUI okunamadı")
        if VERI.son_rapor ~= "" then detay = detay .. " [" .. VERI.son_rapor .. "]" end
        return nil, detay
    end

    rozet_yaz("okunamadı", RENK_HATA)
    local detay = "veri modu envanter bulamadı"
    if VERI.son_rapor ~= "" then detay = detay .. " [" .. VERI.son_rapor .. "]" end
    return nil, detay
end

-- ===== 8) OYUN İÇİ KOMUT =================================================
local calisiyor = true

local function soyle(metin)
    local olay = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    local istek = olay and olay:FindFirstChild("SayMessageRequest")
    if not istek then return end
    local tek = (metin:gsub("%s*\n%s*", " | ")):gsub("%s+", " ")
    if #tek > 190 then tek = tek:sub(1, 187) .. "..." end
    pcall(function() istek:FireServer(tek, "All") end)
end

local function komut_isle(mesaj)
    if type(mesaj) ~= "string" then return end
    local komut, nick = mesaj:match("^%s*(/%S+)%s+(%S+)")
    if not komut or komut:lower() ~= AYAR.chat_komut:lower() then return end
    task.spawn(function()
        local ok, esyalar, hata = pcall(oku, nick)
        if not ok or not esyalar then
            yaz(("hata: %s"):format(tostring((not ok and esyalar) or hata)))
            return
        end
        local cevap = kopru("/chat", { name = AD, nick = nick, items = esyalar })
        local ozet = type(cevap) == "table" and cevap.summary or nil
        if not ozet or ozet == "" then
            ozet = ("%s: %d çeşit eşya (bot kapalı: değer hesaplanmadı)"):format(nick, #esyalar)
        end
        yaz("\n" .. ozet)
        soyle(ozet)
    end)
end

local function chat_bagla()
    local olay
    pcall(function()
        olay = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 4)
    end)
    local istek = olay and olay:FindFirstChild("SayMessageRequest")
    if istek then
        istek.OnClientEvent:Connect(komut_isle)
        yaz("chat komutu hazır: " .. AYAR.chat_komut .. " <nick>")
        return
    end
    pcall(function()
        local tcs = game:GetService("TextChatService")
        local kanallar = tcs:FindFirstChild("TextChannels")
        local kanal = kanallar and kanallar:FindFirstChild("RBXGeneral")
        if not kanal then return end
        local gonderen = getmetatable(kanal).__index.SendAsync
        local yeni = function(self, metin, ...)
            if typeof(metin) == "string" then komut_isle(metin) end
            return gonderen(self, metin, ...)
        end
        if hookfunction then hookfunction(gonderen, yeni)
        elseif replaceclosure then replaceclosure(gonderen, yeni) end
        yaz("chat komutu hazır (TextChatService): " .. AYAR.chat_komut .. " <nick>")
    end)
end

-- ===== 9) BOT DÖNGÜSÜ ====================================================
local function dongu()
    local bagli = nil
    while calisiyor do
        local cevap = kopru("/poll?name=" .. ad_kodla(AD))
        if cevap == nil then
            if bagli ~= false then
                bagli = false
                rozet_yaz("bot yok", RENK_HATA)
                yaz(("bot bulunamadı (denenen adresler: %s)."):format(table.concat(ADRESLER, ", ")))
            end
        else
            if bagli ~= true then
                bagli = true
                kopru("/hello", { name = AD })
                rozet_yaz("bağlı")
                yaz("bot bağlı: " .. adres_etiket(aktif_adres))
            end
            if type(cevap) == "table" and cevap.id then
                local ok, esyalar, hata = pcall(oku, cevap.nick)
                local govde = { id = cevap.id, name = AD, chat = cevap.chat == true }
                if ok and esyalar then
                    govde.items = esyalar
                else
                    govde.error = tostring((not ok and esyalar) or hata or "envanter okunamadı")
                end
                kopru("/result", govde)
            end
        end
        task.wait(bagli == false and 2 or AYAR.poll_araligi)
    end
end

_G.MM2_ENVANTER = {
    ayar = AYAR,
    oku = oku,
    yazdir = function(nick)
        local esyalar, hata = oku(nick)
        if not esyalar then yaz("hata: " .. tostring(hata)); return end
        local satirlar = {}
        for _, e in ipairs(esyalar) do
            satirlar[#satirlar + 1] = ("%dx %s [%s]%s%s"):format(e.qty, e.name, e.rarity,
                e.chroma and " (chroma)" or "", e.pet and " (pet)" or "")
        end
        yaz(("%s — %d çeşit\n%s"):format(nick, #esyalar, table.concat(satirlar, "\n")))
    end,
    teshis = function()
        db_yukle()
        local bilgi = {
            ("sürüm: %s | DB: %d silah, %d pet"):format(SURUM, DB.silah_n, DB.pet_n),
            "RemoteFunction adayları:",
        }
        for _, d in ipairs(adaylar()) do bilgi[#bilgi + 1] = "  " .. d:GetFullName() end
        if VERI.uzak then
            bilgi[#bilgi + 1] = ("öğrenilen veri kaynağı: %s (argüman %d)"):format(VERI.uzak:GetFullName(), VERI.arg)
        else
            bilgi[#bilgi + 1] = "veri kaynağı henüz bulunamadı"
            if VERI.son_rapor ~= "" then bilgi[#bilgi + 1] = "son rapor: " .. VERI.son_rapor end
        end
        local pg = player_gui()
        if pg then
            bilgi[#bilgi + 1] = "PlayerGui çocukları:"
            for _, d in ipairs(pg:GetChildren()) do
                local acik = d:IsA("LayerCollector") and d.Enabled or (d:IsA("GuiObject") and d.Visible)
                bilgi[#bilgi + 1] = ("  %s (%s, görünür=%s)"):format(d.Name, d.ClassName, tostring(acik))
            end
        end
        local metin = table.concat(bilgi, "\n")
        yaz(metin)
        pcall(kopru, "/log", { name = AD, msg = metin })
    end,
    durdur = function()
        calisiyor = false
        rozet_yaz("durduruldu", RENK_BEKLE)
        yaz("durduruldu")
    end,
    rozet = rozet,
    surum = SURUM,
}

rozet()
task.spawn(chat_bagla)
task.spawn(db_yukle)
task.spawn(function()
    local ok, hata = pcall(dongu)
    if not ok then yaz("döngü hatası: " .. tostring(hata)) end
end)
yaz(("yüklendi (%s) — sohbete %s <nick> yaz ya da konsola MM2_ENVANTER.oku(\"nick\")")
    :format(SURUM, AYAR.chat_komut))
rozet_yaz("hazır")
