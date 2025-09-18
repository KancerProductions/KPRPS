-- Game/Systems/BoundaryBehavior.Server.lua (v6.1)
-- Invisible boundaries everywhere.
-- NPCBarrier = pass-through.
-- SpawnPlayerBoundaries = solid + RED PULSE ONLY (no bounce).
-- PlayerBoundaries = solid + SOFT BOUNCE + RED PULSE.
-- Exact (case-insensitive) name matches.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local CFG = {
	BounceSpeed    = 85,
	BounceCooldown = 0.25,
	WarnDistance   = 6,      -- studs to start pulsing
	FlashAlpha     = 0.88,   -- 0..1 (higher = more transparent)
	FlashTime      = 0.25,   -- seconds
}

-- ---------- helpers ----------
local function partsUnder(x)
	if not x then return {} end
	if x:IsA("BasePart") then return {x} end
	local t = {}
	for _,d in ipairs(x:GetDescendants()) do
		if d:IsA("BasePart") then table.insert(t, d) end
	end
	return t
end

-- EXACT (case-insensitive) match anywhere under Boundaries
local function findRootsByNameExact(container, name)
	local out = {}
	if not container then return out end
	local needle = string.lower(name)
	for _,d in ipairs(container:GetDescendants()) do
		if string.lower(d.Name) == needle then table.insert(out, d) end
	end
	return out
end

local function hideVisuals(root)
	for _,d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then d.Transparency = 1; d.CastShadow = false end
		if d:IsA("Decal") or d:IsA("Texture") then d.Transparency = 1 end
		if d:IsA("SurfaceGui") or d:IsA("BillboardGui") then d.Enabled = false end
		if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Highlight") then d.Enabled = false end
	end
end

local function enableTouchesForCharacter(char)
	for _,d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then d.CanTouch = true end
	end
end

-- ---------- locate boundaries ----------
local MAP = workspace:WaitForChild("Map")
local B   = MAP:WaitForChild("Boundaries")

local npcRoots  = findRootsByNameExact(B, "NPCBarrier")
local spbRoots  = findRootsByNameExact(B, "SpawnPlayerBoundaries")
local pbRoots   = findRootsByNameExact(B, "PlayerBoundaries")

-- visuals/collisions
hideVisuals(B)
for _,r in ipairs(npcRoots) do for _,p in ipairs(partsUnder(r)) do p.CanCollide=false; p.CanQuery=true; p.CanTouch=true end end
for _,r in ipairs(spbRoots) do for _,p in ipairs(partsUnder(r)) do p.CanCollide=true;  p.CanQuery=true; p.CanTouch=true end end
for _,r in ipairs(pbRoots)  do for _,p in ipairs(partsUnder(r)) do p.CanCollide=true;  p.CanQuery=true; p.CanTouch=true end end

-- ensure players fire Touched
for _,plr in ipairs(Players:GetPlayers()) do if plr.Character then enableTouchesForCharacter(plr.Character) end end
Players.PlayerAdded:Connect(function(plr) plr.CharacterAdded:Connect(enableTouchesForCharacter) end)

-- ---------- red pulse (shared by spawn + player walls) ----------
local lastFlashAt = setmetatable({}, {__mode="k"})
local function flashPart(part)
	local now = os.clock()
	if lastFlashAt[part] and (now - lastFlashAt[part]) < (CFG.FlashTime * 0.5) then return end
	lastFlashAt[part] = now
	local oldC, oldM = part.Color, part.Material
	part.Transparency = CFG.FlashAlpha
	part.Material     = Enum.Material.Neon
	part.Color        = Color3.fromRGB(255, 80, 80)
	task.delay(CFG.FlashTime, function()
		if part and part.Parent then
			part.Transparency = 1
			part.Material     = oldM
			part.Color        = oldC
		end
	end)
end

