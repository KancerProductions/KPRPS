-- StarterPlayer/StarterPlayerScripts/AnchorBeacons.client.lua (RUNTIME)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Prism = ReplicatedStorage:WaitForChild("Prism")
local Config = Prism:WaitForChild("Config")
local Runtime = Config:FindFirstChild("WorldAnchorsRuntime")

if not Runtime then warn("[AnchorBeacons] No runtime anchors yet."); return end

local folder = workspace:FindFirstChild("AnchorBeacons") or Instance.new("Folder", workspace); folder.Name="AnchorBeacons"

for _, v in ipairs(Runtime:GetChildren()) do
	if v:IsA("Vector3Value") then
		local p = Instance.new("Part"); p.Name=v.Name; p.Size=Vector3.new(0.8,2.4,0.8); p.Anchored=true; p.CanCollide=false; p.Material=Enum.Material.Neon
		p.Color = Color3.fromRGB(120,220,255); p.Position = v.Value; p.Parent = folder
	end
end
