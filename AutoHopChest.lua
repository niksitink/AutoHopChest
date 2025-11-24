setfpscap(10)

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
local player = game.Players.LocalPlayer

-- Team cho script chest
getgenv().Team = getgenv().Team or "Marines"

-- Auto chest
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/trongdeptraihucscript/Main/refs/heads/main/TN-Tp-Chest.lua"))()
end)

-- =============================
-- AUTO SERVER HOP V3 - CHỐNG 772 + 773 + RETRY
-- =============================

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local placeId = game.PlaceId
local hop_delay = tonumber(getgenv().HopDelay) or 95
local lastServer = game.JobId  -- tránh trùng server

local function ServerHop()
    local url =
        "https://games.roblox.com/v1/games/" ..
        placeId ..
        "/servers/Public?sortOrder=Asc&limit=100"

    local data = HttpService:JSONDecode(game:HttpGet(url))
    if not data or not data.data then
        warn("Không lấy được danh sách server → thử lại 2s")
        task.delay(2, ServerHop)
        return
    end

    for _, server in pairs(data.data) do
        if server.id ~= lastServer and server.playing < server.maxPlayers then

            local success, err = pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
            end)

            if not success then
                warn("Teleport thất bại → retry sau 2s", err)
                task.delay(2, ServerHop)
            end

            return
        end
    end

    warn("Không tìm thấy server phù hợp → retry sau 3s")
    task.delay(3, ServerHop)
end

task.spawn(function()
    while task.wait(hop_delay) do
        ServerHop()
    end
end)
