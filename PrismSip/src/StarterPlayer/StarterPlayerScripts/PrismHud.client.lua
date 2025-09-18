-- StarterPlayer/StarterPlayerScripts/PrismHud.client.lua (FIXED REMOTES)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Prism = ReplicatedStorage:WaitForChild("Prism")
local Remotes = Prism:WaitForChild("Remotes")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui"); gui.Name="PrismHud"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.Parent=player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame"); panel.Name="Panel"; panel.AnchorPoint = Vector2.new(1,0)
panel.Position = UDim2.new(1,-12,0,12); panel.Size = UDim2.new(0,220,0,90)
panel.BackgroundColor3 = Color3.fromRGB(35,35,45); panel.BackgroundTransparency=0.2; panel.BorderSizePixel=0; panel.Parent=gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,10)

local energyLabel = Instance.new("TextLabel"); energyLabel.BackgroundTransparency=1; energyLabel.TextXAlignment=Enum.TextXAlignment.Left
energyLabel.Font=Enum.Font.GothamBold; energyLabel.TextSize=22; energyLabel.TextColor3=Color3.fromRGB(255,255,255)
energyLabel.Text="Energy: 0"; energyLabel.Size=UDim2.new(1,-20,0,26); energyLabel.Position=UDim2.new(0,10,0,8); energyLabel.Parent=panel

local boostLabel = Instance.new("TextLabel"); boostLabel.BackgroundTransparency=1; boostLabel.TextXAlignment=Enum.TextXAlignment.Left
boostLabel.Font=Enum.Font.Gotham; boostLabel.TextSize=14; boostLabel.TextColor3=Color3.fromRGB(200,230,255)
boostLabel.Text="Boost: x1.0"; boostLabel.Size=UDim2.new(1,-20,0,20); boostLabel.Position=UDim2.new(0,10,0,36); boostLabel.Parent=panel

local button = Instance.new("TextButton"); button.Text="SIP"; button.Font=Enum.Font.GothamBlack; button.TextSize=22; button.TextColor3=Color3.fromRGB(15,15,20)
button.Size=UDim2.new(0,80,0,36); button.Position=UDim2.new(1,-90,1,-44); button.BackgroundColor3=Color3.fromRGB(255,210,80); button.Parent=panel
Instance.new("UICorner", button).CornerRadius = UDim.new(0,10)

button.MouseButton1Click:Connect(function() Remotes:WaitForChild("Sip"):FireServer() end)
UserInputService.InputBegan:Connect(function(input,gp) if not gp and input.KeyCode==Enum.KeyCode.Space then Remotes:WaitForChild("Sip"):FireServer() end end)

Remotes:WaitForChild("EnergyChanged").OnClientEvent:Connect(function(total,gain,boost)
	energyLabel.Text = ("Energy: %d  (+%d)"):format(total, gain)
	boostLabel.Text = ("Boost: x%.2f"):format(boost or 1.0)
	local t1 = TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(255,230,120)})
	local t2 = TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundColor3 = Color3.fromRGB(35,35,45)})
	t1:Play(); t1.Completed:Wait(); t2:Play()
end)
