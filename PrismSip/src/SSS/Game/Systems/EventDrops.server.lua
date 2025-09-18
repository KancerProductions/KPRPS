-- ServerScriptService/Game/Systems/EventDrops.server.lua (FIXED REMOTES)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local Flags = require(ReplicatedStorage.Prism.Config.FeatureFlags)
local Remotes = require(script.Parent:WaitForChild("_RemotesUtil.module"))

local DROP_INTERVAL = 45
local BONUS_ENERGY = 15

local function spawnDrop()
	if not workspace:FindFirstChild("EventDrops") then
		local f = Instance.new("Folder"); f.Name = "EventDrops"; f.Parent = workspace
	end
	local part = Instance.new("Part")
	part.Name = "PrismDrop"; part.Shape = Enum.PartType.Ball; part.Size = Vector3.new(1.5,1.5,1.5)
	part.Color = Color3.fromRGB(255,230,80); part.Material = Enum.Material.Neon
	part.Anchored = false; part.CanQuery = true
	part.Position = Vector3.new(0, 20, 0) + Vector3.new(math.random(-40,40), 0, math.random(-40,40))
	part.Parent = workspace.EventDrops
	part.Touched:Connect(function(hit)
		local char = hit.Parent; local plr = char and game:GetService("Players"):GetPlayerFromCharacter(char)
		if not plr or part:GetAttribute("claimed") then return end
		part:SetAttribute("claimed", true)
		local ls = plr:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("PrismEnergy") then
			ls.PrismEnergy.Value += BONUS_ENERGY
			Remotes:WaitForChild("EnergyChanged"):FireClient(plr, ls.PrismEnergy.Value, BONUS_ENERGY, 1.0)
		end
		part.Anchored = true; part.Color = Color3.fromRGB(120,255,120)
		Debris:AddItem(part, 2)
	end)
	Remotes:WaitForChild("EventDropSpawned"):FireAllClients(part.Position)
	Debris:AddItem(part, 25)
end

task.spawn(function()
	while task.wait(DROP_INTERVAL) do
		if Flags.EventDrops then spawnDrop() end
	end
end)
