-- AutoHopChest V6 - Multi-Acc + Wave Friendly

-- FPS: để quá thấp dễ bị 267, giữ 20–30 là hợp lý
setfpscap(getgenv().FPS or 25)

repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
repeat task.wait() until Players.LocalPlayer
local player = Players.LocalPlayer

-- ================== AUTO CHEST ==================
getgenv().Team = getgenv().Team or "Marines"

pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/trongdeptraihucscript/Main/refs/heads/main/TN-Tp-Chest.lua"))()
end)

-- ================== AUTO HOP V6 ==================

local HttpService     = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local CoreGui         = game:GetService("CoreGui")

local placeId    = game.PlaceId
local lastServer = game.JobId
local lastHop    = 0
local isHopping  = false
local isRetrying = false

-- base delay (giây) + jitter random để các acc lệch nhau
local BASE_DELAY = tonumber(getgenv().HopDelay)  or 180   -- 3 phút
local JITTER_MAX = tonumber(getgenv().HopJitter) or 120   -- lệch thêm 0-120s

local function nextDelay()
    return BASE_DELAY + math.random(0, JITTER_MAX)
end

-- ============ AUTO REJOIN 267 / 277 ============

local function hookPromptGui(gui)
    local overlay = gui:FindFirstChild("promptOverlay")
    if not overlay then return end

    overlay.ChildAdded:Connect(function(child)
        if child.Name == "ErrorPrompt" then
            task.delay(0.5, function()
                local text = ""

                -- cách 1: đúng cấu trúc chuẩn
                local msgArea = child:FindFirstChild("MessageArea", true)
                if msgArea and msgArea:FindFirstChild("ErrorFrame") then
                    local em = msgArea.ErrorFrame:FindFirstChild("ErrorMessage")
                    if em and typeof(em.Text) == "string" then
                        text = em.Text
                    end
                end

                -- fallback: tìm bất kỳ TextLabel nào có text
                if text == "" then
                    local lbl = child:FindFirstChildWhichIsA("TextLabel", true)
                    if lbl and typeof(lbl.Text) == "string" then
                        text = lbl.Text
                    end
                end

                if text ~= "" then
                    text = string.lower(text)
                    if string.find(text, "security kick")
                        or string.find(text, "error code: 267")
                        or string.find(text, "error code: 277")
                        or string.find(text, "check your internet") then

                        task.wait(1)
                        TeleportService:Teleport(placeId)
                    end
                end
            end)
        end
    end)
end

task.spawn(function()
    local rpg = CoreGui:FindFirstChild("RobloxPromptGui")
    if rpg then hookPromptGui(rpg) end

    CoreGui.ChildAdded:Connect(function(child)
        if child.Name == "RobloxPromptGui" then
            hookPromptGui(child)
        end
    end)
end)

-- ============ BẮT TELEPORT FAIL 772 / 773 ============

local ServerHop -- forward declare

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
    lastHop    = tick()
    return true
end

ServerHop = function()
    if isHopping then return end
    if tick() - lastHop < 10 then return end  -- chống spam hop

    isHopping = true
    task.delay(15, function() isHopping = false end) -- fail-safe

    task.wait(math.random(1,3)) -- giảm spam HTTP cho Wave

    local url = "https://games.roblox.com/v1/games/" .. placeId ..
                "/servers/Public?sortOrder=Asc&limit=100"

    local data
    local ok, err = pcall(function()
        data = HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not ok or not data or not data.data then
        warn("Không lấy được list server, retry 5s...", err)
        isHopping = false
        return task.delay(5, ServerHop)
    end

    local candidates = {}

    for _, server in ipairs(data.data) do
        if server.id ~= lastServer
        and server.playing < server.maxPlayers
        and (not server.ping or server.ping <= 700) then
            table.insert(candidates, server)
        end
    end

    if #candidates == 0 then
        warn("Không server nào phù hợp, retry 10s...")
        isHopping = false
        return task.delay(10, ServerHop)
    end

    -- chọn random trong danh sách để nhiều acc không đổ vào cùng 1 server
    local target = candidates[math.random(1, #candidates)]
    if not SafeTeleport(target.id) then
        warn("Teleport lỗi, retry 6s...")
        isHopping = false
        return task.delay(6, ServerHop)
    end
end

-- Loop hop chính
task.spawn(function()
    -- delay ngẫu nhiên lần đầu để các acc không hop cùng lúc
    task.wait(math.random(10, 60))
    while task.wait(nextDelay()) do
        ServerHop()
    end
end)
