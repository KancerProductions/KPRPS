-- ServerScriptService/Game/Systems/CosmeticsOnSpawn.server.lua (FIXED REMOTES)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Flags = require(ReplicatedStorage.Prism.Config.FeatureFlags)
local Cosmetics = require(ReplicatedStorage.Prism.Config.Cosmetics)
local Remotes = require(script.Parent:WaitForChild("_RemotesUtil.module"))

local STARTER_ID = "starter"

Players.PlayerAdded:Connect(function(plr)
	if Flags.CosmeticsOnSpawn then
		local def = Cosmetics[STARTER_ID]
		if def then Remotes:WaitForChild("CosmeticChanged"):FireClient(plr, STARTER_ID, def.name) end
	end
end)
