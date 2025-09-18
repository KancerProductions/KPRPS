-- StarterPlayer/StarterPlayerScripts/_RemotesUtil.client.lua
-- Helper for client scripts to get remotes the safe way.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Prism = ReplicatedStorage:WaitForChild("Prism")
local Remotes = Prism:WaitForChild("Remotes")
return Remotes
