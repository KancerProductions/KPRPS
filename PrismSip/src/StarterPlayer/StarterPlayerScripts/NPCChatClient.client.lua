-- StarterPlayer/StarterPlayerScripts/NPCChatClient.client.lua (008b)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Prism"):WaitForChild("Remotes")

-- Only forward messages authored by the local player
TextChatService.OnIncomingMessage = function(message: TextChatMessage)
  local src = message.TextSource
  if not src or src.UserId ~= player.UserId then return end
  local text = message.Text or ""
  if text == "" then return end
  Remotes:WaitForChild("NPCChatCommand"):FireServer(text)
end
