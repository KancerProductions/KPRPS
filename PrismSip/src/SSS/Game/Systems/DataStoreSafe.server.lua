-- ServerScriptService/Game/Systems/DataStoreSafe
local DataStoreService = game:GetService("DataStoreService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")

local DATASTORE_NAME = "PrismSip_PlayerData"
local MAX_RETRIES    = 5
local BACKOFF_SEC    = 0.25
local RATE_LIMIT_MS  = 150

local ok, ds = pcall(function() return DataStoreService:GetDataStore(DATASTORE_NAME) end)
local FALLBACK_MODE = (not ok) or RunService:IsStudio()

local mem, lastTouch = {}, {}
local function nowMs() return os.clock() * 1000 end
local function throttle(tag)
	local t, prev = nowMs(), lastTouch[tag] or 0
	if t - prev < RATE_LIMIT_MS then task.wait((RATE_LIMIT_MS - (t - prev))/1000) end
	lastTouch[tag] = nowMs()
end
local function userKey(userId, key) return ("u_%s:%s"):format(userId, key) end
local function backoffTry(fn, op)
	for i=1,MAX_RETRIES do
		local ok, a = pcall(fn)
		if ok then return true, a end
		task.wait((BACKOFF_SEC*(2^(i-1)))*(1+math.random()*0.15))
		warn(("[DataStoreSafe] %s failed (%d/%d): %s"):format(op,i,MAX_RETRIES,tostring(a)))
	end
	return false, ("[DataStoreSafe] %s failed after %d attempts"):format(op, MAX_RETRIES)
end

local API = {}
function API:Get(userId, key, default)
	local k = userKey(userId, key); throttle("GET:"..k)
	if FALLBACK_MODE then return mem[k] ~= nil and mem[k] or default end
	local ok, val = backoffTry(function() return ds:GetAsync(k) end, "GetAsync("..k..")")
	if not ok then return default end
	return val == nil and default or val
end
function API:Set(userId, key, value)
	local k = userKey(userId, key); throttle("SET:"..k)
	if FALLBACK_MODE then mem[k] = value; return true end
	local ok = backoffTry(function() ds:SetAsync(k, value) return true end, "SetAsync("..k..")")
	return ok
end
function API:Increment(userId, key, delta)
	delta = tonumber(delta) or 0
	local k = userKey(userId, key); throttle("INCR:"..k)
	if FALLBACK_MODE then
		local v = tonumber(mem[k]) or 0; v += delta; mem[k] = v; return v
	end
	local ok, res = backoffTry(function() return ds:IncrementAsync(k, delta) end, "IncrementAsync("..k..")")
	return ok and res or nil
end
function API:Dump(userId, keys)
	local out = {}
	for _, key in ipairs(keys or {}) do out[key] = self:Get(userId, key, nil) end
	return HttpService:JSONEncode(out)
end
_G.DataStoreSafe = API
print(("[DataStoreSafe] Ready (fallback=%s, name=%s)"):format(tostring(FALLBACK_MODE), DATASTORE_NAME))
