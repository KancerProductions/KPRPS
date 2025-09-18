-- Hi kancer this is a test

local Players = game:GetService("Players")
local function setup(plr)
	local ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = plr
	local color = Instance.new("IntValue"); color.Name = "Color"; color.Value = 0; color.Parent = ls
	plr:SetAttribute("Pigment", 0)
end
for _,p in ipairs(Players:GetPlayers()) do setup(p) end
Players.PlayerAdded:Connect(setup)