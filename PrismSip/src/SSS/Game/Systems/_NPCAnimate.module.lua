-- ServerScriptService/Game/Systems/_NPCAnimate.module.lua (010)
local AnimIds = {
  idle = 507766666,
  walk = 507777826,
  run  = 507767714,
}

local function load(h)
  local animator = h:FindFirstChildOfClass("Animator") or Instance.new("Animator", h)
  local idleAnim = Instance.new("Animation"); idleAnim.AnimationId = "rbxassetid://"..AnimIds.idle
  local walkAnim = Instance.new("Animation"); walkAnim.AnimationId = "rbxassetid://"..AnimIds.walk
  local runAnim  = Instance.new("Animation");  runAnim.AnimationId  = "rbxassetid://"..AnimIds.run
  local tracks = {
    idle = animator:LoadAnimation(idleAnim),
    walk = animator:LoadAnimation(walkAnim),
    run  = animator:LoadAnimation(runAnim),
  }
  tracks.idle.Looped = true; tracks.walk.Looped = true; tracks.run.Looped = true
  tracks.idle:Play()
  h.Running:Connect(function(speed)
    if speed > 14 then
      if tracks.idle.IsPlaying then tracks.idle:Stop(0.1) end
      if tracks.walk.IsPlaying then tracks.walk:Stop(0.1) end
      if not tracks.run.IsPlaying then tracks.run:Play(0.1) end
    elseif speed > 2 then
      if tracks.idle.IsPlaying then tracks.idle:Stop(0.1) end
      if tracks.run.IsPlaying then tracks.run:Stop(0.1) end
      if not tracks.walk.IsPlaying then tracks.walk:Play(0.1) end
    else
      if tracks.walk.IsPlaying then tracks.walk:Stop(0.1) end
      if tracks.run.IsPlaying then tracks.run:Stop(0.1) end
      if not tracks.idle.IsPlaying then tracks.idle:Play(0.1) end
    end
  end)
  return tracks
end

return load
