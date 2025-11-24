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
-- AUTO SERVER HOP V2 - Không lỗi 773
-- =============================

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local placeId = game.PlaceId
local hop_delay = tonumber(getgenv().HopDelay) or 95

local function ServerHop()
    local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
    local data = HttpService:JSONDecode(game:HttpGet(url))

    for _, server in pairs(data.data) do
        if server.playing < server.maxPlayers then
            TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
            return
        end
    end
end

task.spawn(function()
    while task.wait(hop_delay) do
        ServerHop()
    end
end)
