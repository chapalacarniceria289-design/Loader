-- ==========================================
-- SG HUB | Loader con ventana de key
-- ==========================================
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local ENDPOINT = "https://scriptkeeper-hub.lovable.app/api/public/validate"
local SAVE_FILE = "sghub_key.txt"
local req = (syn and syn.request) or http_request or request

local RED = Color3.fromRGB(255, 42, 61)
local BG = Color3.fromRGB(16, 8, 10)
local PANEL = Color3.fromRGB(28, 14, 17)

-- limpiar ventana anterior
pcall(function() playerGui:FindFirstChild("SGKeyWindow"):Destroy() end)
pcall(function() game:GetService("CoreGui"):FindFirstChild("SGKeyWindow"):Destroy() end)

-- ==========================================
-- LLAMADA AL SERVIDOR
-- ==========================================
local function call(key, heartbeat)
    if not req then return nil, "Tu executor no soporta requests" end
    local ok, r = pcall(req, {
        Url = ENDPOINT,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({
            key = key,
            hwid = game:GetService("RbxAnalyticsService"):GetClientId(),
            heartbeat = heartbeat or nil,
        }),
    })
    if not ok or not r then return nil, "No se pudo conectar al servidor" end
    if r.StatusCode ~= 200 then return nil, "Servidor no disponible (" .. tostring(r.StatusCode) .. ")" end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, r.Body)
    if not ok2 or type(data) ~= "table" then return nil, "Respuesta inválida del servidor" end
    return data
end

-- ==========================================
-- ARRANCAR EL HUB (key válida)
-- ==========================================
local function launch(data, key)
    pcall(function() if writefile then writefile(SAVE_FILE, key) end end)

    if data.permanent then
        getgenv().KeyRemaining = -1
    else
        getgenv().KeyExpireAt = tick() + (data.remaining or 0)
    end

    -- revalida cada 2 minutos (pausas, bans y expiración en vivo)
    task.spawn(function()
        while task.wait(120) do
            local hb = call(key, true)
            if hb and not hb.ok then
                LocalPlayer:Kick("[SG HUB] " .. tostring(hb.msg))
                break
            end
        end
    end)

    local fn = loadstring(data.script or "")
    if fn then
        task.spawn(fn)
        return true
    end
    return false
end

