-- ServerScriptService/Game/Systems/PlayerPadSpawn.server.lua (007c)
-- Fix: FULL_PATH resolver now treats the first token 'Workspace' specially.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Prism"):WaitForChild("Config"):WaitForChild("PlayerPadPath"))

local function pathToInstance(pathStr)
	if not pathStr or pathStr == "" then return nil end
	local tokens = {}
	for token in string.gmatch(pathStr, "[^%.]+") do table.insert(tokens, token) end
	if #tokens == 0 then return nil end

	local current
	-- handle first hop
	if tokens[1] == "Workspace" then
		current = workspace
	else
		-- allow game.<Service>
		current = game:FindFirstChild(tokens[1]) or game:GetService(tokens[1])
		if not current then return nil end
	end
	-- walk remaining
	for i = 2, #tokens do
		current = current and current:FindFirstChild(tokens[i])
		if not current then return nil end
	end
	return current
end

local function findPlayerPad()
	-- 1) Explicit path override
	local inst = pathToInstance(Config.FULL_PATH)
	if inst and inst:IsA("BasePart") then return inst, "explicit-path:"..Config.FULL_PATH end

	-- 2) Tagged parts
	for _, tag in ipairs(Config.TAGS or {}) do
		for _, obj in ipairs(CollectionService:GetTagged(tag)) do
			if obj:IsA("BasePart") then return obj, "tag:"..tag end
		end
	end

	-- 3) Descendant search by candidates (case-insensitive exact)
	local nameSet = {}
	for _, n in ipairs(Config.NAME_CANDIDATES or {}) do nameSet[string.lower(n)] = true end
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BasePart") then
			if nameSet[string.lower(d.Name)] then return d, "name:"..d.Name end
		end
	end

	-- 4) Direct child
	local direct = workspace:FindFirstChild("PlayerPad")
	if direct and direct:IsA("BasePart") then return direct, "direct-child:Workspace.PlayerPad" end

	return nil, "not-found"
end

local function ensureSpawnAt(cf)
	local existing
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("SpawnLocation") then existing = inst; break end
	end
	if not existing then
		existing = Instance.new("SpawnLocation")
		existing.Size = Vector3.new(6,1,6)
		existing.Transparency = 1
		existing.Anchored = true
		existing.CanCollide = true
		existing.Name = "LobbySpawn"
		existing.Parent = workspace
	end
	existing.CFrame = cf + Vector3.new(0, 3, 0)
	return existing
end

task.defer(function()
	local pad, how = findPlayerPad()
	if not pad then
		warn("[PlayerPadSpawn] PlayerPad NOT FOUND ("..how.."). FULL_PATH='"..tostring(Config.FULL_PATH).."'.")
		return
	end
	pcall(function() CollectionService:AddTag(pad, "NPCSpawn") end)
	pcall(function() CollectionService:AddTag(pad, "PlayerPad") end)
	ensureSpawnAt(pad.CFrame)
	print(("[PlayerPadSpawn] Using %s (%s) as player spawn + NPC anchor."):format(pad:GetFullName(), how))
end)
