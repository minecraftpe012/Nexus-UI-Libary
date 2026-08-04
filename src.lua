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
        Window.Size = UDim2.new(0, 220, 0, 380)
        Window.Position = defaultPosition or UDim2.new(0, 50, 0, 50)
        Window.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Window.BorderSizePixel = 1
        Window.BorderColor3 = Color3.fromRGB(35, 35, 35)
        Window.Parent = ScreenGui

        local WindowCorner = Instance.new("UICorner")
        WindowCorner.CornerRadius = UDim.new(0, 6)
        WindowCorner.Parent = Window

        local Header = Instance.new("Frame")
        Header.Name = "Header"
        Header.Size = UDim2.new(1, 0, 0, 30)
        Header.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Header.BorderSizePixel = 0
        Header.Parent = Window

        local HeaderCorner = Instance.new("UICorner")
        HeaderCorner.CornerRadius = UDim.new(0, 6)
        HeaderCorner.Parent = Header

        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Size = UDim2.new(1, -36, 1, 0)
        TitleLabel.Position = UDim2.new(0, 10, 0, 0)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Font = Enum.Font.SourceSansBold
        TitleLabel.Text = titleText
        TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleLabel.TextSize = 15
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.Parent = Header

        local CollapseBtn = Instance.new("TextButton")
        CollapseBtn.Size = UDim2.new(0, 22, 0, 22)
        CollapseBtn.AnchorPoint = Vector2.new(1, 0.5)
        CollapseBtn.Position = UDim2.new(1, -6, 0.5, 0)
        CollapseBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        CollapseBtn.BorderSizePixel = 1
        CollapseBtn.BorderColor3 = Color3.fromRGB(45, 45, 45)
        CollapseBtn.Font = Enum.Font.SourceSansBold
        CollapseBtn.Text = "-"
        CollapseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        CollapseBtn.TextSize = 14
        CollapseBtn.Parent = Header

        local CollapseCorner = Instance.new("UICorner")
        CollapseCorner.CornerRadius = UDim.new(0, 4)
        CollapseCorner.Parent = CollapseBtn

        local Container = Instance.new("ScrollingFrame")
        Container.Name = "Container"
        Container.Size = UDim2.new(1, -10, 1, -36)
        Container.Position = UDim2.new(0, 5, 0, 32)
        Container.BackgroundTransparency = 1
        Container.BorderSizePixel = 0
        Container.CanvasSize = UDim2.new(0, 0, 0, 0)
        Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Container.ScrollBarThickness = 3
        Container.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
        Container.Parent = Window

        local Layout = Instance.new("UIListLayout")
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Padding = UDim.new(0, 4)
        Layout.Parent = Container

        local collapsed = false
        local fullHeight = UDim2.new(0, 220, 0, 380)
        local collapsedHeight = UDim2.new(0, 220, 0, 30)

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
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            btn.BorderSizePixel = 1
            btn.BorderColor3 = Color3.fromRGB(35, 35, 35)
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.SourceSans
            btn.Text = text
            btn.TextColor3 = Color3.fromRGB(220, 220, 220)
            btn.TextSize = 13
            btn.Parent = Container

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = btn

            btn.MouseButton1Click:Connect(function()
                task.spawn(callback)
                TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(25, 25, 25)}):Play()
                task.wait(0.12)
                TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
            end)
            return btn
        end

        function windowAPI:AddToggle(text, default, callback)
            callback = callback or function() end
            local toggled = default or false

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            btn.BorderSizePixel = 1
            btn.BorderColor3 = Color3.fromRGB(35, 35, 35)
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.SourceSans
            btn.Text = "  " .. text
            btn.TextColor3 = Color3.fromRGB(220, 220, 220)
            btn.TextSize = 13
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = Container

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = btn

            local checkbox = Instance.new("Frame")
            checkbox.Size = UDim2.new(0, 16, 0, 16)
            checkbox.Position = UDim2.new(1, -22, 0.5, -8)
            checkbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            checkbox.BorderSizePixel = 1
            checkbox.BorderColor3 = Color3.fromRGB(45, 45, 45)
            checkbox.Parent = btn

            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(0, 3)
            boxCorner.Parent = checkbox

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
            lbl.Size = UDim2.new(1, 0, 0, 24)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.SourceSansBold
            lbl.Text = text
            lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
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
