-- Game/Systems/ColorSip.Server.lua (v1.5)
-- SGZone1/2/3 scattering with large margin & overlap check vs PlayerBoundaries (found recursively).
-- Deposit at Map/Prism.

local CFG = {
	MAP_PATH       = {"Map"},
	GROUNDS_FOLDER = "Grounds",
	ZONES = {
		{ name = "SGZone1", count = 2,  minDist = 12, units = NumberRange.new(3, 6)  },
		{ name = "SGZone2", count = 14, minDist = 12, units = NumberRange.new(7, 12) },
		{ name = "SGZone3", count = 28, minDist = 12, units = NumberRange.new(12, 20)},
	},

	PROP_SIZE       = Vector3.new(4,4,4),
	SIP_AMOUNT      = 1,
	COOLDOWN_SEC    = 0.15,
	RESPAWN_TIME    = NumberRange.new(8,14),
	NORMAL_Y_MIN    = 0.75,
	EDGE_MARGIN     = 18.0,  -- << bigger clearance from PlayerBoundaries (studs)
	RAY_HEIGHT      = 160,

	DEPOSIT_VALUE   = 1,
	COMBO_WINDOW    = 4.0,
	COMBO_BONUS     = 0.15,

	COLORS = {
		Color3.fromRGB(255,126,126), Color3.fromRGB(255,199,115), Color3.fromRGB(255,246,137),
		Color3.fromRGB(135,246,144), Color3.fromRGB(126,213,255), Color3.fromRGB(186,160,255),
	},
	GRAY = Color3.fromRGB(210,210,210),
}

