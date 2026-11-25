--[[
  mm2_envanter.lua — MM2 envanterini EKRAN OKUMADAN, executor içinden okur.

  Nasıl çalışır:
    1) VERİ MODU: oyunun kendi envanter remote'unu bulur (ReplicatedStorage'daki RemoteFunction'lar
       hedef oyuncuyla denenir, dönen tablo doğrulanır) ve envanteri tablodan okur. Piksel yok.
    2) GUI MODU: veri modu bulunamazsa oyuncu profilini GUI nesneleri üzerinden açar/gezer
       (ekran görüntüsü/OCR yok), hücrelerdeki isim/adet/nadirlik/chroma etiketlerini nesne olarak okur.
    3) Masaüstündeki bot (bot.py) 127.0.0.1 köprüsü üzerinden iş verir: /inv nick -> bot -> bu script.
       Ek olarak oyun içi sohbete "/inv nick" yazınca da okur.

  Kullanım: executor konsoluna yapıştır. Konsol API'si:
    MM2_ENVANTER.oku("nick")     -> eşya listesi (tablo)
    MM2_ENVANTER.yazdir("nick")  -> özeti konsola bas
    MM2_ENVANTER.teshis()        -> bulunan GUI/remote yapısını dök (kalibrasyon için)
    MM2_ENVANTER.durdur()        -> döngüyü kapat

  Eşya biçimi: {name="Luger", rarity="godly", chroma=false, pet=false, qty=1}
]]

if _G.MM2_ENVANTER and _G.MM2_ENVANTER.durdur then pcall(_G.MM2_ENVANTER.durdur) end

local AYAR = {
    port = 8765,            -- bot.py'deki bridge_port ile aynı olmalı
    host = "192.168.0.25",  -- PC'nin LAN IP'si (emülatör için)
    ad = nil,               -- script adı; nil = yerel oyuncunun adı
    chat_komut = "/inv",    -- oyun içi komut
    veri_modu = true,       -- önce oyun verisinden (remote) okumayı dene
    gui_modu = true,        -- olmazsa GUI nesnelerinden oku
    veri_suresi = 8,        -- remote keşfi için saniye bütçesi
    kaydirma_bekle = 0.25,  -- GUI modunda her kaydırmadan sonra bekleme
    kaydirma_deneme = 60,   -- en fazla kaç kaydırma
    poll_araligi = 0.4,     -- bot köprüsünü yoklama aralığı
    ayrinti = true,         -- konsola bilgi yaz
}

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Yerel = Players.LocalPlayer
local AD = AYAR.ad or (Yerel and Yerel.Name) or "script"
local SURUM = "script-v2"

local function yaz(...)
    if AYAR.ayrinti then print("[mm2-envanter]", ...) end
end

-- ===== 2) KÖPRÜ (127.0.0.1 HTTP) =========================================
local http = (syn and syn.request) or (http and http.request) or http_request or request

-- Emülatörde (BlueStacks/LDPlayer/MuMu/Delta) 127.0.0.1 EMÜLATÖRÜN kendisidir; PC'ye 10.0.2.2 ile
-- ulaşılır. PC'de çalışan executor'da ise 127.0.0.1 doğrudur. İkisi de denenir, çalışan hatırlanır.
-- PC'ye 10.0.2.2 ile ulaşılamıyorsa AYAR.host'a PC'nin LAN IP'sini yaz (ör. "192.168.1.34").
local ADRESLER = { "10.0.2.2", "127.0.0.1" }
if AYAR.host then ADRESLER = { AYAR.host, "127.0.0.1" } end
local aktif_adres = nil

