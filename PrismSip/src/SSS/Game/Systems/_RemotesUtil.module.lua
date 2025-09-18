-- ServerScriptService/Game/Systems/_RemotesUtil.module.lua
-- Helper for server scripts to get remotes the safe way.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Prism = ReplicatedStorage:WaitForChild("Prism")
local Remotes = Prism:WaitForChild("Remotes")
return Remotes
