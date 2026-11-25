local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local TARGET_USER_IDS = {
    205092160,
    7023885741,
}

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local function getTargetPresences()
    local requestFunc = (syn and syn.request) or (http and http.request) or request or http_request
    
    if not requestFunc then
        warn("[HATA] Executor HTTP fonksiyonunu desteklemiyor!")
        return nil
    end

    local success, response = pcall(function()
        return requestFunc({
            Url = "https://presence.roproxy.com/v1/presence/users",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                userIds = TARGET_USER_IDS
            })
        })
    end)

    if success and response then
        if response.StatusCode ~= 200 then
            warn("[API Uyarısı] Durum Kodu: " .. tostring(response.StatusCode) .. " (Rate limit veya Cloudflare olabilir)")
            return nil
        end
        
        local decodeSuccess, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        
        if decodeSuccess and data and data.userPresences then
            return data.userPresences
        end
    else
        warn("[HTTP Hatası] İstek başarısız: " .. tostring(response))
    end
    return nil
end

local function findAvailableTarget(presences)
    if not presences then return nil, false end

    -- 1. Zaten aynı sunucuda mıyız?
    for _, presence in ipairs(presences) do
        if presence.userPresenceType == 2 and presence.gameId and game.JobId == presence.gameId then
            return presence, true
        end
    end

    -- 2. Oyunda olan ve geçerli JobId'si bulunan hesabı bul
    for _, presence in ipairs(presences) do
        if presence.userPresenceType == 2 then
            return presence, false
        end
    end

    return nil, false
end

local function autoJoinLoop()
    print("[Sistem] Takip döngüsü başlatıldı...")
    
    while task.wait(8) do -- Rate limit yememek için 8 saniyeye çekildi
        local presences = getTargetPresences()
        local activeTarget, isAlreadyTogether = findAvailableTarget(presences)
        
        if activeTarget then
            if isAlreadyTogether then
                print("[Bilgi] Hedep hesapla (" .. tostring(activeTarget.userId) .. ") zaten aynı sunucudasınız.")
                task.wait(15)
            else
                local targetPlaceId = activeTarget.placeId
                local targetJobId = activeTarget.gameId
                
                -- JobId null geliyorsa hesap gizlilik ayarları kapalıdır
                if not targetJobId then
                    warn("[Gizlilik Uyarısı] Hesap (" .. tostring(activeTarget.userId) .. ") oyunda ancak JobId alınamadı! 'Who can join me' ayarı kapalı olabilir.")
                elseif targetPlaceId then
                    print("[Işınlanma] Hedef (" .. tostring(activeTarget.userId) .. ") sunucusuna bağlanılıyor...")
                    local tpSuccess, tpErr = pcall(function()
                        TeleportService:TeleportToPlaceInstance(targetPlaceId, targetJobId, Players.LocalPlayer)
                    end)
                    
                    if not tpSuccess then
                        warn("[Işınlanma Hatası] " .. tostring(tpErr))
                        task.wait(6)
                    else
                        task.wait(12)
                    end
                end
            end
        else
            print("[Durum] Hedef hesaplar aktif değil veya API yanıt vermedi.")
        end
    end
end

autoJoinLoop()
