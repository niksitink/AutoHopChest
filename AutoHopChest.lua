setfpscap(10)

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
local player = game.Players.LocalPlayer

-- Team cho chest
getgenv().Team = getgenv().Team or "Marines"

-- Auto chest
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/trongdeptraihucscript/Main/refs/heads/main/TN-Tp-Chest.lua"))()
end)

-- =============================
--  AUTO SERVER HOP V4 (ANTI-267 FOR WAVE)
-- =============================

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local placeId = game.PlaceId
local hop_delay = tonumber(getgenv().HopDelay) or 120  -- mặc định tăng lên cho Wave
local lastServer = game.JobId

-- Auto Rejoin nếu bị Kick Security
task.spawn(function()
    local CoreGui = game:GetService("CoreGui")
    CoreGui.ChildAdded:Connect(function(child)
        if child.Name == "RobloxPromptGui" or child.Name == "ErrorPrompt" then
            task.wait(1)
            TeleportService:Teleport(placeId)
        end
    end)
end)

local function SafeTeleport(serverId)
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, serverId, player)
    end)

    if not success then
        warn("Teleport Fail:", err)
        task.wait(math.random(2,4)) -- tránh Wave anti
        return false
    end

    return true
end

local function ServerHop()
    task.wait(math.random(1,2)) -- tránh spam request cho Wave

    local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"

    local data
    local ok, err = pcall(function()
        data = HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not ok or not data or not data.data then
        warn("Không lấy được list server, retry...")
        return task.delay(3, ServerHop)
    end

    for _, server in ipairs(data.data) do
        -- Server an toàn
        if server.id ~= lastServer
        and server.ping <= 500
        and server.playing < server.maxPlayers
        then
            if SafeTeleport(server.id) then
                return
            else
                warn("Teleport lỗi -> thử server khác")
            end
        end
    end

    warn("Không tìm được server phù hợp -> retry 5s")
    task.delay(5, ServerHop)
end

task.spawn(function()
    while task.wait(hop_delay) do
        ServerHop()
    end
end)
