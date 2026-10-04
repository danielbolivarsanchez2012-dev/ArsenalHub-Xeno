local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ScriptEnabled = true

local Settings = {
    Aimbot = {
        Enabled = true,
        Key = Enum.UserInputType.MouseButton2,
        FOV = 180,
        WallCheck = true,
        TeamCheck = true
    },
    ESP = {
        Enabled = true,
        VisibleColor = Color3.fromRGB(0, 255, 0),   -- Verde si está visible
        HiddenColor = Color3.fromRGB(255, 50, 50),   -- Rojo si está tras pared
        TeamColor = Color3.fromRGB(0, 150, 255),     -- Azul si es aliado
        Box = true,
        Lines = true,
        Info = true
    },
    WeaponMods = {
        NoRecoil = true,
        FastFire = true
    },
    ToggleKey = Enum.KeyCode.Delete
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = true
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled = false
FOVCircle.Radius = Settings.Aimbot.FOV
FOVCircle.Transparency = 0.7

local CounterText = Drawing.new("Text")
CounterText.Visible = true
CounterText.Size = 20
CounterText.Center = true
CounterText.Outline = true
CounterText.Color = Color3.fromRGB(255, 255, 255)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ArsenalHub"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 220, 0, 220)
MainFrame.Active = true
MainFrame.Draggable = true

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 30)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = TopBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0.05, 0, 0, 0)
TitleLabel.Size = UDim2.new(0.6, 0, 1, 0)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Text = "ARSENAL HUB"
TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local CloseButton = Instance.new("TextButton")
CloseButton.Parent = TopBar
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(0.82, 0, 0.15, 0)
CloseButton.Size = UDim2.new(0, 24, 0, 21)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    FOVCircle:Remove()
    CounterText:Remove()
end)

local CustomESP = {}

local function clearAllESP()
    for _, drawings in pairs(CustomESP) do
        if drawings.Box then drawings.Box.Visible = false end
        if drawings.Line then drawings.Line.Visible = false end
        if drawings.Info then drawings.Info.Visible = false end
    end
end

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Settings.ToggleKey then
        ScriptEnabled = not ScriptEnabled
        FOVCircle.Visible = ScriptEnabled
        CounterText.Visible = ScriptEnabled
        MainFrame.Visible = ScriptEnabled
        
        if not ScriptEnabled then
            clearAllESP()
        end
    end
end)

local function isVisible(targetPart)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("Head") then return false end
    
    local origin = character.Head.Position
    local direction = targetPart.Position - origin
    local distance = direction.Magnitude

    local raycastParams = RaycastParams.new()
    local filterList = {character}
    if targetPart.Parent and targetPart.Parent:IsA("Model") then
        table.insert(filterList, targetPart.Parent)
    end
    
    raycastParams.FilterDescendantsInstances = filterList
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction.Unit * distance, raycastParams)
    return result == nil
end

local function isTeammate(player)
    if not Settings.Aimbot.TeamCheck then return false end
    -- Arsenal usa Teams de Roblox por defecto, validamos equipo y color si aplica
    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return true
    end
    return false
end

local function getClosestPlayerInFOV()
    local closestTarget = nil
    local shortestDistance = Settings.Aimbot.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not isTeammate(player) then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local targetPart = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
                
                if humanoid and targetPart and humanoid.Health > 0 then
                    if not Settings.Aimbot.WallCheck or isVisible(targetPart) then
                        local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen and screenPoint.Z > 0 then
                            local magnitude = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
                            if magnitude < shortestDistance then
                                shortestDistance = magnitude
                                closestTarget = targetPart
                            end
                        end
                    end
                end
            end
        end
    end

    return closestTarget
end