-- ==========================================
-- VENTANA DE KEY
-- ==========================================
local function showWindow(prefill)
    local gui = Instance.new("ScreenGui")
    gui.Name = "SGKeyWindow"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local parented = pcall(function()
        local h = gethui and gethui()
        gui.Parent = h or game:GetService("CoreGui")
    end)
    if not parented or not gui.Parent then gui.Parent = playerGui end

    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.Size = UDim2.new(0, 330, 0, 230)
    frame.BackgroundColor3 = BG
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
    local st = Instance.new("UIStroke", frame)
    st.Color = RED
    st.Thickness = 2

    -- insignia SG
    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 38, 0, 38)
    badge.Position = UDim2.new(0, 18, 0, 16)
    badge.BackgroundColor3 = RED
    badge.Text = "SG"
    badge.TextColor3 = Color3.new(1, 1, 1)
    badge.TextSize = 16
    badge.Font = Enum.Font.GothamBlack
    badge.Parent = frame
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Position = UDim2.new(0, 66, 0, 14)
    title.Size = UDim2.new(1, -110, 0, 22)
    title.BackgroundTransparency = 1
    title.Text = "SG HUB"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local sub = Instance.new("TextLabel")
    sub.Position = UDim2.new(0, 66, 0, 36)
    sub.Size = UDim2.new(1, -110, 0, 18)
    sub.BackgroundTransparency = 1
    sub.Text = "Acceso con licencia"
    sub.TextColor3 = Color3.fromRGB(170, 140, 145)
    sub.TextSize = 12
    sub.Font = Enum.Font.Gotham
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = frame

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 28, 0, 28)
    close.Position = UDim2.new(1, -40, 0, 14)
    close.BackgroundColor3 = PANEL
    close.Text = "X"
    close.TextColor3 = Color3.fromRGB(200, 170, 175)
    close.TextSize = 13
    close.Font = Enum.Font.GothamBold
    close.Parent = frame
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)

    local box = Instance.new("TextBox")
    box.Position = UDim2.new(0, 18, 0, 74)
    box.Size = UDim2.new(1, -36, 0, 42)
    box.BackgroundColor3 = PANEL
    box.Text = prefill or ""
    box.PlaceholderText = "Pega tu key aquí"
    box.PlaceholderColor3 = Color3.fromRGB(120, 90, 95)
    box.TextColor3 = Color3.new(1, 1, 1)
    box.TextSize = 14
    box.Font = Enum.Font.Code
    box.ClearTextOnFocus = false
    box.Parent = frame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)
    local bst = Instance.new("UIStroke", box)
    bst.Color = Color3.fromRGB(70, 30, 36)
    bst.Thickness = 1

    local status = Instance.new("TextLabel")
    status.Position = UDim2.new(0, 18, 0, 124)
    status.Size = UDim2.new(1, -36, 0, 34)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 120, 130)
    status.TextSize = 12
    status.TextWrapped = true
    status.Font = Enum.Font.Gotham
    status.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Position = UDim2.new(0, 18, 1, -64)
    btn.Size = UDim2.new(1, -36, 0, 44)
    btn.BackgroundColor3 = RED
    btn.Text = "ENTRAR"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 15
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = true
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    -- arrastrar la ventana (desde la parte de arriba)
    do
        local dragging, dragStart, startPos
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if input.Position.Y - frame.AbsolutePosition.Y < 70 then
                    dragging, dragStart, startPos = true, input.Position, frame.Position
                end
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    -- animación de entrada
    frame.Size = UDim2.new(0, 330, 0, 0)
    TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Size = UDim2.new(0, 330, 0, 230) }):Play()

    local busy, fails, lockedUntil = false, 0, 0
    local function setStatus(text, color)
        status.Text = text
        status.TextColor3 = color or Color3.fromRGB(255, 120, 130)
    end

    local function submit()
        if busy then return end
        if tick() < lockedUntil then
            setStatus("Demasiados intentos. Espera " .. math.ceil(lockedUntil - tick()) .. "s", Color3.fromRGB(255, 190, 90))
            return
        end
        local key = box.Text:gsub("%s+", ""):upper()
        if key == "" then setStatus("Escribe tu key") return end

        busy = true
        btn.Text = "VERIFICANDO..."
        setStatus("Conectando con el servidor...", Color3.fromRGB(200, 170, 175))

        local data, err = call(key, false)
        if not data then
            setStatus(err or "Error de conexión")
        elseif not data.ok then
            fails = fails + 1
            setStatus(tostring(data.msg or "Key inválida"))
            if fails >= 5 then
                lockedUntil = tick() + 30
                fails = 0
            end
        else
            setStatus("Acceso concedido", Color3.fromRGB(90, 230, 140))
            task.wait(0.4)
            gui:Destroy()
            if not launch(data, key) then
                LocalPlayer:Kick("[SG HUB] Error al cargar el script")
            end
            return
        end
        busy = false
        btn.Text = "ENTRAR"
    end

    btn.Activated:Connect(submit)
    box.FocusLost:Connect(function(enter) if enter then submit() end end)
    close.Activated:Connect(function() gui:Destroy() end)
end

-- ==========================================
-- INICIO
-- ==========================================
-- 1) Si ya viene una key preconfigurada, entra sin mostrar la ventana
local preset = getgenv().Key or script_key
if preset and preset ~= "" then
    local key = tostring(preset):gsub("%s+", ""):upper()
    local data = call(key, false)
    if data and data.ok then
        if not launch(data, key) then LocalPlayer:Kick("[SG HUB] Error al cargar el script") end
        return
    end
end

-- 2) Si no, abre la ventana (con la última key guardada ya escrita)
local saved = ""
pcall(function()
    if isfile and readfile and isfile(SAVE_FILE) then saved = readfile(SAVE_FILE) end
end)
showWindow(saved)
