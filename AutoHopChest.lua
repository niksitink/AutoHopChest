-- AutoHopChest V5 - Multi Acc + Wave friendly

-- FPS: để thấp quá (10) dễ bị 267, mình cho 20 default
setfpscap(getgenv().FPS or 20)

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
local player = game.Players.LocalPlayer

-- ================== AUTO CHEST ==================
getgenv().Team = getgenv().Team or "Marines"

pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/trongdeptraihucscript/Main/refs/heads/main/TN-Tp-Chest.lua"))()
end)

-- ================== AUTO HOP V5 ==================

local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")
local CoreGui          = game:GetService("CoreGui")

local placeId    = game.PlaceId
local lastServer = game.JobId
local lastHop    = 0

-- Base delay và random thêm để mỗi acc lệch nhau
local BASE_DELAY  = tonumber(getgenv().HopDelay) or 180   -- 3 phút
local JITTER_MAX  = tonumber(getgenv().HopJitter) or 60   -- lệch ngẫu nhiên 0–60s

local function nextDelay()
    return BASE_DELAY + math.random(0, JITTER_MAX)
end

local isRetrying = false
local function ServerHop() end  -- forward declare

-- Auto rejoin nếu dính 267 (Security kick)
task.spawn(function()
    local function hookPrompt(gui)
        local overlay = gui:FindFirstChild("promptOverlay")
        if not overlay then return end

        overlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" then
                task.wait(0.5)
                local msgObj = child:FindFirstChild("MessageArea")
                if msgObj and msgObj:FindFirstChild("ErrorFrame") then
                    local textLabel = msgObj.ErrorFrame:FindFirstChild("ErrorMessage")
                    if textLabel and typeof(textLabel.Text) == "string" then
                        local txt = textLabel.Text
                        if string.find(txt, "Security kick") or string.find(txt, "267") then
                            task.wait(1)
                            TeleportService:Teleport(placeId)
                        end
                    end
                end
            end
        end)
    end

    local rpg = CoreGui:FindFirstChild("RobloxPromptGui")
    if rpg then hookPrompt(rpg) end
    CoreGui.ChildAdded:Connect(function(child)
        if child.Name == "RobloxPromptGui" then
            hookPrompt(child)
        end
    end)
end)

-- Bắt TeleportInitFailed (772, 773...) -> auto hop lại server khác
TeleportService.TeleportInitFailed:Connect(function(plr, result, msg)
    if plr ~= player then return end
    if isRetrying then return end
    isRetrying = true
    warn("TeleportInitFailed:", result, msg)
    task.delay(math.random(2,4), function()
        isRetrying = false
        ServerHop()
    end)
end)

local function SafeTeleport(serverId)
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, serverId, player)
    end)
    if not ok then
        warn("Teleport pcall error:", err)
        return false
    end
    lastServer = serverId
    lastHop = tick()
    return true
end

ServerHop = function()
    -- chặn spam hop nếu vừa hop xong
    if tick() - lastHop < 10 then return end

    task.wait(math.random(1,3)) -- giảm spam HTTP cho Wave

    local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
    local data

    local ok, err = pcall(function()
        data = HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not ok or not data or not data.data then
        warn("Không lấy được list server, retry 5s...", err)
        return task.delay(5, ServerHop)
    end

    for _, server in ipairs(data.data) do
        -- tránh server cũ, tránh full, tránh ping quá cao
        if server.id ~= lastServer
        and server.playing < server.maxPlayers
        and (not server.ping or server.ping <= 600) then
            if SafeTeleport(server.id) then
                return
            end
        end
    end

    warn("Không server nào phù hợp, retry 10s...")
    task.delay(10, ServerHop)
end

-- Loop hop chính
task.spawn(function()
    while task.wait(nextDelay()) do
        ServerHop()
    end
end)