-- Modificador adaptado para el sistema de armas de Arsenal (Revolvers, rifles, etc.)
local function applyArsenalMods()
    local character = LocalPlayer.Character
    if not character then return end
    
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            for _, descendant in ipairs(tool:GetDescendants()) do
                if descendant:IsA("NumberValue") or descendant:IsA("IntValue") then
                    local name = descendant.Name:lower()
                    if Settings.WeaponMods.NoRecoil and (name:find("recoil") or name:find("spread") or name:find("kick") or name:find("cam")) then
                        descendant.Value = 0
                    end
                    if Settings.WeaponMods.FastFire and (name:find("cooldown") or name:find("firerate") or name:find("fire") or name:find("delay")) then
                        descendant.Value = descendant.Value / 2.5
                    end
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    if not ScriptEnabled then 
        FOVCircle.Visible = false
        CounterText.Visible = false
        clearAllESP()
        return 
    end

    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = mousePos
    FOVCircle.Radius = Settings.Aimbot.FOV
    FOVCircle.Visible = true

    CounterText.Text = "JUGADORES: " .. (#Players:GetPlayers() - 1)
    CounterText.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y * 0.85)
    CounterText.Visible = true

    if Settings.Aimbot.Enabled and UserInputService:IsMouseButtonPressed(Settings.Aimbot.Key) then
        local targetPart = getClosestPlayerInFOV()
        if targetPart then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
        end
    end

    if Settings.WeaponMods.NoRecoil or Settings.WeaponMods.FastFire then
        pcall(applyArsenalMods)
    end

    for player, drawings in pairs(CustomESP) do
        if not player.Parent or not player.Character or not player.Character:FindFirstChildOfClass("Humanoid") or player.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            if drawings.Box then drawings.Box:Remove() end
            if drawings.Line then drawings.Line:Remove() end
            if drawings.Info then drawings.Info:Remove() end
            CustomESP[player] = nil
        end
    end

    local localHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character then
                local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
                local head = character:FindFirstChild("Head")
                local humanoid = character:FindFirstChildOfClass("Humanoid")

                if rootPart and head and humanoid and humanoid.Health > 0 then
                    if not CustomESP[player] then
                        local box = Drawing.new("Square")
                        box.Visible = false
                        box.Thickness = 1
                        box.Filled = false

                        local line = Drawing.new("Line")
                        line.Visible = false
                        line.Thickness = 1

                        local info = Drawing.new("Text")
                        info.Visible = false
                        info.Size = 14
                        info.Center = true
                        info.Outline = true

                        CustomESP[player] = { Box = box, Line = line, Info = info }
                    end

                    local drawings = CustomESP[player]
                    local rootPos, rootOnScreen = Camera:WorldToViewportPoint(rootPart.Position)

                    if rootOnScreen and rootPos.Z > 0 and Settings.ESP.Enabled then
                        local teammate = isTeammate(player)
                        local visible = isVisible(head)
                        
                        local currentColor
                        local labelText = ""

                        if teammate then
                            currentColor = Settings.ESP.TeamColor
                            labelText = player.Name .. " [ALIADO]"
                        else
                            currentColor = visible and Settings.ESP.VisibleColor or Settings.ESP.HiddenColor
                            labelText = player.Name .. " | " .. math.floor(humanoid.Health) .. " HP"
                        end

                        local topPos = Camera:WorldToViewportPoint((rootPart.CFrame * CFrame.new(0, 3, 0)).Position)
                        local bottomPos = Camera:WorldToViewportPoint((rootPart.CFrame * CFrame.new(0, -3, 0)).Position)
                        local height = math.abs(topPos.Y - bottomPos.Y)
                        local width = height / 2

                        local distance = localHead and math.floor((localHead.Position - rootPart.Position).Magnitude) or 0

                        if Settings.ESP.Box then
                            drawings.Box.Size = Vector2.new(width, height)
                            drawings.Box.Position = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)
                            drawings.Box.Color = currentColor
                            drawings.Box.Visible = true
                        else
                            drawings.Box.Visible = false
                        end

                        if Settings.ESP.Lines then
                            drawings.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            drawings.Line.To = Vector2.new(rootPos.X, rootPos.Y)
                            drawings.Line.Color = currentColor
                            drawings.Line.Visible = true
                        else
                            drawings.Line.Visible = false
                        end

                        if Settings.ESP.Info then
                            drawings.Info.Text = labelText .. " | " .. distance .. "m"
                            drawings.Info.Position = Vector2.new(rootPos.X, (rootPos.Y - height / 2) - 18)
                            drawings.Info.Color = currentColor
                            drawings.Info.Visible = true
                        else
                            drawings.Info.Visible = false
                        end
                    else
                        drawings.Box.Visible = false
                        drawings.Line.Visible = false
                        drawings.Info.Visible = false
                    end
                end
            end
        end
    end
end)
