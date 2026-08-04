local Library = {}
Library.__index = Library

local Column = {}
Column.__index = Column

-- Services
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Styling Constants
local THEME = {
    Background = Color3.fromRGB(22, 22, 24),
    Header = Color3.fromRGB(16, 16, 18),
    Outline = Color3.fromRGB(40, 40, 45),
    Text = Color3.fromRGB(235, 235, 235),
    SubText = Color3.fromRGB(160, 160, 165),
    ToggleOn = Color3.fromRGB(46, 204, 113),
    ToggleOff = Color3.fromRGB(231, 76, 60),
    Button = Color3.fromRGB(30, 30, 34),
    ButtonHover = Color3.fromRGB(40, 40, 46)
}

function Library.new(hubName)
    local self = setmetatable({}, Library)

    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = hubName or "MultiColumnUI"
    screenGui.ResetOnSpawn = false
    
    -- CoreGui protection fallback
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = CoreGui
    elseif gethui then
        screenGui.Parent = gethui()
    else
        screenGui.Parent = CoreGui
    end

    -- Horizontal Column Container
    local container = Instance.new("Frame")
    container.Name = "ColumnContainer"
    container.Size = UDim2.new(1, -40, 1, -40)
    container.Position = UDim2.new(0, 20, 0, 20)
    container.BackgroundTransparency = 1
    container.Parent = screenGui

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = container

    self.ScreenGui = screenGui
    self.Container = container
    return self
end

function Library:CreateColumn(title)
    local col = setmetatable({}, Column)

    -- Main Column Frame
    local frame = Instance.new("Frame")
    frame.Name = title .. "_Column"
    frame.Size = UDim2.new(0, 170, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundColor3 = THEME.Background
    frame.BorderSizePixel = 1
    frame.BorderColor3 = THEME.Outline
    frame.Parent = self.Container

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 4)
    frameCorner.Parent = frame

    -- Title Bar
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 28)
    header.BackgroundColor3 = THEME.Header
    header.BorderSizePixel = 0
    header.Parent = frame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 4)
    headerCorner.Parent = header

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 1, 0)
    titleLabel.Position = UDim2.new(0, 5, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = THEME.Text
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.Parent = header

    -- Content Scroll Area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 0, 0)
    content.Position = UDim2.new(0, 0, 0, 32)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.BackgroundTransparency = 1
    content.Parent = frame

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent = content

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 6)
    listLayout.Parent = content

    col.Frame = frame
    col.Content = content
    return col
end

function Column:AddSection(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = THEME.SubText
    label.TextSize = 12
    label.Font = Enum.Font.SourceSansSemibold
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = self.Content
end

function Column:AddToggle(text, default, callback)
    local state = default or false
    callback = callback or function() end

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 22)
    row.BackgroundTransparency = 1
    row.Parent = self.Content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -24, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = THEME.Text
    label.TextSize = 13
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 16, 0, 16)
    btn.Position = UDim2.new(1, -16, 0.5, -8)
    btn.BackgroundColor3 = state and THEME.ToggleOn or THEME.ToggleOff
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = row

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 3)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = state and THEME.ToggleOn or THEME.ToggleOff
        }):Play()
        callback(state)
    end)
end

function Column:AddButton(text, callback)
    callback = callback or function() end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 22)
    btn.BackgroundColor3 = THEME.Button
    btn.BorderSizePixel = 1
    btn.BorderColor3 = THEME.Outline
    btn.Text = text
    btn.TextColor3 = THEME.Text
    btn.TextSize = 13
    btn.Font = Enum.Font.SourceSans
    btn.Parent = self.Content

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 3)
    btnCorner.Parent = btn

    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = THEME.ButtonHover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = THEME.Button end)
    btn.MouseButton1Click:Connect(function() callback() end)
end

function Column:AddSlider(text, min, max, default, callback)
    local val = math.clamp(default or min, min, max)
    callback = callback or function() end

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundTransparency = 1
    container.Parent = self.Content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 16)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(val)
    label.TextColor3 = THEME.Text
    label.TextSize = 12
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 10)
    track.Position = UDim2.new(0, 0, 0, 18)
    track.BackgroundColor3 = THEME.Button
    track.BorderSizePixel = 0
    track.Parent = container

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = THEME.ToggleOn
    fill.BorderSizePixel = 0
    fill.Parent = track

    local dragging = false
    local function update(input)
        local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        val = math.floor(min + (max - min) * pos)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        label.Text = text .. ": " .. tostring(val)
        callback(val)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)
end

function Column:AddTextBox(text, placeholder, callback)
    callback = callback or function() end

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 22)
    row.BackgroundTransparency = 1
    row.Parent = self.Content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = THEME.Text
    label.TextSize = 13
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.5, 0, 1, 0)
    box.Position = UDim2.new(0.5, 0, 0, 0)
    box.BackgroundColor3 = THEME.Button
    box.BorderSizePixel = 1
    box.BorderColor3 = THEME.Outline
    box.Text = ""
    box.PlaceholderText = placeholder or ""
    box.TextColor3 = THEME.Text
    box.TextSize = 12
    box.Font = Enum.Font.SourceSans
    box.Parent = row

    box.FocusLost:Connect(function(enterPressed)
        callback(box.Text)
    end)
end

function Library:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

return Library
