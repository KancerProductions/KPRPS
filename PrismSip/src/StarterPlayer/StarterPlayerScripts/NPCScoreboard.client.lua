local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Prism"):WaitForChild("Remotes")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui"); gui.Name="PrismScoreboard"; gui.ResetOnSpawn=false; gui.Parent=player:WaitForChild("PlayerGui")
local frame = Instance.new("Frame"); frame.Name="Board"; frame.BackgroundTransparency=0.2; frame.BackgroundColor3=Color3.fromRGB(25,25,35)
frame.Position=UDim2.new(1,-260,0,60); frame.Size=UDim2.new(0,240,0,240); frame.Parent=gui
local ui = Instance.new("UIListLayout"); ui.Parent=frame; ui.Padding=UDim.new(0,4)
local title = Instance.new("TextLabel"); title.BackgroundTransparency=1; title.Font=Enum.Font.GothamBold; title.TextSize=16; title.TextColor3=Color3.new(1,1,1)
title.Text="Sips (Players + NPCs)"; title.Size=UDim2.new(1,0,0,22); title.Parent=frame
local function row(text)
  local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Font=Enum.Font.Gotham; l.TextSize=14; l.TextColor3=Color3.fromRGB(220,230,255)
  l.Size=UDim2.new(1,-10,0,18); l.TextXAlignment=Enum.TextXAlignment.Left; l.Text=text; l.Parent=frame
end
local function buildPlayers()
  for _,c in ipairs(frame:GetChildren()) do if c:IsA("TextLabel") and c~=title then c:Destroy() end end
  for _,p in ipairs(Players:GetPlayers()) do
    local ls=p:FindFirstChild("leaderstats"); local e=ls and ls:FindFirstChild("PrismEnergy")
    row(("🧑 %s — %d"):format(p.DisplayName or p.Name, e and e.Value or 0))
  end
end
Players.PlayerAdded:Connect(buildPlayers); Players.PlayerRemoving:Connect(buildPlayers)
task.spawn(buildPlayers)
Remotes.NPCStatsUpdate.OnClientEvent:Connect(function(list)
  buildPlayers()
  if typeof(list)=="table" then
    for _,it in ipairs(list) do row(("🤖 %s — %d"):format(it.name, it.energy or 0)) end
  end
end)
