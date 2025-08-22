-- Full TPUI — complete GUI backbone with clean CreateButton / CreateToggle / CreateTextbox / RenameTab API
-- Visuals / layout kept consistent with original; no page-area buttons auto-instantiated.

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
local PAGE_BTN_MARGIN = 20
local PAGE_BTN_HEIGHT = 40
local PAGE_BTN_GAPY = 10

-- helper: add corner
local function addCorner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = inst
    return c
end

-- helper: add RGB outline (animating)
local function addRGBOutline(frame, thickness)
    local outline = Instance.new("UIStroke")
    outline.Thickness = thickness or 2
    outline.Color = Color3.fromHSV(0, 1, 1)
    outline.Parent = frame
    spawn(function()
        local hue = 0
        while outline.Parent do
            hue = (hue + 0.002) % 1
            outline.Color = Color3.fromHSV(hue, 1, 1)
            task.wait(0.01)
        end
    end)
    return outline
end

-- Page frame (draggable, spawn a bit higher)
local PageMain = Instance.new("Frame")
PageMain.Name = "PageMain"
PageMain.Size = UDim2.new(0, PAGE_W, 0, PAGE_H)
PageMain.Position = UDim2.new(0.3, 0, 0.22, 0)
PageMain.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
PageMain.Active = true
PageMain.Draggable = true
PageMain.BorderSizePixel = 0
PageMain.Parent = ScreenGui
addCorner(PageMain, 10)
addRGBOutline(PageMain)

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
addCorner(TabMain, 10)
addRGBOutline(TabMain)

-- keep TabMain height in sync
local function SyncTabHeight()
    TabMain.Size = UDim2.new(0, TAB_W, 0, math.min(PageMain.AbsoluteSize.Y, TAB_H))
end
PageMain:GetPropertyChangedSignal("AbsoluteSize"):Connect(SyncTabHeight)
SyncTabHeight()

-- small button factories (kept as tiny low-level helpers)
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

-- CreatePage
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

-- Create pages and set current page
local PlayerPage = CreatePage("PlayerPage")
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

-- Tab registry
local tabIndex = 0
local TabButtonsByName = {}
local TabButtonsArray = {}

-- CreateTab (registers buttons and wires switching)
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

    -- register
    TabButtonsByName[name] = btn
    table.insert(TabButtonsArray, btn)

    return btn
end

-- New TPUI library (simple API)
local TPUI = {}

-- Helper: resolve a page by name or direct Frame
local function resolvePage(pageOrName)
    if type(pageOrName) == "string" then
        -- accept either exact keys we exported below ("Player", "TPTool", "Tab3", etc.)
        local map = {
            Player = PlayerPage,
            TPTool = TPToolPage,
            Tab3 = Tab3Page,
            Tab4 = Tab4Page,
            Tab5 = Tab5Page
        }
        return map[pageOrName] or Pages:FindFirstChild(pageOrName) or nil
    elseif typeof(pageOrName) == "Instance" and pageOrName:IsA("Frame") then
        return pageOrName
    else
        return nil
    end
end

-- Helper: compute next Y offset on a page by looking at existing children layout
local function getNextY(page)
    -- find bottom-most point used by direct children and place next after gap
    local maxBottom = PAGE_BTN_GAPY -- start small margin
    for _, child in ipairs(page:GetChildren()) do
        if child:IsA("GuiObject") then
            -- only consider objects placed with absolute offsets (common for our buttons)
            local yPos = 0
            local h = 0
            if child.Position and child.Size then
                -- use offset fallback if scale used
                yPos = child.Position.Y.Offset or 0
                h = child.Size.Y.Offset or 0
            end
            local bottom = yPos + h
            if bottom > maxBottom then maxBottom = bottom end
        end
    end
    return maxBottom + PAGE_BTN_GAPY
end

--[[
    TPUI:CreateButton(pageOrName, text, onClick)
    - pageOrName: string (e.g. "Player") or Frame
    - text: button text
    - onClick: function() called when pressed (pcall wrapped)
    Returns: the TextButton instance
]]
function TPUI:CreateButton(pageOrName, text, onClick)
    local page = resolvePage(pageOrName)
    if not page then
        warn("TPUI:CreateButton - invalid page:", pageOrName)
        return nil
    end
    local y = getNextY(page)
    local btn = makePageButton(page, UDim2.new(1, -(PAGE_BTN_MARGIN * 2), 0, PAGE_BTN_HEIGHT),
        UDim2.new(0, PAGE_BTN_MARGIN, 0, y), Color3.fromRGB(200,0,0), tostring(text or "Button"))
    addCorner(btn, 6)
    if onClick then
        btn.MouseButton1Click:Connect(function()
            local ok, err = pcall(onClick)
            if not ok then warn("TPUI button callback error:", err) end
        end)
    end
    return btn
end

