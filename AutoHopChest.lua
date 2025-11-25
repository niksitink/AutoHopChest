setfpscap(10)

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
local player = game.Players.LocalPlayer

-- TEAM cho chest
getgenv().Team = getgenv().Team or "Marines"

-- Auto chest
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/trongdeptraihucscript/Main/refs/heads/main/TN-Tp-Chest.lua"))()
end)

-- =============================
--  AUTO SERVER HOP V4.1 - ANTI 772 / 773
-- =============================

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local placeId   = game.PlaceId
local hop_delay = tonumber(getgenv().HopDelay) or 120
local lastServer = game.JobId
local isRetrying = false

local ServerHop -- forward declare để dùng trong event

-- Khi teleport fail (772, 773, v.v...) thì tự hop lại
TeleportService.TeleportInitFailed:Connect(function(plr, result, msg)
    if plr ~= player then return end

    warn("TeleportInitFailed:", result, msg)

    if not isRetrying then
        isRetrying = true
        task.delay(2, function()
            isRetrying = false
            ServerHop()
        end)
    end
end)

local function SafeTeleport(serverId)
    -- Ở đây TeleportToPlaceInstance có thể cho ra 772 nhưng không throw error,
    -- nên phần xử lý chính là trong TeleportInitFailed ở trên.
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, serverId, player)
    end)

    if not ok then
        warn("Teleport pcall error:", err)
        return false
    end

    return true
end

ServerHop = function()
    task.wait(math.random(1,2)) -- tránh spam request

    local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
    local data

    local ok, err = pcall(function()
        data = HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not ok or not data or not data.data then
        warn("Không lấy được list server, retry 3s...", err)
        return task.delay(3, ServerHop)
    end

    for _, server in ipairs(data.data) do
        if server.id ~= lastServer
        and server.playing < server.maxPlayers
        and (not server.ping or server.ping <= 600) then

            if SafeTeleport(server.id) then
                lastServer = server.id
                return
            end
        end
    end

    warn("Không tìm được server phù hợp, retry 5s...")
    task.delay(5, ServerHop)
end

task.spawn(function()
    while task.wait(hop_delay) do
        ServerHop()
    end
end)
