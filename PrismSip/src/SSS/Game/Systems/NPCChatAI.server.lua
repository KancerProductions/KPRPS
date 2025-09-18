-- ServerScriptService/Game/Systems/NPCChatAI.server.lua (008b)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ChatService = game:GetService("Chat")

local Remotes = ReplicatedStorage:WaitForChild("Prism"):WaitForChild("Remotes")

local function bubble(part, text) pcall(function() ChatService:Chat(part, tostring(text), Enum.ChatColor.White) end) end

local greetings = {"hi","hello","hey","yo","sup","hola"}
local funqs = {"tell me something fun","joke","fun fact","funny"}
local followqs = {"follow me","tag along","come with me","team up","squad"}
local stopqs = {"stop","you can stop","go away","dismiss"}

local function containsAny(s, list)
  s = string.lower(s)
  for _,k in ipairs(list) do if string.find(s, k, 1, true) then return true end end
  return false
end

local function nearestNPC(pos, radius)
  local best, bestD, bestModel
  for _,m in ipairs(workspace:GetChildren()) do
    if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") and m.Name:match("^Guest_") then
      local hrp = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChildWhichIsA("BasePart")
      if hrp then
        local d = (hrp.Position - pos).Magnitude
        if d <= radius and (not bestD or d < bestD) then bestD=d; bestModel=m end
      end
    end
  end
  return bestModel
end

Remotes:WaitForChild("NPCChatCommand").OnServerEvent:Connect(function(player, text)
  if type(text) ~= "string" or text == "" then return end
  local char = player.Character
  local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChildWhichIsA("BasePart"))
  if not root then return end

  local npc = nearestNPC(root.Position, 24)
  if not npc then return end
  local hrp = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso") or npc:FindFirstChildWhichIsA("BasePart")
  if not hrp then return end

  local function say(t) bubble(hrp, t) end

  if containsAny(text, greetings) then say("hey! want to farm some prism drops?"); return end
  if containsAny(text, funqs) then
    local funs = {"fun fact: Zone 3 boost hits different 😤","pro tip: catch falling drops for instant energy!","if your cup sparkles, you’re basically famous."}
    say(funs[math.random(1,#funs)]); return
  end
  if containsAny(text, followqs) then
    say("on your six. lead the way!")
    local prompt = npc:FindFirstChild("TalkPrompt", true)
    if prompt and prompt.Triggered then pcall(function() prompt.Triggered:Fire(player) end) end
    return
  end
  if containsAny(text, stopqs) then npc:SetAttribute("Following", nil); say("roger. I’ll roam for candy."); return end
  say(({"sip sip hooray!","zone hopping or chill grind?","I rate your drip 10/10."})[math.random(1,3)])
end)
