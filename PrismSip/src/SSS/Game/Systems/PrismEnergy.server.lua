-- ServerScriptService/Game/Systems/PrismEnergy.server.lua (FIXED REMOTES)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Flags = require(ReplicatedStorage.Prism.Config.FeatureFlags)
local Zones = require(ReplicatedStorage.Prism.Config.ZoneConfig)
local Remotes = require(script.Parent:WaitForChild("_RemotesUtil.module"))

local ENERGY_PER_SIP = 1

local function ensureLeaderstats(player)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = player end
	local e = ls:FindFirstChild("PrismEnergy")
	if not e then e = Instance.new("IntValue"); e.Name = "PrismEnergy"; e.Value = 0; e.Parent = ls end
	return e
end

local function currentZoneBoost(char)
	if not char or not char:FindFirstChild("HumanoidRootPart") then return 1.0 end
	local hrp = char.HumanoidRootPart
	local region = Region3.new(hrp.Position - Vector3.new(8,8,8), hrp.Position + Vector3.new(8,8,8))
	local parts = workspace:FindPartsInRegion3(region, char, 20)
	for _, p in ipairs(parts) do
		for zoneName, data in pairs(Zones) do
			if game:GetService("CollectionService"):HasTag(p, zoneName) or p.Name == zoneName then
				return data.boost or 1.0
			end
		end
	end
	return 1.0
end

local function onSip(player)
	local energyVal = ensureLeaderstats(player)
	local char = player.Character
	local boost = currentZoneBoost(char)
	local gain = math.floor(ENERGY_PER_SIP * boost)
	energyVal.Value += gain
	Remotes:WaitForChild("EnergyChanged"):FireClient(player, energyVal.Value, gain, boost)
end

Remotes:WaitForChild("Sip").OnServerEvent:Connect(function(player) onSip(player) end)
Players.PlayerAdded:Connect(function(plr) ensureLeaderstats(plr) end)
