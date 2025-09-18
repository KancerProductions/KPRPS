-- ServerScriptService/Game/Systems/WorldAnchorProbe.server.lua (RUNTIME SAFE)
-- Populates ReplicatedStorage.Prism.Config.WorldAnchorsRuntime (Folder) with Vector3Value children for anchor positions.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Prism = ReplicatedStorage:FindFirstChild("Prism") or Instance.new("Folder", ReplicatedStorage); Prism.Name="Prism"
local Config = Prism:FindFirstChild("Config") or Instance.new("Folder", Prism); Config.Name="Config"

local Runtime = Config:FindFirstChild("WorldAnchorsRuntime") or Instance.new("Folder", Config); Runtime.Name = "WorldAnchorsRuntime"

local function addAnchor(name, cf)
	local v = Runtime:FindFirstChild(name) or Instance.new("Vector3Value", Runtime)
	v.Name = name
	v.Value = cf.Position
end

local function gather()
	local list = {}
	for _, inst in ipairs(CollectionService:GetTagged("NPCSpawn")) do
		if inst:IsA("BasePart") then addAnchor(inst.Name, inst.CFrame) end
	end
	for _, name in ipairs({"LobbyAnchor","NPCSpawn1","NPCSpawn2","NPCSpawn3"}) do
		local p = workspace:FindFirstChild(name, true)
		if p and p:IsA("BasePart") then addAnchor(name, p.CFrame) end
	end
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("SpawnLocation") then addAnchor(inst.Name ~= "" and inst.Name or "SpawnLocation", inst.CFrame + Vector3.new(0,3,0)) end
	end
end

gather()

-- If still empty, record first player spawn positions
if #Runtime:GetChildren() == 0 then
	local recorded = {}
	local function onChar(plr, char)
		local hrp = char:WaitForChild("HumanoidRootPart", 5) or char:FindFirstChild("Torso")
		if hrp and not recorded[plr.UserId] then
			recorded[plr.UserId] = true
			addAnchor("PlayerSpawn_"..plr.UserId, hrp.CFrame)
		end
	end
	Players.PlayerAdded:Connect(function(plr) plr.CharacterAdded:Connect(function(c) onChar(plr, c) end) end)
	for _,plr in ipairs(Players:GetPlayers()) do if plr.Character then onChar(plr, plr.Character) end plr.CharacterAdded:Connect(function(c) onChar(plr,c) end) end
end
