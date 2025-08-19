-- Full GUI with Player tab Speed control + Noclip (fixed per request)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- prevent duplicates on re-execution
if LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("TPUI") then
    LocalPlayer.PlayerGui.TPUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TPUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- sizes / layout
local PAGE_W, PAGE_H = 400, 250
local TAB_W = 60
local TAB_H = 220
local EDGE_GAP = 10
local PAGE_BTN_MARGIN = 20
local PAGE_BTN_HEIGHT = 40
local PAGE_BTN_GAPY = 10

-- Page frame (draggable, spawn a bit higher)
local PageMain = Instance.new("Frame")
PageMain.Name = "PageMain"
PageMain.Size = UDim2.new(0, PAGE_W, 0, PAGE_H)
PageMain.Position = UDim2.new(0.3, 0, 0.22, 0) -- slightly higher
PageMain.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
PageMain.Active = true
PageMain.Draggable = true
PageMain.BorderSizePixel = 0
PageMain.Parent = ScreenGui

local PageCorner = Instance.new("UICorner")
PageCorner.CornerRadius = UDim.new(0, 10)
PageCorner.Parent = PageMain

-- RGB outline for PageMain
local PageOutline = Instance.new("UIStroke")
PageOutline.Thickness = 2
PageOutline.Color = Color3.fromHSV(0, 1, 1)
PageOutline.Parent = PageMain
spawn(function()
    local hue = 0
    while PageOutline.Parent do
        hue = (hue + 0.002) % 1
        PageOutline.Color = Color3.fromHSV(hue, 1, 1)
        task.wait(0.01)
    end
end)

-- Pages holder
local Pages = Instance.new("Frame")
Pages.Name = "Pages"
Pages.Size = UDim2.new(1, 0, 1, 0)
Pages.Position = UDim2.new(0, 0, 0, 0)
Pages.BackgroundTransparency = 1
Pages.BorderSizePixel = 0
Pages.ClipsDescendants = true
Pages.Parent = PageMain

-- Tab frame
local TabMain = Instance.new("Frame")
TabMain.Name = "TabMain"
TabMain.Size = UDim2.new(0, TAB_W, 0, TAB_H)
TabMain.Position = UDim2.new(0.018, 0, 0.159, 0)
TabMain.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TabMain.BorderSizePixel = 0
TabMain.ClipsDescendants = true
TabMain.Parent = ScreenGui

local TabCorner = Instance.new("UICorner")
TabCorner.CornerRadius = UDim.new(0, 10)
TabCorner.Parent = TabMain

-- RGB outline for TabMain
local TabOutline = Instance.new("UIStroke")
TabOutline.Thickness = 2
TabOutline.Color = Color3.fromHSV(0, 1, 1)
TabOutline.Parent = TabMain
spawn(function()
    local hue = 0
    while TabOutline.Parent do
        hue = (hue + 0.002) % 1
        TabOutline.Color = Color3.fromHSV(hue, 1, 1)
        task.wait(0.01)
    end
end)

-- keep TabMain height in sync
local function SyncTabHeight()
    TabMain.Size = UDim2.new(0, TAB_W, 0, math.min(PageMain.AbsoluteSize.Y, TAB_H))
end
PageMain:GetPropertyChangedSignal("AbsoluteSize"):Connect(SyncTabHeight)
SyncTabHeight()

-- helpers
local function addCorner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = inst
    return c
end

local function makeTextButton(parent, size, pos, bg, txt)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = bg
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Text = txt or ""
    b.AutoButtonColor = true
    b.BorderSizePixel = 0
    b.Parent = parent
    return b
end

local function makePageButton(parent, size, pos, bg, txt)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = bg
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 16
    b.Text = txt or ""
    b.AutoButtonColor = true
    b.BorderSizePixel = 0
    b.Parent = parent
    return b
end

