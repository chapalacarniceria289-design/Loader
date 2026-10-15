local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ENDPOINT = "https://scriptkeeper-hub.lovable.app/api/public/validate"
local KEY = getgenv().Key or script_key
local req = (syn and syn.request) or http_request or request

local function kick(msg)
    LocalPlayer:Kick("[Key] " .. tostring(msg))
end

local function call(heartbeat)
    local ok, r = pcall(req, {
        Url = ENDPOINT,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({
            key = KEY,
            hwid = game:GetService("RbxAnalyticsService"):GetClientId(),
            heartbeat = heartbeat or nil,
        }),
    })
    if not ok or not r or r.StatusCode ~= 200 then return nil end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, r.Body)
    return ok2 and data or nil
end

if not KEY or KEY == "" then return kick("Falta la key") end

local data = call(false)
if not data then return kick("No se pudo conectar al servidor") end
if not data.ok then return kick(data.msg) end

-- Lo que lee la pestaña GENERAL del hub
if data.permanent then
    getgenv().KeyRemaining = -1
else
    getgenv().KeyExpireAt = tick() + data.remaining
end

-- Revalida cada 2 minutos (pausas, bans y expiración en vivo)
task.spawn(function()
    while task.wait(120) do
        local hb = call(true)
        if hb and not hb.ok then
            kick(hb.msg)
            break
        end
    end
end)

local fn = loadstring(data.script)
if fn then fn() else kick("Error al cargar el script") end