local function tek_adres(adres, yol, govde)
    if not http then return nil end
    local ok, cevap = pcall(http, {
        Url = ("http://%s:%d%s"):format(adres, AYAR.port, yol),
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
        aktif_adres = nil  -- adres artık cevap vermiyor: yeniden ara
    end
    for _, adres in ipairs(ADRESLER) do
        local cevap = tek_adres(adres, yol, govde)
        if cevap then
            if aktif_adres ~= adres then
                aktif_adres = adres
                yaz(("bot adresi: %s:%d"):format(adres, AYAR.port))
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
-- Oyundaki ad → botun beklediği ad. Bot tarafında fix_name zaten yakın eşleşmeyi düzeltiyor.
local RARITY_ESLEME = {
    godly = "godly", ancient = "ancient", legendary = "legendary", rare = "rare",
    uncommon = "uncommon", common = "common", unique = "unique", vintage = "vintage",
    chroma = "chroma", pet = "pet", ["godlys"] = "godly", legendarys = "legendary",
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

-- Aynı isim/nadirlik/chroma/pet eşyaları tek satırda topla
local function birlestir(liste)
    local harita, sira = {}, {}
    for _, e in ipairs(liste or {}) do
        local anahtar = ("%s|%s|%s|%s"):format(e.name:lower(), e.rarity, tostring(e.chroma), tostring(e.pet))
        local v = harita[anahtar]
        if v then v.qty = v.qty + (e.qty or 1)
        else
            harita[anahtar] = { name = e.name, rarity = e.rarity, chroma = e.chroma, pet = e.pet, qty = e.qty or 1 }
            sira[#sira + 1] = harita[anahtar]
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
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == nick:lower() or (p.DisplayName and p.DisplayName:lower() == nick:lower()) then return p end
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

-- ===== 4) VERİ MODU: oyunun kendi envanter tablosu =======================
-- Önce ReplicatedStorage'daki RemoteFunction'lar arasından envanteri veren aranır. Türkçe/İngilizce
-- alan adları denenir; tabloya benzeyen dönüş ilk başarıda hatırlanır, sonraki okumalar tek çağrı olur.
local VERI = { uzak = nil, arg = nil }

local AD_ALAN = { "Name", "ItemName", "name", "itemName", "Item", "Id", "id" }
local NADIRLIK_ALAN = { "Rarity", "rarity", "RarityName", "rarityName", "Tier", "tier", "Quality" }
local ADET_ALAN = { "Amount", "amount", "Count", "count", "Quantity", "quantity", "Qty", "qty",
                    "Copies", "Duplicates", "Stack", "stack" }

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

-- Dönen tablonun her yerindeki eşya benzeri girdileri toplar (Weapons/Pets gibi alt tablolar dahil)
local function topla(deger, baglam, cikti, derinlik, gorulen)
    if type(deger) ~= "table" or derinlik > 6 or gorulen[deger] then return end
    gorulen[deger] = true
    if esya_mi(deger) then
        local ham = alan_bul(deger, AD_ALAN, "string")
        local ad, chroma = chroma_ayir(ham)
        local pet = baglam:find("pet", 1, true) ~= nil or deger.Pet == true or deger.IsPet == true
        if ad:find("(Pet)", 1, true) then pet = true; ad = (ad:gsub("%s*%(Pet%)", "")) end
        local adet = alan_bul(deger, ADET_ALAN, "number") or 1
        if type(adet) == "table" then adet = 1 end
        cikti[#cikti + 1] = {
            name = ad, rarity = nadirlik_duzelt(nadirlik_alani(deger)) or "misc",
            chroma = chroma or (deger.Chroma == true or deger.IsChroma == true),
            pet = pet, qty = math.max(math.floor(adet), 1),
        }
        return
    end
    for k, v in pairs(deger) do
        local alt = baglam
        if type(k) == "string" then alt = baglam .. " " .. k:lower() end
        topla(v, alt, cikti, derinlik + 1, gorulen)
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

local ON_EK = { "inv", "item", "weapon", "profile", "get", "fetch", "data", "own", "check" }

local function adaylar()
    local liste, kok = {}, game:GetService("ReplicatedStorage")
    for _, d in ipairs(kok:GetDescendants()) do
        if d:IsA("RemoteFunction") then
            local ad = d.Name:lower()
            for _, onek in ipairs(ON_EK) do
                if ad:find(onek, 1, true) then
                    liste[#liste + 1] = d
                    break
                end
            end
        end
    end
    return liste
end

local ARG_ORNEKLERI = {
    function(p) return { p } end,
    function(p) return { p.UserId } end,
    function(p) return { "GetInventory", p } end,
    function(p) return { p, "Inventory" } end,
    function(p) return { "Inventory", p.UserId } end,
}

local function cagir(uzak, arglar)
    local ok, sonuc = pcall(function() return uzak:InvokeServer(table.unpack(arglar)) end)
    return ok and sonuc or nil
end

local function veri_ogren(hedef)
    local bitis = os.clock() + AYAR.veri_suresi
    for _, uzak in ipairs(adaylar()) do
        for i, ornek in ipairs(ARG_ORNEKLERI) do
            if os.clock() > bitis then return nil end
            local liste = tablodan_oku(cagir(uzak, ornek(hedef)))
            if #liste > 0 then
                if hedef == Yerel then
                    VERI.uzak, VERI.arg = uzak, i
                    logla(("veri kaynağı: %s (argüman %d)"):format(uzak:GetFullName(), i))
                    return liste
                end
                -- Argümanı yok sayıp kendi envanterini veren remote'ları ayıkla
                local kendi = tablodan_oku(cagir(uzak, ornek(Yerel)))
                if imza(kendi) ~= imza(liste) then
                    VERI.uzak, VERI.arg = uzak, i
                    logla(("veri kaynağı: %s (argüman %d)"):format(uzak:GetFullName(), i))
                    return liste
                end
                break -- bu remote oyuncuya göre veri vermiyor
            end
        end
    end
    return nil
end

local function veri_oku(oyuncu)
    if not AYAR.veri_modu then return nil end
    if VERI.uzak then
        local liste = tablodan_oku(cagir(VERI.uzak, ARG_ORNEKLERI[VERI.arg](oyuncu)))
        if #liste > 0 then return liste end
        VERI.uzak, VERI.arg = nil, nil  -- kaynak artık cevap vermiyor: yeniden öğren
    end
    return veri_ogren(oyuncu)
end

-- ===== 5) GUI MODU: profil panelini nesne olarak okuma ====================
-- Ekran görüntüsü/OCR yok: hücrelerdeki TextLabel'lar (isim, "xN", "Chroma") ve nadirlik rengi
-- doğrudan nesnelerden okunur. Kaydırma CanvasPosition ile yapılır (fare tekerleği gerekmez).
local NADIRLIK_RENK = {
    godly = Color3.fromRGB(253, 1, 178), ancient = Color3.fromRGB(90, 10, 235),
    legendary = Color3.fromRGB(196, 6, 9), rare = Color3.fromRGB(0, 200, 0),
    uncommon = Color3.fromRGB(1, 253, 253), common = Color3.fromRGB(100, 100, 100),
    unique = Color3.fromRGB(239, 139, 0), vintage = Color3.fromRGB(230, 200, 0),
}
local RENK_TOLERANS = 0.12  -- kanal başına ~30/255

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
        if (n:IsA("GuiObject") or n:IsA("LayerCollector")) and n.Visible == false then return false end
        n = n.Parent
    end
    return true
end

-- Düğme yazısı: TextButton'ın kendi yazısı ya da ImageButton'ın içindeki etiket
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
    end
    if VirtualUser then
        if pcall(function() VirtualUser:ClickButton(nesne) end) then oldu = true end
    end
    return oldu
end

-- Oyuncu listesindeki satırı bulur: aynı kapsayıcıda en çok oyuncu adı olan yer listeyi verir.
local function oyuncu_satiri(nick)
    local pg = player_gui()
    if not pg then return nil end
    local isimler = {}
    for _, p in ipairs(Players:GetPlayers()) do isimler[#isimler + 1] = p.Name:lower() end
    local gruplar = {}
    for _, e in ipairs(pg:GetDescendants()) do
        if e:IsA("TextLabel") and gorunur(e) then
            local sade = (metin_temiz(e.Text) or ""):lower():gsub("^%[.-%]%s*", "")
            for _, isim in ipairs(isimler) do
                if sade == isim then
                    local kap = e.Parent or e
                    for _ = 1, 4 do if kap and kap.Parent then kap = kap.Parent end end
                    gruplar[kap] = gruplar[kap] or { n = 0, etiket = {} }
                    if not gruplar[kap].etiket[sade] then
                        gruplar[kap].n = gruplar[kap].n + 1
                        gruplar[kap].etiket[sade] = e
                    end
                    break
                end
            end
        end
    end
    local en_iyi, en_iyi_n = nil, 0
    for kap, bilgi in pairs(gruplar) do
        if bilgi.n > en_iyi_n then en_iyi, en_iyi_n = kap, bilgi.n end
    end
    return en_iyi and gruplar[en_iyi].etiket[nick:lower()] or nil
end

local function satira_tikla(etiket)
    local n = etiket
    while n and not (n:IsA("TextButton") or n:IsA("ImageButton")) do n = n.Parent end
    if n then return tikla(n) end
    if etiket.Parent and firesignal then
        pcall(firesignal, etiket.Parent.MouseButton1Click)
        return true
    end
    return false
end

local KATEGORI = { "weapons", "pets", "radios", "items", "emotes", "effects", "inventory" }

-- Silah/Pets gibi kategori düğmelerini taşıyan panelin ortak atasını bulur
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

-- Izgarayı bulur: en çok "hücre" (içinde yazı olan çocuk) barındıran çerçeve
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

-- Tek hücre: isim + "xN" + "Chroma" + nadirlik rengi (arka plan/kontur)
local function hucre_oku(hucre)
    local etiketler = {}
    if hucre:IsA("TextButton") or hucre:IsA("TextLabel") then etiketler[1] = hucre end  -- yazı doğrudan hücrede olabilir
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

-- Izgaranın tamamını okur. Slot kimliği içerik koordinatı (kaydırma düşülür): aynı slot birden çok
-- karede görülse bile adet şişmez (bot tarafındaki merge mantığının aynısı).
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
        local son = math.max(sf.CanvasSize.Y - sf.AbsoluteSize.Y, 0)
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

-- Sekme düğmeleri: aynı yatay satırdaki düğme grubu (Season 1 / Classic / Holiday gibi).
-- Kategori düğmeleri (Weapons/Pets) ve kapatma düğmesi dışlanır.
local YASAK_SEKME = { weapons = true, weapon = true, pets = true, pet = true, radios = true,
                      items = true, emotes = true, effects = true, close = true, equip = true }

local function sekme_dugmeleri(ata)
    local grid = izgara_bul(ata)
    local dugmeler = {}
    for _, d in ipairs(ata:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and gorunur(d)
            and not (grid and d:IsDescendantOf(grid)) then  -- eşya hücreleri sekme sanılmasın
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

-- Profil panelini kapatır (X / close düğmesi, yoksa Escape)
local function kapat(ata)
    local adaylar = {}
    for _, d in ipairs(ata:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and gorunur(d) then
            local k = (dugme_metni(d) or ""):lower()
            local ad = (d.Name or ""):lower()
            if k == "x" or k == "×" or k == "✕" or k == "close" or ad:find("close", 1, true) then
                adaylar[#adaylar + 1] = d
            end
        end
    end
    if adaylar[1] then
        tikla(adaylar[1]); task.wait(0.4)
        return
    end
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyDownEvent(Enum.KeyCode.Escape, false, true, game)
        vim:SendKeyUpEvent(Enum.KeyCode.Escape, false, true, game)
    end)
    task.wait(0.3)
end

-- GUI modu: oyuncu listesinden profile girip sekmeleri dolaşır, ızgarayı nesne olarak okur.
local function gui_oku(oyuncu)
    if not AYAR.gui_modu then return nil end
    local pg = player_gui()
    if not pg then return nil, "PlayerGui yok" end

    local etiket = oyuncu_satiri(oyuncu.Name)
    if not etiket then
        local acici = dugme_bul(pg, "players", true) or dugme_bul(pg, "player list", false)
        if acici then tikla(acici); task.wait(0.6) end
        etiket = bekle(function() return oyuncu_satiri(oyuncu.Name) end, 1.5)
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
        if imza_ == onceki then return end  -- sekme değişmedi / aynı sayfa iki kez okundu
        onceki = imza_
        for _, e in ipairs(parca) do liste[#liste + 1] = e end
    end

    local silah = dugme_bul(ata, "weapons", true) or dugme_bul(ata, "weapon", false)
    if silah then
        tikla(silah); task.wait(0.7)
        local sekmeler = sekme_dugmeleri(ata)
        if #sekmeler > 0 then
            for _, s in ipairs(sekmeler) do
                tikla(s); task.wait(0.7)
                sayfa_ekle(false)
            end
        else
            sayfa_ekle(false)
        end
    end

    local pet_dugme = dugme_bul(ata, "pets", true) or dugme_bul(ata, "pet", false)
    if pet_dugme then
        tikla(pet_dugme); task.wait(0.8)
        sayfa_ekle(true)
    end

    kapat(ata)
    if #liste == 0 then return nil, "envanter panelinde eşya okunamadı" end
    return birlestir(liste)
end

-- ===== 6) ROZET: sağ altta "Inv" ==========================================
-- Rozet görünüyorsa script yüklendi (enjeksiyon tuttu). Okuma sırasında rengi/yazısı değişir.
-- İstemezsen: MM2_ENVANTER.rozet(false)
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
        local eski = pg:FindFirstChild("MM2EnvanterRozet")  -- önceki enjeksiyondan kalmış olabilir
        if eski then eski:Destroy() end
        rozet_gui = Instance.new("ScreenGui")
        rozet_gui.Name = "MM2EnvanterRozet"
        rozet_gui.ResetOnSpawn = false
        rozet_gui.IgnoreGuiInset = true
        rozet_gui.DisplayOrder = 1000
        rozet_gui.Parent = pg
        rozet_etiket = Instance.new("TextLabel")
        rozet_etiket.Size = UDim2.new(0, 118, 0, 26)
        rozet_etiket.Position = UDim2.new(1, -132, 1, -100)  -- sağ alt köşe
        rozet_etiket.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        rozet_etiket.BackgroundTransparency = 0.15
        rozet_etiket.TextSize = 15
        rozet_etiket.Font = Enum.Font.GothamBold
        rozet_etiket.TextColor3 = Color3.fromRGB(130, 255, 150)
        rozet_etiket.Text = "Inv • yüklendi"
        rozet_etiket.Parent = rozet_gui
        local kose = Instance.new("UICorner")
        kose.CornerRadius = UDim.new(0, 6)
        kose.Parent = rozet_etiket
    end)
end

local function rozet_yaz(metin, renk)
    pcall(function()
        if not rozet_etiket then return end
        rozet_etiket.Text = "Inv • " .. metin
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

    local gui_esyalar, hata = gui_oku(oyuncu)
    if gui_esyalar and #gui_esyalar > 0 then
        yaz(("%s: GUI modu, %d çeşit, %.2f sn"):format(oyuncu.Name, #gui_esyalar, os.clock() - basla))
        rozet_yaz("okundu")
        return gui_esyalar
    end
    rozet_yaz("okunamadı", RENK_HATA)
    return nil, hata or "envanter okunamadı"
end

-- ===== 8) OYUN İÇİ KOMUT =================================================
local calisiyor = true

-- Uzun özeti sohbete tek satır olarak bas (Roblox sohbet sınırı ~200 karakter)
local function soyle(metin)
    local r = game:GetService("ReplicatedStorage")
    local olay = r:FindFirstChild("DefaultChatSystemChatEvents")
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
        olay = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents", 6)
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
                yaz(("bot bulunamadı (denenen adresler: %s). PC'de bot.py açık mı? Windows güvenlik duvarı "
                    .. "8765'e izin veriyor mu? Emülatörde 10.0.2.2 PC'yi gösterir; gerekirse AYAR.host'a "
                    .. "PC'nin LAN IP'sini yaz."):format(table.concat(ADRESLER, ", ")))
            end
        else
            if bagli ~= true then
                bagli = true
                kopru("/hello", { name = AD })
                rozet_yaz("bağlı")
                yaz(("bot bağlı: %s:%d"):format(tostring(aktif_adres), AYAR.port))
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
        task.wait(bagli == false and 2 or AYAR.poll_araligi)  -- bağlantı yokken daha seyrek dene
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
        local bilgi = { "RemoteFunction adayları:" }
        for _, d in ipairs(adaylar()) do bilgi[#bilgi + 1] = "  " .. d:GetFullName() end
        if VERI.uzak then
            bilgi[#bilgi + 1] = ("öğrenilen veri kaynağı: %s (argüman %d)"):format(VERI.uzak:GetFullName(), VERI.arg)
        else
            bilgi[#bilgi + 1] = "veri kaynağı henüz bulunamadı"
        end
        local pg = player_gui()
        if pg then
            bilgi[#bilgi + 1] = "PlayerGui çocukları:"
            for _, d in ipairs(pg:GetChildren()) do
                bilgi[#bilgi + 1] = ("  %s (%s, görünür=%s)"):format(d.Name, d.ClassName, tostring(d.Visible))
            end
            local ata = panel_bul()
            bilgi[#bilgi + 1] = "profil paneli: " .. (ata and ata:GetFullName() or "bulunamadı")
            local grid = ata and izgara_bul(ata) or nil
            bilgi[#bilgi + 1] = "ızgara: " .. (grid and grid:GetFullName() or "bulunamadı")
            if grid then
                bilgi[#bilgi + 1] = ("ızgaranın doğrudan çocuğu: %d"):format(#grid:GetChildren())
                local ilk = grid:GetChildren()[1]
                if ilk then
                    for _, t in ipairs(ilk:GetDescendants()) do
                        if t:IsA("TextLabel") then
                            bilgi[#bilgi + 1] = ("  örnek etiket: %q arkaplan=%s"):format(t.Text, tostring(t.BackgroundColor3))
                        end
                    end
                end
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
chat_bagla()
task.spawn(function()
    local ok, hata = pcall(dongu)
    if not ok then yaz("döngü hatası: " .. tostring(hata)) end
end)
yaz(("yüklendi (%s) — sohbete %s <nick> yaz ya da konsola MM2_ENVANTER.oku(\"nick\")")
    :format(SURUM, AYAR.chat_komut))
rozet_yaz("hazır")
