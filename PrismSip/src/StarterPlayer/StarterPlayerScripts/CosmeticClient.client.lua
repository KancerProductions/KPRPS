-- StarterPlayer/StarterPlayerScripts/CosmeticClient.client.lua (FIXED REMOTES)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Prism = ReplicatedStorage:WaitForChild("Prism")
local Remotes = Prism:WaitForChild("Remotes")
local Cosmetics = require(Prism.Config.Cosmetics)

local player = Players.LocalPlayer
local function apply(id)
	local def = Cosmetics[id]; if not def then return end
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart", 5) or char:WaitForChild("UpperTorso", 5)
	if not hrp then return end
	local att1 = Instance.new("Attachment", hrp); att1.Position = Vector3.new(0,0.5,0)
	local att2 = Instance.new("Attachment", hrp); att2.Position = Vector3.new(0,-0.5,0)
	local trail = Instance.new("Trail"); trail.Attachment0=att1; trail.Attachment1=att2
	trail.Color = ColorSequence.new(def.color or Color3.fromRGB(255,255,255)); trail.Lifetime=0.4; trail.MinLength=0.1
	trail.WidthScale = NumberSequence.new(def.trailWidth or 0.6); trail.Parent = hrp
end
Remotes:WaitForChild("CosmeticChanged").OnClientEvent:Connect(function(id) apply(id) end)
