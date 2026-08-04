local Library = {}
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = game:GetService("Players").LocalPlayer

function Library.new(hubName, toggleKey)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = hubName or "PepsiSwarmGUI"
    ScreenGui.ResetOnSpawn = false

    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    else
        pcall(function()
            ScreenGui.Parent = CoreGui
        end)
        if ScreenGui.Parent ~= CoreGui then
            ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
    end

    local boundKey = toggleKey or Enum.KeyCode.RightShift
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == boundKey then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    local WindowManager = {}

    function WindowManager:AddWindow(titleText, defaultPosition)
        local Window = Instance.new("Frame")
        Window.Name = titleText .. "Window"
        Window.Size = UDim2.new(0, 200, 0, 360)
        Window.Position = defaultPosition or UDim2.new(0, 50, 0, 50)
        Window.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        Window.BorderSizePixel = 1
        Window.BorderColor3 = Color3.fromRGB(55, 55, 65)
        Window.Parent = ScreenGui

        local Header = Instance.new("Frame")
        Header.Name = "Header"
        Header.Size = UDim2.new(1, 0, 0, 28)
        Header.BackgroundColor3 = Color3.fromRGB(48, 48, 58)
        Header.BorderSizePixel = 0
        Header.Parent = Window

        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Size = UDim2.new(1, -32, 1, 0)
        TitleLabel.Position = UDim2.new(0, 8, 0, 0)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Font = Enum.Font.SourceSansBold
        TitleLabel.Text = titleText
        TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
        TitleLabel.TextSize = 14
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.Parent = Header

        local CollapseBtn = Instance.new("TextButton")
        CollapseBtn.Size = UDim2.new(0, 22, 0, 22)
        CollapseBtn.Position = UDim2.new(1, -26, 0.5, -11)
        CollapseBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        CollapseBtn.BorderSizePixel = 1
        CollapseBtn.BorderColor3 = Color3.fromRGB(60, 60, 75)
        CollapseBtn.Font = Enum.Font.SourceSansBold
        CollapseBtn.Text = "-"
        CollapseBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
        CollapseBtn.TextSize = 14
        CollapseBtn.Parent = Header

        local Container = Instance.new("ScrollingFrame")
        Container.Name = "Container"
        Container.Size = UDim2.new(1, -8, 1, -34)
        Container.Position = UDim2.new(0, 4, 0, 30)
        Container.BackgroundTransparency = 1
        Container.BorderSizePixel = 0
        Container.CanvasSize = UDim2.new(0, 0, 0, 0)
        Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Container.ScrollBarThickness = 3
        Container.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
        Container.Parent = Window

        local Layout = Instance.new("UIListLayout")
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Padding = UDim.new(0, 3)
        Layout.Parent = Container

        local collapsed = false
        local fullHeight = UDim2.new(0, 200, 0, 360)
        local collapsedHeight = UDim2.new(0, 200, 0, 28)

        CollapseBtn.MouseButton1Click:Connect(function()
            collapsed = not collapsed
            Container.Visible = not collapsed
            CollapseBtn.Text = collapsed and "+" or "-"
            if collapsed then
                Window.Size = collapsedHeight
            else
                Window.Size = fullHeight
            end
        end)

        local dragging, dragInput, dragStart, startPos
        Header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Window.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        Header.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        local windowAPI = {}

        function windowAPI:AddButton(text, callback)
            callback = callback or function() end
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 28)
            btn.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
            btn.BorderSizePixel = 1
            btn.BorderColor3 = Color3.fromRGB(45, 45, 55)
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.SourceSans
            btn.Text = text
            btn.TextColor3 = Color3.fromRGB(210, 210, 210)
            btn.TextSize = 13
            btn.Parent = Container

            btn.MouseButton1Click:Connect(function()
                task.spawn(callback)
                TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}):Play()
                task.wait(0.12)
                TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(12, 12, 15)}):Play()
            end)
            return btn
        end

        function windowAPI:AddToggle(text, default, callback)
            callback = callback or function() end
            local toggled = default or false

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 28)
            btn.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
            btn.BorderSizePixel = 1
            btn.BorderColor3 = Color3.fromRGB(45, 45, 55)
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.SourceSans
            btn.Text = "  " .. text
            btn.TextColor3 = Color3.fromRGB(210, 210, 210)
            btn.TextSize = 13
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = Container

            local checkbox = Instance.new("Frame")
            checkbox.Size = UDim2.new(0, 16, 0, 16)
            checkbox.Position = UDim2.new(1, -20, 0.5, -8)
            checkbox.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
            checkbox.BorderSizePixel = 1
            checkbox.BorderColor3 = Color3.fromRGB(50, 50, 65)
            checkbox.Parent = btn

            local checkmark = Instance.new("TextLabel")
            checkmark.Size = UDim2.new(1, 0, 1, 0)
            checkmark.BackgroundTransparency = 1
            checkmark.Font = Enum.Font.SourceSansBold
            checkmark.Text = toggled and "✓" or ""
            checkmark.TextColor3 = Color3.fromRGB(0, 255, 120)
            checkmark.TextSize = 14
            checkmark.Parent = checkbox

            btn.MouseButton1Click:Connect(function()
                toggled = not toggled
                checkmark.Text = toggled and "✓" or ""
                pcall(callback, toggled)
            end)
            return btn
        end

        function windowAPI:AddLabel(text)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 22)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.SourceSansBold
            lbl.Text = text
            lbl.TextColor3 = Color3.fromRGB(150, 150, 170)
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Center
            lbl.Parent = Container
            return lbl
        end

        return windowAPI
    end

    return WindowManager
end

return Library
