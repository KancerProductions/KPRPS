-- StarterPlayer/StarterPlayerScripts/ColorHud
local HUD_NAME, PULSE_TIME = "ColorHud", 0.25
local CORNER_RADIUS = UDim.new(0, 8)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local ColorChanged = ReplicatedStorage:FindFirstChild("ColorSip")
	and ReplicatedStorage.ColorSip:FindFirstChild("ColorChanged")
local BoundaryPulse = ReplicatedStorage:FindFirstChild("Boundary")
	and ReplicatedStorage.Boundary:FindFirstChild("Pulse")

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset = HUD_NAME, false, true
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name, frame.AnchorPoint = "Chip", Vector2.new(0,0)
frame.Position, frame.Size = UDim2.new(0,12,0,12), UDim2.new(0,160,0,36)
frame.BackgroundColor3, frame.BackgroundTransparency, frame.BorderSizePixel = Color3.fromRGB(40,40,40), 0.2, 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = CORNER_RADIUS
corner.Parent = frame

local label = Instance.new("TextLabel")
label.Size, label.Position = UDim2.new(1,-12,1,0), UDim2.new(0,12,0,0)
label.BackgroundTransparency, label.TextXAlignment = 1, Enum.TextXAlignment.Left
label.Text, label.TextColor3, label.TextSize, label.Font =
	"Color: —", Color3.fromRGB(240,240,240), 18, Enum.Font.GothamSemibold
label.Parent = frame

local function setColor(c3)
	label.Text = ("Color: %d, %d, %d"):format(
		math.floor(c3.R*255), math.floor(c3.G*255), math.floor(c3.B*255)
	)
	label.TextColor3 = c3
end

local function pulse(color)
	local c1 = TweenService:Create(frame, TweenInfo.new(PULSE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundColor3 = color or Color3.fromRGB(200,60,60)
	})
	local c2 = TweenService:Create(frame, TweenInfo.new(PULSE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundColor3 = Color3.fromRGB(40,40,40)
	})
	c1:Play(); c1.Completed:Wait(); c2:Play()
end

if ColorChanged and ColorChanged:IsA("RemoteEvent") then
	ColorChanged.OnClientEvent:Connect(function(r,g,b) setColor(Color3.fromRGB(r,g,b)) end)
end
if BoundaryPulse and BoundaryPulse:IsA("RemoteEvent") then
	BoundaryPulse.OnClientEvent:Connect(function(r,g,b) pulse(Color3.fromRGB(r or 200, g or 60, b or 60)) end)
end

setColor(Color3.fromRGB(255,255,255))