local function CreatePage(name)
    local page = Instance.new("Frame")
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.Position = UDim2.new(0, 0, 0, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.BorderSizePixel = 0
    page.Parent = Pages
    addCorner(page, 10)
    return page
end

-- Create tab and page objects
local PlayerPage = CreatePage("PlayerPage") -- first tab is Player
local TPToolPage = CreatePage("TPToolPage")
local Tab3Page = CreatePage("Tab3Page")
local Tab4Page = CreatePage("Tab4Page")
local Tab5Page = CreatePage("Tab5Page")
local currentPage = PlayerPage
currentPage.Visible = true

-- Tab container (non-scrolling)
local TabScroll = Instance.new("Frame")
TabScroll.Size = UDim2.new(1, 0, 1, 0)
TabScroll.Position = UDim2.new(0, 0, 0, 0)
TabScroll.BackgroundTransparency = 1
TabScroll.BorderSizePixel = 0
TabScroll.Parent = TabMain

-- create tab buttons
local tabIndex = 0
local function CreateTab(name, pageFrame)
    local GAP = 8
    local BTN_SIDE = TAB_W - 25
    local y = tabIndex * (BTN_SIDE + GAP) + 5
    tabIndex += 1

    local btn = makeTextButton(
        TabScroll,
        UDim2.new(1, -5, 0, BTN_SIDE),
        UDim2.new(0, 3, 0, y),
        Color3.fromRGB(200,0,0),
        name
    )
    addCorner(btn, 6)

    btn.MouseButton1Click:Connect(function()
        if currentPage ~= pageFrame then
            currentPage.Visible = false
            pageFrame.Visible = true
            currentPage = pageFrame
        end
    end)

    return btn
end

-- Create 5 tabs
CreateTab("Player", PlayerPage)
CreateTab("TP Tool", TPToolPage)
CreateTab("Tab3", Tab3Page)
CreateTab("Tab4", Tab4Page)
CreateTab("Tab5", Tab5Page)

-- Toggle helper (kept, but not instantiating page-area cosmetic buttons)
local function CreateToggleButton(parent, text, yPos, onToggle)
    local enabled = false
    local btn = makePageButton(parent, UDim2.new(1, -(PAGE_BTN_MARGIN * 2), 0, PAGE_BTN_HEIGHT), UDim2.new(0, PAGE_BTN_MARGIN, 0, yPos), Color3.fromRGB(200,0,0), text)
    btn.TextXAlignment = Enum.TextXAlignment.Right
    addCorner(btn, 6)

    local square = Instance.new("Frame")
    square.Size = UDim2.new(0, 20, 0, 20)
    square.Position = UDim2.new(0, 8, 0.5, 0)
    square.AnchorPoint = Vector2.new(0, 0.5)
    square.BackgroundColor3 = Color3.fromRGB(255,255,255)
    square.BorderSizePixel = 0
    square.Parent = btn
    addCorner(square, 4)

    local outline = Instance.new("UIStroke")
    outline.Thickness = 2
    outline.Color = Color3.fromRGB(255,255,255)
    outline.Parent = square

    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        square.BackgroundColor3 = enabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,255,255)
        if onToggle then
            local ok, err = pcall(function() onToggle(enabled) end)
            if not ok then warn("Toggle callback error:", err) end
        end
    end)

    return btn, square
end

local function CreateTextboxToggle(parent, yPos, placeholder, onToggle)
    local enabled = false

    local container = makePageButton(parent, UDim2.new(1, -(PAGE_BTN_MARGIN*2), 0, PAGE_BTN_HEIGHT), UDim2.new(0, PAGE_BTN_MARGIN, 0, yPos), Color3.fromRGB(200,0,0), "")
    addCorner(container, 6)

    -- Center label "Speed" (added)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -130, 1, 0) -- leave room for left & right elements
    label.Position = UDim2.new(0, 60, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "Speed"
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = container

    -- TextBox (left) - starts at "1"
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0, 44, 0, PAGE_BTN_HEIGHT - 10)
    input.Position = UDim2.new(0, 6, 0, 5)
    input.BackgroundColor3 = Color3.fromRGB(30,30,30)
    input.TextColor3 = Color3.fromRGB(255,255,255)
    input.Font = Enum.Font.Gotham
    input.TextSize = 16
    input.PlaceholderText = ""
    input.ClearTextOnFocus = false
    input.TextEditable = true
    input.Text = "1"
    input.Parent = container
    addCorner(input, 4)

    -- Toggle square (right)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 22, 0, 22)
    toggleBtn.Position = UDim2.new(1, -34, 0.5, 0)
    toggleBtn.AnchorPoint = Vector2.new(0, 0.5)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
    toggleBtn.Text = ""
    toggleBtn.Parent = container
    addCorner(toggleBtn, 4)
    local toggleOutline = Instance.new("UIStroke")
    toggleOutline.Thickness = 2
    toggleOutline.Color = Color3.fromRGB(255,255,255)
    toggleOutline.Parent = toggleBtn

    local function setState(b)
        enabled = b and true or false
        toggleBtn.BackgroundColor3 = enabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,255,255)
        if onToggle then
            local ok, err = pcall(function() onToggle(input.Text, enabled) end)
            if not ok then warn("TextboxToggle callback error:", err) end
        end
    end

    -- Clicking container toggles, unless editing the textbox
    container.MouseButton1Click:Connect(function()
        if UserInputService:GetFocusedTextBox() == input then
            return
        end
        setState(not enabled)
    end)

    -- clicking the square also toggles
    toggleBtn.MouseButton1Click:Connect(function()
        setState(not enabled)
    end)

    input.FocusLost:Connect(function()
        if onToggle then
            local ok, err = pcall(function() onToggle(input.Text, enabled) end)
            if not ok then warn("TextboxToggle callback error:", err) end
        end
    end)

    return {
        container = container,
        input = input,
        toggle = toggleBtn,
        Enabled = enabled,
        Set = setState
    }
end


-- Noclip toggle
local function setCharacterCollision(state)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = state
        end
    end
end

local function CreateNoclipToggle(parent, yPos)
    return CreateToggleButton(parent, "Noclip", yPos, function(enabled)
        if enabled then
            setCharacterCollision(false)
        else
            setCharacterCollision(true)
        end
    end)
end

CreateNoclipToggle(PlayerPage, 20 + PAGE_BTN_HEIGHT + PAGE_BTN_GAPY + 4)

-- GUI hide/show button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 40, 0, 40)
ToggleButton.Position = UDim2.new(0.05, 0, 0.02, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Text = "≡"
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 23
ToggleButton.Active = true
ToggleButton.Draggable = true
ToggleButton.BorderSizePixel = 0
ToggleButton.Parent = ScreenGui
addCorner(ToggleButton, 6)
ToggleButton.ZIndex = 10

local isVisible = true
ToggleButton.MouseButton1Click:Connect(function()
    isVisible = not isVisible
    PageMain.Visible = isVisible
    TabMain.Visible = isVisible
end)
