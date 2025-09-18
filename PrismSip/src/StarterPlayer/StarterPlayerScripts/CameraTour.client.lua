local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local camera = workspace.CurrentCamera
local targets = {}
local Prism = ReplicatedStorage:FindFirstChild("Prism")
if Prism and Prism:FindFirstChild("Config") and Prism.Config:FindFirstChild("WorldAnchors.Auto") then
  local ok, mod = pcall(function() return require(Prism.Config["WorldAnchors.Auto"]) end)
  if ok and type(mod)=="table" and type(mod.anchors)=="table" then
    for _, a in ipairs(mod.anchors) do table.insert(targets, {kind="anchor", cf=CFrame.new(unpack(a.cframe)), name=a.name or "Anchor"}) end
  end
end
for _, d in ipairs(workspace:GetDescendants()) do
  if d:IsA("BasePart") and (d.Name=="SGZone1" or d.Name=="SGZone2" or d.Name=="SGZone3") then table.insert(targets, {kind="zone", cf=d.CFrame + Vector3.new(0, d.Size.Y + 6, 0), name=d.Name}) end
end
local idx=0
local function jump()
  if #targets==0 then warn("[CameraTour] No anchors/zones found."); return end
  idx = (idx % #targets) + 1
  local t = targets[idx]; camera.CameraType=Enum.CameraType.Scriptable; camera.CFrame = t.cf * CFrame.Angles(0, math.rad(180), 0)
  print(("[CameraTour] #%d -> %s: %s"):format(idx, t.kind, t.name))
end
UserInputService.InputBegan:Connect(function(input,gp) if not gp and input.KeyCode==Enum.KeyCode.F9 then jump() end end)
