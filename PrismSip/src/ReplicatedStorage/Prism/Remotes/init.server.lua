local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Prism = ReplicatedStorage:FindFirstChild("Prism") or Instance.new("Folder", ReplicatedStorage); Prism.Name = "Prism"
local Remotes = Prism:FindFirstChild("Remotes") or Instance.new("Folder", Prism); Remotes.Name = "Remotes"

local function ensure(name, className)
  local f = Remotes:FindFirstChild(name)
  if not f then f = Instance.new(className); f.Name = name; f.Parent = Remotes end
  return f
end

ensure("Sip", "RemoteEvent")
ensure("EnergyChanged", "RemoteEvent")
ensure("CosmeticChanged", "RemoteEvent")
ensure("QuestProgress", "RemoteEvent")
ensure("EventDropSpawned", "RemoteEvent")
ensure("EventDropClaim", "RemoteFunction")

return Remotes
