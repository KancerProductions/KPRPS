local COLORS = { SGZone1=Color3.fromRGB(255,255,255), SGZone2=Color3.fromRGB(120,200,255), SGZone3=Color3.fromRGB(255,120,255) }
local function label(part, name)
  local box=Instance.new("SelectionBox"); box.Name="ZoneBeacon"; box.Color3=COLORS[name] or Color3.new(1,1,1); box.LineThickness=0.02; box.Adornee=part; box.Parent=workspace
  local bb=Instance.new("BillboardGui"); bb.Name="ZoneLabel"; bb.Size=UDim2.new(0,120,0,24); bb.StudsOffset=Vector3.new(0,2,0); bb.AlwaysOnTop=true; bb.Parent=part
  local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Size=UDim2.new(1,0,1,0); t.TextColor3=box.Color3; t.TextStrokeTransparency=0.5; t.Font=Enum.Font.GothamBold; t.TextScaled=true; t.Text=name; t.Parent=bb
end
for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("BasePart") and (d.Name=="SGZone1" or d.Name=="SGZone2" or d.Name=="SGZone3") then if not d:FindFirstChild("ZoneLabel") then label(d,d.Name) end end end
workspace.DescendantAdded:Connect(function(d) if d:IsA("BasePart") and (d.Name=="SGZone1" or d.Name=="SGZone2" or d.Name=="SGZone3") then label(d,d.Name) end end)
