local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Library = {}

local Theme = {
    Background = Color3.fromRGB(18, 18, 18),
    Header = Color3.fromRGB(25, 25, 25),
    Sidebar = Color3.fromRGB(22, 22, 22),
    ElementBackground = Color3.fromRGB(28, 28, 32),
    Accent = Color3.fromRGB(40, 200, 40),
    ToggleOff = Color3.fromRGB(220, 35, 35),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 180),
    Border = Color3.fromRGB(40, 40, 40)
}

function Library:CreateWindow(windowTitle)
    for _, parent in ipairs({CoreGui, LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")}) do
        if parent then
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("ScreenGui") and child.Name == "PrismHubTabbed" then
                    child:Destroy()
                end
            end
        end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "PrismHubTabbed"
    ScreenGui.ResetOnSpawn = false
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
        ScreenGui.Parent = CoreGui
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local MainWindow = Instance.new("Frame")
    MainWindow.Size = UDim2.new(0, 480, 0, 320)
    MainWindow.Position = UDim2.new(0.5, -240, 0.5, -160)
    MainWindow.BackgroundColor3 = Theme.Background
    MainWindow.BorderSizePixel = 0
    MainWindow.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 6)
    MainCorner.Parent = MainWindow

    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 32)
    Header.BackgroundColor3 = Theme.Header
    Header.BorderSizePixel = 0
    Header.Parent = MainWindow

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 6)
    HeaderCorner.Parent = Header

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -60, 1, 0)
    TitleLabel.Position = UDim2.new(0, 12, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.Text = windowTitle
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Header

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 24, 0, 24)
    CloseBtn.Position = UDim2.new(1, -28, 0.5, -12)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Font = Enum.Font.SourceSansBold
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Theme.TextDim
    CloseBtn.TextSize = 14
    CloseBtn.Parent = Header

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    local Sidebar = Instance.new("ScrollingFrame")
    Sidebar.Size = UDim2.new(0, 120, 1, -32)
    Sidebar.Position = UDim2.new(0, 0, 0, 32)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    Sidebar.ScrollBarThickness = 0
    Sidebar.Parent = MainWindow

    local SidebarLayout = Instance.new("UIListLayout")
    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarLayout.Padding = UDim.new(0, 4)
    SidebarLayout.Parent = Sidebar

    local SidebarPadding = Instance.new("UIPadding")
    SidebarPadding.PaddingTop = UDim.new(0, 6)
    SidebarPadding.PaddingLeft = UDim.new(0, 6)
    SidebarPadding.PaddingRight = UDim.new(0, 6)
    SidebarPadding.Parent = Sidebar

    local ContentArea = Instance.new("Frame")
    ContentArea.Size = UDim2.new(1, -120, 1, -32)
    ContentArea.Position = UDim2.new(0, 120, 0, 32)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = MainWindow

    local dragging, dragInput, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainWindow.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
            MainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local tabs = {}
    local activeTabName = nil
    local windowAPI = {}

    function windowAPI:AddTab(name)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 30)
        tabBtn.BackgroundColor3 = Theme.ElementBackground
        tabBtn.BorderSizePixel = 0
        tabBtn.Font = Enum.Font.SourceSansBold
        tabBtn.Text = name
        tabBtn.TextColor3 = Theme.TextDim
        tabBtn.TextSize = 13
        tabBtn.Parent = Sidebar

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = tabBtn

        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Size = UDim2.new(1, -12, 1, -12)
        tabContent.Position = UDim2.new(0, 6, 0, 6)
        tabContent.BackgroundTransparency = 1
        tabContent.BorderSizePixel = 0
        tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabContent.ScrollBarThickness = 3
        tabContent.Visible = false
        tabContent.Parent = ContentArea

        local contentLayout = Instance.new("UIListLayout")
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim.new(0, 6)
        contentLayout.Parent = tabContent

        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabContent.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 10)
        end)

        tabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(tabs) do
                t.content.Visible = false
                t.button.TextColor3 = Theme.TextDim
                t.button.BackgroundColor3 = Theme.ElementBackground
            end
            tabContent.Visible = true
            tabBtn.TextColor3 = Theme.Text
            tabBtn.BackgroundColor3 = Theme.Header
        end)

        if not activeTabName then
            tabContent.Visible = true
            tabBtn.TextColor3 = Theme.Text
            tabBtn.BackgroundColor3 = Theme.Header
            activeTabName = name
        end

        tabs[name] = {button = tabBtn, content = tabContent}

        local tabAPI = {}

        function tabAPI:AddToggle(text, default, callback)
            callback = callback or function() end
            local toggled = default or false

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 28)
            btn.BackgroundColor3 = Theme.ElementBackground
            btn.BorderSizePixel = 0
            btn.Font = Enum.Font.SourceSans
            btn.Text = "    " .. text
            btn.TextColor3 = Theme.Text
            btn.TextSize = 13
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = tabContent

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = btn

            local box = Instance.new("Frame")
            box.Size = UDim2.new(0, 14, 0, 14)
            box.Position = UDim2.new(1, -18, 0.5, -7)
            box.BorderSizePixel = 0
            box.Parent = btn

            local function updateColor()
                box.BackgroundColor3 = toggled and Theme.Accent or Theme.ToggleOff
            end
            updateColor()

            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(0, 3)
            boxCorner.Parent = box

            btn.MouseButton1Click:Connect(function()
                toggled = not toggled
                updateColor()
                pcall(callback, toggled)
            end)
            return btn
        end

        function tabAPI:AddButton(text, callback)
            callback = callback or function() end
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 28)
            btn.BackgroundColor3 = Theme.ElementBackground
            btn.BorderSizePixel = 0
            btn.Font = Enum.Font.SourceSans
            btn.Text = text
            btn.TextColor3 = Theme.Text
            btn.TextSize = 13
            btn.Parent = tabContent

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = btn

            btn.MouseButton1Click:Connect(function()
                task.spawn(callback)
            end)
            return btn
        end

        function tabAPI:AddLabel(text)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 20)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.SourceSansBold
            lbl.Text = text
            lbl.TextColor3 = Theme.TextDim
            lbl.TextSize = 12
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = tabContent
            return lbl
        end

        return tabAPI
    end

    return windowAPI
end

getgenv().PrismLibrary = Library
