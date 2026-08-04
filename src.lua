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
        Window.Size = UDim2.new(0, 180, 0, 340)
        Window.Position = defaultPosition or UDim2.new(0, 50, 0, 50)
        Window.BackgroundColor3 = Color3.fromRGB(10, 10, 13)
        Window.BorderSizePixel = 1
        Window.BorderColor3 = Color3.fromRGB(24, 24, 30)
        Window.Parent = ScreenGui

        local Header = Instance.new("TextButton")
        Header.Name = "Header"
        Header.Size = UDim2.new(1, 0, 0, 24)
        Header.BackgroundColor3 = Color3.fromRGB(15, 15, 19)
        Header.BorderSizePixel = 0
        Header.AutoButtonColor = false
        Header.Font = Enum.Font.SourceSansBold
        Header.Text = "  " .. titleText .. "  -"
        Header.TextColor3 = Color3.fromRGB(235, 235, 235)
        Header.TextSize = 13
        Header.TextXAlignment = Enum.TextXAlignment.Left
        Header.Parent = Window

        local Container = Instance.new("ScrollingFrame")
        Container.Name = "Container"
        Container.Size = UDim2.new(1, -6, 1, -28)
        Container.Position = UDim2.new(0, 3, 0, 26)
        Container.BackgroundTransparency = 1
        Container.BorderSizePixel = 0
        Container.CanvasSize = UDim2.new(0, 0, 0, 0)
        Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Container.ScrollBarThickness = 2
        Container.ScrollBarImageColor3 = Color3.fromRGB(55, 55, 70)
        Container.Parent = Window

        local Layout = Instance.new("UIListLayout")
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Padding = UDim.new(0, 2)
        Layout.Parent = Container

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
            btn.Size = UDim2.new(1, 0, 0, 22)
            btn.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
            btn.BorderSizePixel = 1
            btn.BorderColor3 = Color3.fromRGB(24, 24, 30)
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.SourceSans
            btn.Text = text
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.TextSize = 12
            btn.Parent = Container

            btn.MouseButton1Click:Connect(function()
                task.spawn(callback)
                TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}):Play()
                task.wait(0.12)
                TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(13, 13, 17)}):Play()
            end)
            return btn
        end

        function windowAPI:AddToggle(text, default, callback)
            callback = callback or function() end
            local toggled = default or false

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 22)
            btn.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
            btn.BorderSizePixel = 1
            btn.BorderColor3 = Color3.fromRGB(24, 24, 30)
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.SourceSans
            btn.Text = "  " .. text
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.TextSize = 12
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = Container

            local checkbox = Instance.new("Frame")
            checkbox.Size = UDim2.new(0, 14, 0, 14)
            checkbox.Position = UDim2.new(1, -18, 0.5, -7)
            checkbox.BackgroundColor3 = Color3.fromRGB(8, 8, 11)
            checkbox.BorderSizePixel = 1
            checkbox.BorderColor3 = Color3.fromRGB(35, 35, 45)
            checkbox.Parent = btn

            local checkmark = Instance.new("TextLabel")
            checkmark.Size = UDim2.new(1, 0, 1, 0)
            checkmark.BackgroundTransparency = 1
            checkmark.Font = Enum.Font.SourceSansBold
            checkmark.Text = toggled and "✓" or ""
            checkmark.TextColor3 = Color3.fromRGB(0, 255, 120)
            checkmark.TextSize = 13
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
            lbl.Size = UDim2.new(1, 0, 0, 20)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.SourceSansBold
            lbl.Text = text
            lbl.TextColor3 = Color3.fromRGB(130, 130, 150)
            lbl.TextSize = 12
            lbl.TextXAlignment = Enum.TextXAlignment.Center
            lbl.Parent = Container
            return lbl
        end

        return windowAPI
    end

    return WindowManager
end

return Library