--[[
    TPUI:CreateToggle(pageOrName, text, default, onToggle)
    - pageOrName: string or Frame
    - text: label text shown on the right
    - default: boolean initial state
    - onToggle: function(state) called on change (pcall wrapped)
    Returns: btn, square, api { Set = fn, Get = fn }
    Usage: TPUI:CreateToggle("Player","Noclip",false,function(s) ... end)
]]
function TPUI:CreateToggle(pageOrName, text, default, onToggle)
    local page = resolvePage(pageOrName)
    if not page then
        warn("TPUI:CreateToggle - invalid page:", pageOrName)
        return nil
    end
    local y = getNextY(page)
    local enabled = default and true or false
    local btn = makePageButton(page, UDim2.new(1, -(PAGE_BTN_MARGIN * 2), 0, PAGE_BTN_HEIGHT),
        UDim2.new(0, PAGE_BTN_MARGIN, 0, y), Color3.fromRGB(200,0,0), tostring(text or "Toggle"))
    addCorner(btn, 6)
    btn.TextXAlignment = Enum.TextXAlignment.Right

    local square = Instance.new("Frame")
    square.Size = UDim2.new(0, 20, 0, 20)
    square.Position = UDim2.new(0, 8, 0.5, 0)
    square.AnchorPoint = Vector2.new(0, 0.5)
    square.BackgroundColor3 = enabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,255,255)
    square.BorderSizePixel = 0
    square.Parent = btn
    addCorner(square, 4)
    local outline = Instance.new("UIStroke")
    outline.Thickness = 2
    outline.Color = Color3.fromRGB(255,255,255)
    outline.Parent = square

    local function callCallback(state)
        if onToggle then
            local ok, err = pcall(function() onToggle(state) end)
            if not ok then warn("TPUI toggle callback error:", err) end
        end
    end

    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        square.BackgroundColor3 = enabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,255,255)
        callCallback(enabled)
    end)

    local function SetState(b)
        enabled = b and true or false
        square.BackgroundColor3 = enabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,255,255)
        callCallback(enabled)
    end
    local function GetState() return enabled end

    return btn, square, { Set = SetState, Get = GetState }
end

--[[
    TPUI:CreateTextbox(pageOrName, placeholderOrLabel, onSubmit)
    - pageOrName: string or Frame
    - placeholderOrLabel: string shown on the button's label / placeholder
    - onSubmit: function(text) called when focus lost or Enter pressed (pcall wrapped)
    Returns: container, input, api { SetText = fn, GetText = fn }
    Usage: TPUI:CreateTextbox("Player", "Name", function(t) print(t) end)
]]
function TPUI:CreateTextbox(pageOrName, placeholderOrLabel, onSubmit)
    local page = resolvePage(pageOrName)
    if not page then
        warn("TPUI:CreateTextbox - invalid page:", pageOrName)
        return nil
    end
    local y = getNextY(page)

    local container = makePageButton(page, UDim2.new(1, -(PAGE_BTN_MARGIN * 2), 0, PAGE_BTN_HEIGHT),
        UDim2.new(0, PAGE_BTN_MARGIN, 0, y), Color3.fromRGB(200,0,0), "")
    addCorner(container, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -130, 1, 0)
    label.Position = UDim2.new(0, 60, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(placeholderOrLabel or "Input")
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = container

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0, 180, 0, PAGE_BTN_HEIGHT - 10)
    input.Position = UDim2.new(0, 6, 0, 5)
    input.BackgroundColor3 = Color3.fromRGB(30,30,30)
    input.TextColor3 = Color3.fromRGB(255,255,255)
    input.Font = Enum.Font.Gotham
    input.TextSize = 16
    input.PlaceholderText = ""
    input.ClearTextOnFocus = false
    input.TextEditable = true
    input.Text = ""
    input.Parent = container
    addCorner(input, 4)

    local function callCallback(text)
        if onSubmit then
            local ok, err = pcall(function() onSubmit(text) end)
            if not ok then warn("TPUI textbox callback error:", err) end
        end
    end

    input.FocusLost:Connect(function(enterPressed)
        callCallback(input.Text)
    end)

    local api = {
        SetText = function(t) input.Text = tostring(t or "") end,
        GetText = function() return input.Text end
    }

    return container, input, api
end

--[[
    TPUI:RenameTab(key, newName)
    - key: string (old name) or number (index)
    - newName: string
    Returns: true on success, false otherwise
    Example: TPUI:RenameTab("Player", "Me") or TPUI:RenameTab(1, "Me")
]]
function TPUI:RenameTab(key, newName)
    if type(newName) ~= "string" then return false end
    if type(key) == "string" then
        local btn = TabButtonsByName[key]
        if btn and btn.Parent then
            TabButtonsByName[newName] = btn
            TabButtonsByName[key] = nil
            btn.Text = newName
            return true
        end
        return false
    elseif type(key) == "number" then
        local btn = TabButtonsArray[key]
        if btn and btn.Parent then
            local oldName
            for n,b in pairs(TabButtonsByName) do
                if b == btn then oldName = n; break end
            end
            if oldName then TabButtonsByName[oldName] = nil end
            TabButtonsByName[newName] = btn
            btn.Text = newName
            return true
        end
        return false
    else
        return false
    end
end

-- Create 5 tabs (names preserved)
CreateTab("Player", PlayerPage)
CreateTab("TP Tool", TPToolPage)
CreateTab("Tab3", Tab3Page)
CreateTab("Tab4", Tab4Page)
CreateTab("Tab5", Tab5Page)

-- Noclip factory (kept, now uses TPUI:CreateToggle)
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
    -- NOTE: The library auto-positions buttons; pass the page name or Frame.
    local btn, square, api = TPUI:CreateToggle(parent, "Noclip", false, function(enabled)
        if enabled then setCharacterCollision(false) else setCharacterCollision(true) end
    end)
    return btn, square, api
end

-- GUI hide/show button (kept)
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

-- Expose API globals for convenience (optional)
_G.TPUI = TPUI
_G.TPUI_CreatePage = CreatePage
_G.TPUI_Pages = {
    Player = PlayerPage,
    TPTool = TPToolPage,
    Tab3 = Tab3Page,
    Tab4 = Tab4Page,
    Tab5 = Tab5Page
}

-- End of TPUI backbone
