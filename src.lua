local Library = {}
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = game:GetService("Players").LocalPlayer

function Library.new(hubName)
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

    local WindowManager = {}

    function WindowManager:AddWindow(titleText, defaultPosition, customColor)
        local accent = customColor or Color3.fromRGB(114, 43, 215)

        local Window = Instance.new("Frame")
        Window.Name = titleText .. "Window"
        Window.Size = UDim2.new(0, 185, 0, 320)
        Window.Position = defaultPosition or UDim2.new(0, 50, 0, 50)
        Window.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        Window.BorderSizePixel = 0
        Window.Parent = ScreenGui

        local WinStroke = Instance.new("UIStroke")
        WinStroke.Color = Color3.fromRGB(35, 35, 42)
        WinStroke.Thickness = 1
        WinStroke.Parent = Window

        local Header = Instance.new("TextButton")
        Header.Name = "Header"
        Header.Size = UDim2.new(1, 0, 0, 26)
        Header.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
        Header.BorderSizePixel = 0
        Header.AutoButtonColor = false
        Header.Font = Enum.Font.SourceSansBold
        Header.Text = "  " .. titleText .. "  -"
        Header.TextColor3 = Color3.fromRGB(220, 220, 220)
        Header.TextSize = 13
        Header.TextXAlignment = Enum.TextXAlignment.Left
        Header.Parent = Window

        local HeaderAccent = Instance.new("Frame")
        HeaderAccent.Size = UDim2.new(1, 0, 0, 2)
        HeaderAccent.Position = UDim2.new(0, 0, 1, -2)
        HeaderAccent.BackgroundColor3 = accent
        HeaderAccent.BorderSizePixel = 0
        HeaderAccent.Parent = Header

        local Container = Instance.new("ScrollingFrame")
        Container.Name = "Container"
        Container.Size = UDim2.new(1, -4, 1, -30)
        Container.Position = UDim2.new(0, 2, 0, 28)
        Container.BackgroundTransparency = 1
        Container.BorderSizePixel = 0
        Container.CanvasSize = UDim2.new(0, 0, 0, 0)
        Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Container.ScrollBarThickness = 2
        Container.ScrollBarImageColor3 = accent
        Container.Parent = Window

        local Layout = Instance.new("UIListLayout")
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Padding = UDim.new(0, 3)
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
            btn.Size = UDim2.new(1, 0, 0, 24)
            btn.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.SourceSans
            btn.Text = text
            btn.TextColor3 = Color3.fromRGB(180, 180, 180)
            btn.TextSize = 12
            btn.Parent = Container

            local btnStroke = Instance.new("UIStroke")
            btnStroke.Color = Color3.fromRGB(35, 35, 42)
            btnStroke.Thickness = 1
            btnStroke.Parent = btn

            btn.MouseButton1Click:Connect(function()
                task.spawn(callback)
                TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
                task.wait(0.15)
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22, 22, 26)}):Play()
            end)
            return btn
        end

        function windowAPI:AddToggle(text, default, callback)
            callback = callback or function() end
            local toggled = default or false

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 24)
            btn.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.SourceSans
            btn.Text = "  " .. text
            btn.TextColor3 = Color3.fromRGB(180, 180, 180)
            btn.TextSize = 12
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = Container

            local btnStroke = Instance.new("UIStroke")
            btnStroke.Color = Color3.fromRGB(35, 35, 42)
            btnStroke.Thickness = 1
            btnStroke.Parent = btn

            local indicator = Instance.new("TextLabel")
            indicator.Size = UDim2.new(0, 20, 0, 16)
            indicator.Position = UDim2.new(1, -22, 0.5, -8)
            indicator.BackgroundTransparency = 1
            indicator.Font = Enum.Font.SourceSansBold
            indicator.Text = toggled and "✓" or ""
            indicator.TextColor3 = Color3.fromRGB(0, 255, 128)
            indicator.TextSize = 14
            indicator.Parent = btn

            btn.MouseButton1Click:Connect(function()
                toggled = not toggled
                indicator.Text = toggled and "✓" or ""
                pcall(callback, toggled)
            end)
            return btn
        end

        function windowAPI:AddLabel(text)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 20)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.SourceSansBold
            lbl.Text = " " .. text
            lbl.TextColor3 = Color3.fromRGB(130, 130, 145)
            lbl.TextSize = 12
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = Container
            return lbl
        end

        return windowAPI
    end

    return WindowManager
end

return Library