-- ---------- bounce (PlayerBoundaries only) ----------
local function outwardNormal(part, worldPoint)
	local cf, sz = part.CFrame, part.Size
	local lp = cf:PointToObjectSpace(worldPoint)
	local hx, hz = math.max(sz.X*0.5,1e-3), math.max(sz.Z*0.5,1e-3)
	local ax, az = math.abs(lp.X)/hx, math.abs(lp.Z)/hz
	local nLocal = (ax > az) and Vector3.new(lp.X>=0 and 1 or -1, 0, 0) or Vector3.new(0,0,lp.Z>=0 and 1 or -1)
	return cf:VectorToWorldSpace(nLocal)
end

local function pushBack(char, wallPart)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum and wallPart and wallPart:IsA("BasePart")) then return end
	local tNow   = os.clock()
	local nextOk = char:GetAttribute("NextBounceAt") or 0
	if tNow < nextOk then return end
	char:SetAttribute("NextBounceAt", tNow + CFG.BounceCooldown)

	local n = outwardNormal(wallPart, hrp.Position)
	hrp.CFrame = CFrame.new(hrp.Position + n * 1.5) * hrp.CFrame.Rotation
	local v = hrp.AssemblyLinearVelocity
	hrp.AssemblyLinearVelocity = Vector3.new(n.X*CFG.BounceSpeed, v.Y, n.Z*CFG.BounceSpeed)
	flashPart(wallPart)
end

-- hook Touched for PB bounce; we also flash on touch for both PB and SPB
local pbParts, spbParts = {}, {}
for _,r in ipairs(pbRoots)  do for _,p in ipairs(partsUnder(r)) do table.insert(pbParts,  p) end end
for _,r in ipairs(spbRoots) do for _,p in ipairs(partsUnder(r)) do table.insert(spbParts, p) end end

for _,p in ipairs(pbParts) do
	p.Touched:Connect(function(hit)
		local char = hit and hit.Parent
		if char and char:FindFirstChildOfClass("Humanoid") and Players:GetPlayerFromCharacter(char) then
			pushBack(char, p)       -- bounce + flash
		end
	end)
end
for _,p in ipairs(spbParts) do
	p.Touched:Connect(function(hit)
		local char = hit and hit.Parent
		if char and char:FindFirstChildOfClass("Humanoid") and Players:GetPlayerFromCharacter(char) then
			flashPart(p)            -- flash only (NO bounce)
		end
	end)
end

-- proximity pulse every frame:
RunService.Heartbeat:Connect(function()
	-- flatten once per tick (cheap)
	for _,plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character; if not char then continue end
		local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
		local pos  = hrp.Position

		local function maybeFlash(w)
			local cf, sz = w.CFrame, w.Size
			local lp = cf:PointToObjectSpace(pos)
			local hx, hz = sz.X*0.5, sz.Z*0.5
			local dx = math.max(0, math.abs(lp.X)-hx)
			local dz = math.max(0, math.abs(lp.Z)-hz)
			local dist = math.sqrt(dx*dx + dz*dz)
			if dist <= CFG.WarnDistance then flashPart(w) end
		end

		for _,w in ipairs(spbParts) do maybeFlash(w) end              -- spawn walls: flash only
		for _,w in ipairs(pbParts) do                                 -- player walls: flash + fallback bounce if inside
			maybeFlash(w)
			local cf, sz = w.CFrame, w.Size
			local lp = cf:PointToObjectSpace(pos)
			local hx, hz = sz.X*0.5, sz.Z*0.5
			local dx = math.max(0, math.abs(lp.X)-hx)
			local dz = math.max(0, math.abs(lp.Z)-hz)
			local dist = math.sqrt(dx*dx + dz*dz)
			if dist < 0.25 or (math.abs(lp.X) < hx and math.abs(lp.Z) < hz) then
				pushBack(char, w)
			end
		end
	end
end)

print(("[Boundaries v6.1] PlayerBoundaries=%d | SpawnPlayerBoundaries=%d | NPC=%d (pulse on both; bounce on PB only).")
	:format(#pbRoots, #spbRoots, #npcRoots))