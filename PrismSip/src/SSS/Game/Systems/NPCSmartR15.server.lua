local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Prism = ReplicatedStorage:WaitForChild("Prism")
local Remotes = Prism:WaitForChild("Remotes")
local Outfits = require(Prism.Config.NPCOutfits)
local NamesCfg = require(Prism.Config.NPCNames)
local World = require(Prism.Config.NPCWorldRefs)

local MAX = Outfits.maxNPCs or 6

-- === Helpers ===
local function playerPadCF()
  local cfg = Prism:FindFirstChild("Config"); local path = "Workspace.Map.PlayerPad"
  if cfg and cfg:FindFirstChild("PlayerPadPath") then path = require(cfg.PlayerPadPath).FULL_PATH or path end
  local cur = (string.sub(path,1,9)=="Workspace") and workspace or game
  for token in string.gmatch(path, "[^%.]+") do if token ~= "Workspace" then cur = cur:FindFirstChild(token) end if not cur then break end end
  if cur and cur:IsA("BasePart") then return cur.CFrame end
  return CFrame.new(0,6,0)
end

local usedNames = {}
local function randName()
  local p = NamesCfg.prefixes[math.random(1,#NamesCfg.prefixes)]
  local s = NamesCfg.suffixes[math.random(1,#NamesCfg.suffixes)]
  local n = ""; if NamesCfg.numerics[math.random(1,#NamesCfg.numerics)] then n = tostring(math.random(10,999)) end
  local final = p..s..n; if usedNames[final] then return randName() end; usedNames[final]=true; return final
end

local function applyClothes(model)
  -- Nuke old clothing
  for _,d in ipairs(model:GetChildren()) do if d:IsA("Shirt") or d:IsA("Pants") then d:Destroy() end end
  local shirtId = Outfits.shirts[math.random(1,#Outfits.shirts)]
  local pantsId = Outfits.pants[math.random(1,#Outfits.pants)]
  local shirt = Instance.new("Shirt"); shirt.ShirtTemplate = "rbxassetid://"..shirtId; shirt.Parent = model
  local pants = Instance.new("Pants"); pants.PantsTemplate = "rbxassetid://"..pantsId; pants.Parent = model
  local bc = model:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors", model)
  local skin = Outfits.palettes[math.random(1,#Outfits.palettes)]
  pcall(function()
    bc.HeadColor3=skin; bc.LeftArmColor3=skin; bc.RightArmColor3=skin; bc.TorsoColor3=skin; bc.LeftLegColor3=skin; bc.RightLegColor3=skin
  end)
end

local function spawnNPC(i)
  local model = Players:CreateHumanoidModelFromUserId(1)
  model.Parent = workspace
  local hum = model:FindFirstChildOfClass("Humanoid") or Instance.new("Humanoid", model)
  hum.RigType = Enum.HumanoidRigType.R15; hum.AutoRotate = true
  hum.WalkSpeed = math.random(Outfits.walkSpeedRange[1], Outfits.walkSpeedRange[2])
  hum.JumpPower = math.random(Outfits.jumpPowerRange[1], Outfits.jumpPowerRange[2])
  applyClothes(model)
  hum.DisplayName = randName(); hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
  model:SetAttribute("NPC_Energy", 0); model:SetAttribute("NovaNPC", true); CollectionService:AddTag(model,"NovaNPC")
  model:PivotTo(playerPadCF() * CFrame.new(math.random(-6,6), 4, math.random(-6,6)))
  return model
end

local function H(m) return m and m:FindFirstChildOfClass("Humanoid") end
local function R(m) return m and (m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart")) end
local function worldPos(inst) return (inst:IsA("Model") and inst:GetPivot().Position) or inst.Position end

local function moveTo(npc, targetPos, timeoutSec)
  local h, r = H(npc), R(npc); if not h or not r then return false end
  local path = PathfindingService:CreatePath({AgentRadius=2, AgentHeight=5, AgentCanJump=true})
  local ok = pcall(function() path:ComputeAsync(r.Position, targetPos) end)
  if not ok or path.Status ~= Enum.PathStatus.Success then
    h:MoveTo(targetPos); local t0=os.clock(); while os.clock()-t0 < (timeoutSec or 5) do if (R(npc).Position-targetPos).Magnitude < 3 then return true end RunService.Heartbeat:Wait() end
    return false
  end
  for _,wp in ipairs(path:GetWaypoints()) do
    h:MoveTo(wp.Position)
    local t0=os.clock(); local reached=false
    while os.clock()-t0 < (timeoutSec or 5) do if (R(npc).Position-wp.Position).Magnitude < 3 then reached=true; break end RunService.Heartbeat:Wait() end
    if not reached then h.Jump=true; h:MoveTo(wp.Position); local t1=os.clock(); while os.clock()-t1 < 2 do if (R(npc).Position-wp.Position).Magnitude < 3 then reached=true; break end RunService.Heartbeat:Wait() end end
    if not reached then return false end
  end
  return true
end

local function wander(npc, center, radius)
  center = center or (R(npc) and R(npc).Position) or Vector3.new(); radius = radius or 12
  local offset = Vector3.new(math.random(-radius,radius),0,math.random(-radius,radius))
  moveTo(npc, center+offset, 3)
end

local function sipVisual(part)
  if not part or not part:IsA("BasePart") then return end
  if part:GetAttribute("SipCooldown") then return end
  part:SetAttribute("SipCooldown", true)
  local c, t = part.Color, part.Transparency
  TweenService:Create(part, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color=c:Lerp(Color3.new(.6,.6,.6), .5), Transparency=math.clamp(t+.1,0,.9)}):Play()
  task.delay(0.3, function()
    TweenService:Create(part, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Color=c, Transparency=t}):Play()
    task.delay(0.2, function() part:SetAttribute("SipCooldown", nil) end)
  end)
end

local function sipOnce(npc, part)
  npc:SetAttribute("NPC_Energy", (npc:GetAttribute("NPC_Energy") or 0) + (World.EnergyPerSip or 4))
  sipVisual(part)
end

local function findSipBlock()
  local tag = World.SipBlockTag
  if tag and tag ~= "" then
    local tagged = CollectionService:GetTagged(tag)
    if #tagged > 0 then
      for i=1,#tagged do
        local p = tagged[((i+math.random(0,#tagged-1)-1)%#tagged)+1]
        if p and p:IsA("BasePart") then return p end
      end
    end
  end
  local roots = {}
  for _, name in ipairs(World.SipRoots or {}) do
    for _, d in ipairs(workspace:GetDescendants()) do if d.Name == name then table.insert(roots, d) end end
  end
  if #roots == 0 then roots = {workspace} end
  for _, r in ipairs(roots) do
    for _, d in ipairs(r:GetDescendants()) do
      if d:IsA("BasePart") then
        local nm = string.lower(d.Name)
        if (d.Material == Enum.Material.Neon) or nm:find("block") or nm:find("color") or nm:find("pad") then return d end
      end
    end
  end
end

local function findDeposit()
  for _, name in ipairs(World.DepositTargets or {"Prism"}) do
    for _, d in ipairs(workspace:GetDescendants()) do if d.Name == name then return d end end
  end
end

local function mainLoop(npc)
  -- immediate shove away from the pad so it doesn't cluster
  wander(npc, playerPadCF().Position, 26)
  while npc.Parent do
    local block = findSipBlock()
    if block then
      local dest = worldPos(block) + Vector3.new(math.random(-3,3),0,math.random(-3,3))
      if moveTo(npc, dest, 7) then
        local a,b = (World.SipsPerStop or {3,6})[1], (World.SipsPerStop or {3,6})[2]
        for i=1, math.random(a,b) do sipOnce(npc, block); task.wait(0.5 + math.random()) end
      else
        wander(npc, dest, 14)
      end
    else
      wander(npc, nil, 14)
    end
    if (npc:GetAttribute("NPC_Energy") or 0) >= (World.DepositThreshold or 28) then
      local depot = findDeposit()
      if depot then
        local pos = worldPos(depot) + Vector3.new(math.random(-3,3),0,math.random(-3,3))
        if moveTo(npc, pos, 8) then npc:SetAttribute("NPC_Energy", 0) end
      end
    end
    task.wait(0.5 + math.random())
  end
end

-- Spawner + periodic stats
task.spawn(function()
  while true do
    task.wait(3)
    local count = 0
    for _,m in ipairs(workspace:GetChildren()) do
      if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") and (m:GetAttribute("NovaNPC") or CollectionService:HasTag(m,"NovaNPC")) then count += 1 end
    end
    for i=1, math.max(0, (MAX) - count) do
      local npc = spawnNPC(i); task.spawn(function() mainLoop(npc) end)
    end
    -- Broadcast NPC energy to scoreboard
    local stats = {}
    for _,m in ipairs(workspace:GetChildren()) do
      if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") and (m:GetAttribute("NovaNPC") or CollectionService:HasTag(m,"NovaNPC")) then
        table.insert(stats, {name = (m:FindFirstChildOfClass("Humanoid") and m:FindFirstChildOfClass("Humanoid").DisplayName) or m.Name, energy = m:GetAttribute("NPC_Energy") or 0})
      end
    end
    Remotes.NPCStatsUpdate:FireAllClients(stats)
  end
end)
