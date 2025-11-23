setfpscap(10)
-- AutoHopChest.lua
-- Auto Chest + Auto Server Hop cho Blox Fruits

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
local player = game.Players.LocalPlayer

-- Team cho script chest (có thể override bằng getgenv().Team trước khi load)
getgenv().Team = getgenv().Team or "Marines"

-- Chạy auto chest
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/trongdeptraihucscript/Main/refs/heads/main/TN-Tp-Chest.lua"))()
end)

-- =============================
-- AUTO SERVER HOP SAU X GIÂY
-- =============================

local TeleportService = game:GetService("TeleportService")
local PLACE_ID = game.PlaceId

-- Nếu đã set getgenv().HopDelay trước đó thì dùng, không thì mặc định 95s
local HOP_INTERVAL = tonumber(getgenv().HopDelay) or 95

task.spawn(function()
    while task.wait(HOP_INTERVAL) do
        pcall(function()
            TeleportService:Teleport(PLACE_ID, player)
        end)
    end
end)