-- ---------- utils ----------
local function path(root, names) local cur=root; for _,n in ipairs(names) do cur=cur:FindFirstChild(n); if not cur then return nil end end; return cur end
local function partsUnder(x) if not x then return {} end; if x:IsA("BasePart") then return {x} end; local t={}; for _,d in ipairs(x:GetDescendants()) do if d:IsA("BasePart") then table.insert(t,d) end end; return t end
local function getSurfaceParts(inst) if inst:IsA("BasePart") then return {inst} end; local t={}; for _,d in ipairs(inst:GetDescendants()) do if d:IsA("BasePart") then table.insert(t,d) end end; return t end
local function getBBox(inst) if inst:IsA("Model") then local cf,sz=inst:GetBoundingBox(); return cf,sz else return inst.CFrame,inst.Size end end
local function randf(a,b) return a + math.random()*(b-a) end
local function choose(t) return t[math.random(1,#t)] end
local function dist2D_PointToPartAABB(p, part)
	local cf,sz=part.CFrame,part.Size; local lp=cf:PointToObjectSpace(p)
	local hx,hz=sz.X*0.5,sz.Z*0.5; local dx=math.max(0,math.abs(lp.X)-hx); local dz=math.max(0,math.abs(lp.Z)-hz)
	if dx<=0 and dz<=0 then return 0 else return math.sqrt(dx*dx+dz*dz) end
end

-- find ANY descendants named like "PlayerBoundaries" (case-insensitive, partial match ok)
local function findRootsByNameLike(container, needleLower)
	local roots = {}
	if not container then return roots end
	local target = string.lower(needleLower)
	for _,d in ipairs(container:GetDescendants()) do
		if string.find(string.lower(d.Name), target, 1, true) then table.insert(roots, d) end
	end
	return roots
end

local function inAnyRoot(part, roots)
	for _,r in ipairs(roots or {}) do if part:IsDescendantOf(r) then return true end end
	return false
end

-- ---------- scatter ----------
local function scatterOnZone(zonePart, count, minDist, boundaryParts, pbRoots)
	local pts, tries, maxTries = {}, 0, count*320

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Whitelist
	rayParams.FilterDescendantsInstances = getSurfaceParts(zonePart)
	rayParams.IgnoreWater = true

	local cf, sz = getBBox(zonePart)
	local halfX, halfZ = sz.X*0.5, sz.Z*0.5
	local testBoxSize = Vector3.new(CFG.PROP_SIZE.X + 2*CFG.EDGE_MARGIN, 14, CFG.PROP_SIZE.Z + 2*CFG.EDGE_MARGIN)

	local boundarySet = {}; for _,p in ipairs(boundaryParts or {}) do boundarySet[p]=true end

	local function farEnough(p)
		for _,q in ipairs(pts) do
			local dx, dz = p.X-q.X, p.Z-q.Z
			if (dx*dx + dz*dz) < (minDist*minDist) then return false end
		end
		for _,w in ipairs(boundaryParts or {}) do
			if dist2D_PointToPartAABB(p, w) < (CFG.EDGE_MARGIN + CFG.PROP_SIZE.X*0.5) then return false end
		end
		if boundaryParts and #boundaryParts > 0 then
			local hits = workspace:GetPartBoundsInBox(CFrame.new(p + Vector3.new(0, testBoxSize.Y*0.5, 0)), testBoxSize)
			for _,h in ipairs(hits) do
				if boundarySet[h] or inAnyRoot(h, pbRoots) then return false end
			end
		end
		return true
	end

	while #pts < count and tries < maxTries do
		tries += 1
		local lx, lz = (math.random()*2-1)*halfX, (math.random()*2-1)*halfZ
		local start = (cf * CFrame.new(lx, sz.Y*0.5 + CFG.RAY_HEIGHT, lz)).Position
		local r = workspace:Raycast(start, Vector3.new(0, -(sz.Y + CFG.RAY_HEIGHT*2), 0), rayParams)
		if r and r.Instance and r.Normal.Y >= CFG.NORMAL_Y_MIN then
			local p = r.Position + r.Normal * 0.5
			if farEnough(p) then table.insert(pts, p) end
		end
	end
	if #pts < count then warn(("[ColorSip] %s: placed %d/%d (margins/area tight)."):format(zonePart.Name, #pts, count)) end
	return pts
end

-- ---------- remotes ----------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:FindFirstChild("ColorSipEvents") or Instance.new("Folder")
Events.Name="ColorSipEvents"; Events.Parent=ReplicatedStorage
local PickupEvent = Events:FindFirstChild("Pickup") or Instance.new("RemoteEvent"); PickupEvent.Name="Pickup"; PickupEvent.Parent=Events
local DepositEvent= Events:FindFirstChild("Deposit") or Instance.new("RemoteEvent"); DepositEvent.Name="Deposit"; DepositEvent.Parent=Events

-- ---------- map refs ----------
local mapRoot = path(workspace, CFG.MAP_PATH); assert(mapRoot, "[ColorSip] Map not found.")
local grounds = mapRoot:FindFirstChild(CFG.GROUNDS_FOLDER); assert(grounds, "[ColorSip] Map/Grounds not found.")
local boundariesFolder = mapRoot:FindFirstChild("Boundaries")

-- find all PlayerBoundaries roots (recursive, case-insensitive)
local pbRoots = findRootsByNameLike(boundariesFolder, "playerboundaries")
local boundaryParts = {}
for _,root in ipairs(pbRoots) do for _,p in ipairs(partsUnder(root)) do table.insert(boundaryParts, p) end end
print(("[ColorSip] Found %d PlayerBoundaries roots; %d parts; EDGE_MARGIN=%0.1f"):format(#pbRoots, #boundaryParts, CFG.EDGE_MARGIN))

-- Prism
local prism = mapRoot:FindFirstChild("Prism")
if not (prism and prism:IsA("BasePart")) then
	prism = Instance.new("Part"); prism.Name="Prism"; prism.Anchored=true; prism.CanCollide=true
	prism.Material=Enum.Material.Neon; prism.Color=Color3.fromRGB(255,245,130)
	prism.Size=Vector3.new(8,10,8); prism.CFrame=CFrame.new(0,6,0); prism.Parent=mapRoot
end
local depo = prism:FindFirstChildOfClass("ProximityPrompt") or Instance.new("ProximityPrompt")
depo.ActionText="Deposit"; depo.ObjectText="Prism"; depo.HoldDuration=0; depo.MaxActivationDistance=12; depo.Parent=prism

local lastDeposit = {}
depo.Triggered:Connect(function(plr)
	local pig = plr:GetAttribute("Pigment") or 0; if pig <= 0 then return end
	local now, mult = time(), 1.0
	if lastDeposit[plr] and (now - lastDeposit[plr]) <= CFG.COMBO_WINDOW then
		local prev = (plr:GetAttribute("PrismStreak") or 1) + 1
		plr:SetAttribute("PrismStreak", prev); mult = 1 + (prev - 1) * CFG.COMBO_BONUS
	else plr:SetAttribute("PrismStreak", 1) end
	lastDeposit[plr] = now
	local gain = math.floor(pig * CFG.DEPOSIT_VALUE * mult)
	local ls = plr:FindFirstChild("leaderstats"); local stat = ls and ls:FindFirstChild("Color"); if stat then stat.Value += gain end
	plr:SetAttribute("Pigment", 0); DepositEvent:FireClient(plr, gain, plr:GetAttribute("PrismStreak") or 1)
end)

-- ---------- prop factory ----------
local TweenService = game:GetService("TweenService")
local propsFolder = workspace:FindFirstChild("ColorProps"); if propsFolder then propsFolder:Destroy() end
propsFolder = Instance.new("Folder"); propsFolder.Name="ColorProps"; propsFolder.Parent=workspace

local function makeProp(pos, zoneName, unitsRange)
	local p = Instance.new("Part")
	p.Name="ColorProp"; p.Anchored=true; p.CanCollide=true; p.CanTouch=true
	p.Material=Enum.Material.SmoothPlastic; p.Size=CFG.PROP_SIZE; p.CFrame=CFrame.new(pos)
	p.Color=choose(CFG.COLORS)
	p:SetAttribute("Zone", zoneName)
	local maxUnits=math.floor(randf(unitsRange.Min,unitsRange.Max))
	p:SetAttribute("UnitsMax",maxUnits); p:SetAttribute("Units",maxUnits); p:SetAttribute("ReadyAt",0)
	p.Parent=propsFolder

	local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,22,0,22); bb.AlwaysOnTop=true; bb.LightInfluence=0; bb.StudsOffset=Vector3.new(0,p.Size.Y*0.6,0); bb.Parent=p
	local dot=Instance.new("TextLabel"); dot.BackgroundTransparency=1; dot.Size=UDim2.fromScale(1,1); dot.Font=Enum.Font.GothamBlack; dot.TextScaled=true; dot.Text="●"; dot.TextColor3=Color3.new(1,1,1); dot.TextStrokeTransparency=0.5; dot.Parent=bb

	local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="Sip"; prompt.ObjectText="Color"; prompt.HoldDuration=0; prompt.MaxActivationDistance=12; prompt.Parent=p

	local function tintByUnits()
		local u=p:GetAttribute("Units") or 0; local m=p:GetAttribute("UnitsMax") or 1
		local k=1 - math.clamp(u/math.max(1,m),0,1); p.Color=p.Color:Lerp(CFG.GRAY,k)
	end

	prompt.Triggered:Connect(function(plr)
		local now=time(); if now < (p:GetAttribute("ReadyAt") or 0) then return end
		p:SetAttribute("ReadyAt", now + CFG.COOLDOWN_SEC)
		local u=p:GetAttribute("Units") or 0; if u<=0 then return end
		local take=math.min(CFG.SIP_AMOUNT,u)
		p:SetAttribute("Units", u - take); tintByUnits()
		local cur=plr:GetAttribute("Pigment") or 0; plr:SetAttribute("Pigment", cur + take)
		PickupEvent:FireClient(plr, take, cur + take)
		if (u - take) <= 0 then
			task.delay(randf(CFG.RESPAWN_TIME.Min, CFG.RESPAWN_TIME.Max), function()
				if p and p.Parent then
					local newMax=math.floor(randf(unitsRange.Min,unitsRange.Max))
					p:SetAttribute("UnitsMax", newMax); p:SetAttribute("Units", newMax)
					p.Color=choose(CFG.COLORS)
				end
			end)
			local out=TweenService:Create(p, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = CFG.PROP_SIZE*0.1})
			out:Play(); out.Completed:Connect(function() TweenService:Create(p, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = CFG.PROP_SIZE}):Play() end)
		end
	end)
end

-- ---------- build ----------
for _,z in ipairs(CFG.ZONES) do
	local mesh=grounds:FindFirstChild(z.name)
	if not (mesh and mesh:IsA("BasePart")) then warn("[ColorSip] Missing zone mesh: "..z.name)
	else
		local pts=scatterOnZone(mesh,z.count,z.minDist,boundaryParts,pbRoots)
		for _,pos in ipairs(pts) do makeProp(pos,z.name,z.units) end
	end
end
print("[ColorSip] Build OK.")
