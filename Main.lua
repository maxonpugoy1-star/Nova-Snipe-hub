-- [[ NOVA SNIPE HUB - INVISIBLE CORE ENGINE ]] --
-- Completely skips UI rendering to bypass all mobile executor loading crashes

_G.NovaSniperRunning = true

-- Configuration Flags
local SAFE_HEALTH_THRESHOLD = 25
local ITEM_WHITELIST = {
    ["Cosmic Relic"] = true,
    ["Fallen Star"] = true
}
local QUEST_BLACKLIST = {
    ["Mella Tidefall"] = true,
    ["Admin Quest"] = true,
    ["Developer Request"] = true,
    ["Part Rod Quest"] = true,
    ["Blue Whale Migration"] = true
}

local originalPosition = nil
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

-- Anti-AFK Hook
pcall(function()
    LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end)

local function firePrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        task.spawn(function()
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration + 0.05)
            prompt:InputHoldEnd()
        end)
    end
end

-- 1. Cosmic Relic Sniper Module
local function scanAndGrab()
    local targetFolders = { workspace:FindFirstChild("DroppedItems"), workspace:FindFirstChild("ActiveItems"), workspace:FindFirstChild("Map"), workspace }
    for _, folder in pairs(targetFolders) do
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if ITEM_WHITELIST[child.Name] then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local hrp = LocalPlayer.Character.HumanoidRootPart
                        originalPosition = hrp.CFrame
                        hrp.CFrame = child:GetPivot() * CFrame.new(0, 1.5, 0)
                        task.wait(0.3)
                        
                        local prompt = child:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then firePrompt(prompt) task.wait(0.5) end
                        if originalPosition then hrp.CFrame = originalPosition end
                        return
                    end
                end
            end
        end
    end
end

-- 2. Smart Auto-Quest Module
local function processValidQuests()
    local npcFolder = workspace:FindFirstChild("NPCs") or workspace:FindFirstChild("WorldNPCs") or workspace
    if not npcFolder then return end
    for _, npc in ipairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") and not QUEST_BLACKLIST[npc.Name] then
            local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and prompt.Enabled == true then
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = LocalPlayer.Character.HumanoidRootPart
                    originalPosition = hrp.CFrame
                    hrp.CFrame = npc:GetPivot() * CFrame.new(0, 0, -3)
                    task.wait(0.4)
                    firePrompt(prompt)
                    task.wait(0.5)
                    local net = ReplicatedStorage:FindFirstChild("events") or ReplicatedStorage:FindFirstChild("Network")
                    if net and net:FindFirstChild("QuestRemote") then
                        net.QuestRemote:FireServer(npc.Name, "Accept")
                        net.QuestRemote:FireServer(npc.Name, "Claim")
                    end
                    task.wait(0.3)
                    if originalPosition then hrp.CFrame = originalPosition end
                    break 
                end
            end
        end
    end
end

-- 3. Auto Fishing Module
local function executeFishingLoop()
    local character = LocalPlayer.Character
    if not character then return end
    local rod = character:FindFirstChildOfClass("Tool") or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
    if rod and (rod.Name:match("Rod") or rod.Name:match("Spincaster") or rod.Name:match("Cosmos")) then
        if rod.Parent == LocalPlayer.Backpack then rod.Parent = character end
        if rod:FindFirstChild("events") and rod.events:FindFirstChild("cast") then rod.events.cast:FireServer(100) end
    end
end

task.spawn(function()
    local net = ReplicatedStorage:FindFirstChild("events") or ReplicatedStorage:FindFirstChild("Network")
    if net then
        for _, v in pairs(net:GetChildren()) do
            if v.Name:match("reeled") or v.Name:match("catch") or v.Name:match("shake") then
                v.OnClientEvent:Connect(function(...)
                    task.wait(0.1)
                    v:FireServer(true)
                end)
            end
        end
    end
end)

-- Main Master Thread Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        
        -- Anti-Death
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if humanoid and hrp and humanoid.Health > 0 then
                if humanoid.Health <= SAFE_HEALTH_THRESHOLD then
                    hrp.CFrame = CFrame.new(380, 13, 250) 
                    task.wait(1)
                end
                local state = humanoid:GetState()
                if state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll then
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end
        
        -- Run Features Automatically
        scanAndGrab()
        processValidQuests()
        
        local char = LocalPlayer.Character
        if char and not char:FindFirstChild("Fish") and not char:FindFirstChild("Reeling") then 
            executeFishingLoop() 
        end
        
        local net = ReplicatedStorage:FindFirstChild("events") or ReplicatedStorage:FindFirstChild("Network")
        if net and net:FindFirstChild("sellall") then 
            net.sellall:FireServer() 
        end
    end
end)

print("[Nova Snipe] Core engine activated successfully without UI.")



