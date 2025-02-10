--[[
  OrionLib - A UI Library for Roblox
  -----------------------------------
  This version removes the console functionality and improves animations.
  It also adds a built-in settings tab to adjust menu transparency and makes
  the toggler icon draggable.
  
  Enjoy and happy scripting!
--]]

-----------------------
-- SERVICES & VARIABLES
-----------------------
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

-----------------------
-- PREMIUM SYSTEM (Example)
-----------------------
local function GrantPremiumToAll()
    for _, player in ipairs(Players:GetPlayers()) do
        player:SetAttribute("Premium", true)
    end
end
Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("Premium", true)
end)
local function IsPremium(player)
    return player:GetAttribute("Premium") == true
end
GrantPremiumToAll()

-----------------------
-- OrionLib Table Setup
-----------------------
local OrionLib = {
    Elements = {},
    ThemeObjects = {},
    Connections = {},
    Flags = {},
    Themes = {
        Default = {
            Main    = Color3.fromRGB(22, 2, 28),
            Second  = Color3.fromRGB(61, 28, 71),
            Stroke  = Color3.fromRGB(60, 60, 60),
            Divider = Color3.fromRGB(60, 60, 60),
            Text    = Color3.fromRGB(240, 240, 240),
            TextDark= Color3.fromRGB(150, 150, 150)
        }
    },
    SelectedTheme = "Default",
    Folder = nil,
    SaveCfg = false
}

-----------------------
-- Feather Icons (Optional)
-----------------------
local Icons = {}
local success, response = pcall(function()
    Icons = HttpService:JSONDecode(game:HttpGetAsync("https://raw.githubusercontent.com/7kayoh/feather-roblox/refs/heads/main/src/Modules/asset.lua")).icons
end)
if not success then
    warn("OrionLib - Failed to load Feather Icons. Error code: " .. response)
end
local function GetIcon(IconName)
    return Icons[IconName] or nil
end

-----------------------
-- GUI SETUP
-----------------------
local Orion = Instance.new("ScreenGui")
Orion.Name = "Orion"
-- Always parent to CoreGui (no fallback)
Orion.Parent = game:GetService("CoreGui")

function OrionLib:IsRunning()
    return Orion.Parent == game:GetService("CoreGui")
end

local function AddConnection(signal, func)
    if not OrionLib:IsRunning() then return end
    local conn = signal:Connect(func)
    table.insert(OrionLib.Connections, conn)
    return conn
end

task.spawn(function()
    while OrionLib:IsRunning() do
        wait()
    end
    for _, conn in ipairs(OrionLib.Connections) do
        conn:Disconnect()
    end
end)

-----------------------
-- DRAGGABLE FUNCTION
-----------------------
local function MakeDraggable(dragPoint, mainObject)
    pcall(function()
        local dragging, dragInput, startMousePos, startPos = false, nil, nil, nil
        AddConnection(dragPoint.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                startMousePos = input.Position
                startPos = mainObject.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        AddConnection(dragPoint.InputChanged, function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        AddConnection(UserInputService.InputChanged, function(input)
            if input == dragInput and dragging then
                local delta = input.Position - startMousePos
                local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                TweenService:Create(mainObject, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = newPos}):Play()
                mainObject.Position = newPos
            end
        end)
    end)
end

-----------------------
-- UTILITY FUNCTIONS
-----------------------
local function Create(name, props, children)
    local obj = Instance.new(name)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    for _, child in pairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

local function CreateElement(name, func)
    OrionLib.Elements[name] = function(...) return func(...) end
end

local function MakeElement(name, ...)
    return OrionLib.Elements[name](...)
end

local function SetProps(obj, props)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

local function SetChildren(obj, children)
    for _, child in pairs(children) do
        child.Parent = obj
    end
    return obj
end

local function Round(num, factor)
    local result = math.floor(num / factor + (math.sign(num) * 0.5)) * factor
    if result < 0 then result = result + factor end
    return result
end

local function ReturnProperty(obj)
    if obj:IsA("Frame") or obj:IsA("TextButton") then
        return "BackgroundColor3"
    elseif obj:IsA("ScrollingFrame") then
        return "ScrollBarImageColor3"
    elseif obj:IsA("UIStroke") then
        return "Color"
    elseif obj:IsA("TextLabel") or obj:IsA("TextBox") then
        return "TextColor3"
    elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
        return "ImageColor3"
    end
end

local function AddThemeObject(obj, type)
    OrionLib.ThemeObjects[type] = OrionLib.ThemeObjects[type] or {}
    table.insert(OrionLib.ThemeObjects[type], obj)
    obj[ReturnProperty(obj)] = OrionLib.Themes[OrionLib.SelectedTheme][type]
    return obj
end

local function SetTheme()
    for name, tbl in pairs(OrionLib.ThemeObjects) do
        for _, obj in pairs(tbl) do
            obj[ReturnProperty(obj)] = OrionLib.Themes[OrionLib.SelectedTheme][name]
        end
    end
end

local function PackColor(color)
    return {R = color.R * 255, G = color.G * 255, B = color.B * 255}
end

local function UnpackColor(color)
    return Color3.fromRGB(color.R, color.G, color.B)
end

local function LoadCfg(config)
    local data = HttpService:JSONDecode(config)
    for k, v in pairs(data) do
        if OrionLib.Flags[k] then
            spawn(function()
                if OrionLib.Flags[k].Type == "Colorpicker" then
                    OrionLib.Flags[k]:Set(UnpackColor(v))
                else
                    OrionLib.Flags[k]:Set(v)
                end
            end)
        else
            warn("OrionLib Config Loader - Could not find key", k, v)
        end
    end
end

local function SaveCfg(name)
    local data = {}
    for k, v in pairs(OrionLib.Flags) do
        if v.Save then
            if v.Type == "Colorpicker" then
                data[k] = PackColor(v.Value)
            else
                data[k] = v.Value
            end
        end
    end
    -- (Optionally, write data to a file)
end

-----------------------
-- UI ELEMENTS (Examples)
-----------------------
CreateElement("Corner", function(scale, offset)
    return Create("UICorner", {CornerRadius = UDim.new(scale or 0, offset or 10)})
end)

CreateElement("Stroke", function(color, thickness)
    return Create("UIStroke", {Color = color or Color3.fromRGB(255,255,255), Thickness = thickness or 1})
end)

CreateElement("List", function(scale, offset)
    return Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(scale or 0, offset or 0)})
end)

CreateElement("Padding", function(bottom, left, right, top)
    return Create("UIPadding", {PaddingBottom = UDim.new(0, bottom or 4), PaddingLeft = UDim.new(0, left or 4), PaddingRight = UDim.new(0, right or 4), PaddingTop = UDim.new(0, top or 4)})
end)

CreateElement("TFrame", function()
    return Create("Frame", {BackgroundTransparency = 1})
end)

CreateElement("Frame", function(color)
    return Create("Frame", {BackgroundColor3 = color or Color3.fromRGB(255,255,255), BorderSizePixel = 0})
end)

CreateElement("RoundFrame", function(color, scale, offset)
    return Create("Frame", {BackgroundColor3 = color or Color3.fromRGB(255,255,255), BorderSizePixel = 0}, {Create("UICorner", {CornerRadius = UDim.new(scale, offset)})})
end)

CreateElement("Button", function()
    return Create("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0})
end)

CreateElement("ScrollFrame", function(color, width)
    return Create("ScrollingFrame", {BackgroundTransparency = 1, MidImage = "rbxassetid://7445543667", BottomImage = "rbxassetid://7445543667", TopImage = "rbxassetid://7445543667", ScrollBarImageColor3 = color, BorderSizePixel = 0, ScrollBarThickness = width, CanvasSize = UDim2.new(0,0,0,0)})
end)

CreateElement("Image", function(imageID)
    local img = Create("ImageLabel", {Image = imageID, BackgroundTransparency = 1})
    if GetIcon(imageID) then img.Image = GetIcon(imageID) end
    return img
end)

CreateElement("ImageButton", function(imageID)
    return Create("ImageButton", {Image = imageID, BackgroundTransparency = 1})
end)

CreateElement("Label", function(text, textSize, transparency)
    return Create("TextLabel", {Text = text or "", TextColor3 = Color3.fromRGB(240,240,240), TextTransparency = transparency or 0, TextSize = textSize or 15, Font = Enum.Font.FredokaOne, RichText = true, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
end)

-----------------------
-- NOTIFICATION EXAMPLE
-----------------------
local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
    SetProps(MakeElement("List"), {HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0,5)})
}), {Position = UDim2.new(1,-25,1,-25), Size = UDim2.new(0,300,1,-25), AnchorPoint = Vector2.new(1,1), Parent = Orion})

function OrionLib:MakeNotification(config)
    spawn(function()
        config.Name = config.Name or "Notification"
        config.Content = config.Content or "Test"
        config.Image = config.Image or "rbxassetid://4384403532"
        config.Time = config.Time or 15

        local notifParent = SetProps(MakeElement("TFrame"), {Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y, Parent = NotificationHolder})
        local notifFrame = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(25,25,25),0,10), {Parent = notifParent, Size = UDim2.new(1,0,0,0), Position = UDim2.new(1,-55,0,0), BackgroundTransparency = 0, AutomaticSize = Enum.AutomaticSize.Y}), {
            MakeElement("Stroke", Color3.fromRGB(93,93,93), 1.2),
            MakeElement("Padding", 12,12,12,12),
            SetProps(MakeElement("Image", config.Image), {Size = UDim2.new(0,20,0,20), ImageColor3 = Color3.fromRGB(240,240,240), Name = "Icon"}),
            SetProps(MakeElement("Label", config.Name,15), {Size = UDim2.new(1,-30,0,20), Position = UDim2.new(0,30,0,0), Font = Enum.Font.FredokaOne, Name = "Title"}),
            SetProps(MakeElement("Label", config.Content,14), {Size = UDim2.new(1,0,0,0), Position = UDim2.new(0,0,0,25), Font = Enum.Font.FredokaOne, Name = "Content", AutomaticSize = Enum.AutomaticSize.Y, TextColor3 = Color3.fromRGB(200,200,200), TextWrapped = true})
        })
        TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0,0,0,0)}):Play()
        wait(config.Time - 0.88)
        TweenService:Create(notifFrame.Icon, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 1}):Play()
        TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.6}):Play()
        wait(0.3)
        TweenService:Create(notifFrame.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.9}):Play()
        TweenService:Create(notifFrame.Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
        TweenService:Create(notifFrame.Content, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.5}):Play()
        wait(0.05)
        notifFrame:TweenPosition(UDim2.new(1,20,0,0), "In", "Quad", 0.3, true)
        wait(1.35)
        notifFrame:Destroy()
    end)
end

-----------------------
-- CONFIGURATION & INIT
-----------------------
function OrionLib:Init()
    if OrionLib.SaveCfg then
        pcall(function()
            if isfile(OrionLib.Folder .. "/" .. game.GameId .. ".txt") then
                LoadCfg(readfile(OrionLib.Folder .. "/" .. game.GameId .. ".txt"))
                OrionLib:MakeNotification({Name = "Configuration", Content = "Auto-loaded configuration for the game " .. game.GameId .. ".", Time = 5})
            end
        end)
    end
end

-----------------------
-- NEW: MENU TRANSPARENCY FUNCTION
-----------------------
function OrionLib:SetMenuTransparency(transparency)
    if OrionLib.MainWindow then
        OrionLib.MainWindow.BackgroundTransparency = transparency
        if OrionLib.MainWindow:FindFirstChild("TopBar") then
            OrionLib.MainWindow.TopBar.BackgroundTransparency = transparency
        end
    end
end

-----------------------
-- MAIN WINDOW CREATION
-----------------------
function OrionLib:MakeWindow(WindowConfig)
    local FirstTab, Minimized, UIHidden = true, false, false
    WindowConfig = WindowConfig or {}
    WindowConfig.Name = WindowConfig.Name or "Yonkai"
    WindowConfig.ConfigFolder = WindowConfig.ConfigFolder or WindowConfig.Name
    WindowConfig.SaveConfig = WindowConfig.SaveConfig or false
    WindowConfig.HidePremium = WindowConfig.HidePremium or false
    if WindowConfig.IntroEnabled == nil then WindowConfig.IntroEnabled = true end
    WindowConfig.IntroToggleIcon = WindowConfig.IntroToggleIcon or "rbxassetid://8834748103"
    WindowConfig.IntroText = WindowConfig.IntroText or "Yonkai"
    WindowConfig.CloseCallback = WindowConfig.CloseCallback or function() end
    WindowConfig.ShowIcon = WindowConfig.ShowIcon or false
    WindowConfig.Icon = WindowConfig.Icon or "rbxassetid://8834748103"
    WindowConfig.IntroIcon = WindowConfig.IntroIcon or "rbxassetid://8834748103"
    OrionLib.Folder = WindowConfig.ConfigFolder
    OrionLib.SaveCfg = WindowConfig.SaveConfig
    if WindowConfig.SaveConfig and not isfolder(WindowConfig.ConfigFolder) then
        makefolder(WindowConfig.ConfigFolder)
    end

    local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255,255,255),4), {Size = UDim2.new(1,0,1,-50)}), {MakeElement("List"), MakeElement("Padding",8,0,0,8)}), "Divider")
    AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        TabHolder.CanvasSize = UDim2.new(0,0,0,TabHolder.UIListLayout.AbsoluteContentSize.Y+16)
    end)

    local CloseBtn = SetChildren(SetProps(MakeElement("Button"), {Size = UDim2.new(0.5,0,1,0), Position = UDim2.new(0.5,0,0,0), BackgroundTransparency = 1}), {
        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072725342"), {Position = UDim2.new(0,9,0,6), Size = UDim2.new(0,18,0,18)}), "Text")
    })
    local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), {Size = UDim2.new(0.5,0,1,0), BackgroundTransparency = 1}), {
        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072719338"), {Position = UDim2.new(0,9,0,6), Size = UDim2.new(0,18,0,18), Name = "Ico"}), "Text")
    })
    local DragPoint = SetProps(MakeElement("TFrame"), {Size = UDim2.new(1,0,0,50)})

    local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255),0,10), {Size = UDim2.new(0,150,1,-50), Position = UDim2.new(0,0,0,50)}), {
        AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(1,0,0,10), Position = UDim2.new(0,0,0,0)}), "Second"),
        AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(0,10,1,0), Position = UDim2.new(1,-10,0,0)}), "Second"),
        AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(0,1,1,0), Position = UDim2.new(1,-1,0,0)}), "Stroke"),
        TabHolder,
        SetChildren(SetProps(MakeElement("TFrame"), {Size = UDim2.new(1,0,0,50), Position = UDim2.new(0,0,1,-50)}), {
            AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(1,0,0,1)}), "Stroke"),
            AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {AnchorPoint = Vector2.new(0,0.5), Size = UDim2.new(0,32,0,32), Position = UDim2.new(0,10,0.5,0)}), {
                SetProps(MakeElement("Image", "https://www.roblox.com/headshot-thumbnail/image?userId="..LocalPlayer.UserId.."&width=420&height=420&format=png"), {Size = UDim2.new(1,0,1,0)}),
                AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4031889928"), {Size = UDim2.new(1,0,1,0)}), "Second"),
                MakeElement("Corner",1)
            }), "Divider"),
            SetChildren(SetProps(MakeElement("TFrame"), {AnchorPoint = Vector2.new(0,0.5), Size = UDim2.new(0,32,0,32), Position = UDim2.new(0,10,0.5,0)}), {
                AddThemeObject(MakeElement("Stroke"), "Stroke"),
                MakeElement("Corner",1)
            }),
            AddThemeObject(SetProps(MakeElement("Label", "User", WindowConfig.HidePremium and 14 or 13), {Size = UDim2.new(1,-60,0,13), Position = WindowConfig.HidePremium and UDim2.new(0,50,0,19) or UDim2.new(0,50,0,12), Font = Enum.Font.FredokaOne, ClipsDescendants = true}), "Text"),
            AddThemeObject(SetProps(MakeElement("Label", "",12), {Size = UDim2.new(1,-60,0,12), Position = UDim2.new(0,50,1,-25), Visible = not WindowConfig.HidePremium}), "TextDark")
        })
    }), "Second")

    local WindowName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.Name,14), {Size = UDim2.new(1,-30,2,0), Position = UDim2.new(0,25,0,-24), Font = Enum.Font.FredokaOne, TextSize = 20}), "Text")
    local WindowTopBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-1)}), "Stroke")

    local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255),0,10), {Parent = Orion, Position = UDim2.new(0.5,-307,0.5,-172), Size = UDim2.new(0,615,0,344), ClipsDescendants = true}), {
        SetChildren(SetProps(MakeElement("TFrame"), {Size = UDim2.new(1,0,0,50), Name = "TopBar"}), {WindowName, WindowTopBarLine, AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255),0,7), {Size = UDim2.new(0,70,0,30), Position = UDim2.new(1,-90,0,10)}), {
            AddThemeObject(MakeElement("Stroke"), "Stroke"),
            AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(0,1,1,0), Position = UDim2.new(0.5,0,0,0)}), "Stroke"),
            CloseBtn, MinimizeBtn
        }), "Second")}),
        DragPoint, WindowStuff
    }), "Main")
    
    OrionLib.MainWindow = MainWindow  -- store for transparency adjustments

    if WindowConfig.ShowIcon then
        WindowName.Position = UDim2.new(0,50,0,-24)
        local WindowIcon = SetProps(MakeElement("Image", WindowConfig.Icon), {Size = UDim2.new(0,20,0,20), Position = UDim2.new(0,25,0,15)})
        WindowIcon.Parent = MainWindow.TopBar
    end

    MakeDraggable(DragPoint, MainWindow)

    local MobileReopenButton = SetChildren(SetProps(MakeElement("Button"), {Parent = Orion, Size = UDim2.new(0,40,0,40), Position = UDim2.new(0.5,-20,0,20), BackgroundTransparency = 0, BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main, Visible = false}), {
        AddThemeObject(SetProps(MakeElement("Image", WindowConfig.IntroToggleIcon or "http://www.roblox.com/asset/?id=8834748103"), {AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0), Size = UDim2.new(0.7,0,0.7,0)}), "Text"),
        MakeElement("Corner",1)
    })
    
    -- Make the toggler icon draggable.
    MakeDraggable(MobileReopenButton, MobileReopenButton)

    AddConnection(CloseBtn.MouseButton1Up, function()
        MainWindow.Visible = false
        MobileReopenButton.Visible = true
        UIHidden = true
        OrionLib:MakeNotification({Name = "Interface Hidden", Content = "Tap Left Control to reopen the interface", Time = 5})
        WindowConfig.CloseCallback()
    end)

    AddConnection(UserInputService.InputBegan, function(input)
        if input.KeyCode == Enum.KeyCode.LeftControl and UIHidden then
            MainWindow.Visible = true
            MobileReopenButton.Visible = false
        end
    end)

    AddConnection(MobileReopenButton.Activated, function()
        MainWindow.Visible = true
        MobileReopenButton.Visible = false
    end)

    AddConnection(MinimizeBtn.MouseButton1Up, function()
        if Minimized then
            TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0,615,0,344)}):Play()
            MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
            wait(0.03)
            MainWindow.ClipsDescendants = false
            WindowStuff.Visible = true
            WindowTopBarLine.Visible = true
        else
            MainWindow.ClipsDescendants = true
            WindowTopBarLine.Visible = false
            MinimizeBtn.Ico.Image = "rbxassetid://7072720870"
            TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0,WindowName.TextBounds.X+140,0,50)}):Play()
            wait(0.1)
            WindowStuff.Visible = false
        end
        Minimized = not Minimized
    end)

    local function LoadSequence()
        MainWindow.Visible = false
        local LoadSequenceLogo = SetProps(MakeElement("Image", WindowConfig.IntroIcon), {Parent = Orion, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.4,0), Size = UDim2.new(0,28,0,28), ImageColor3 = Color3.fromRGB(255,255,255), ImageTransparency = 1})
        local LoadSequenceText = SetProps(MakeElement("Label", WindowConfig.IntroText,14), {Parent = Orion, Size = UDim2.new(1,0,1,0), AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,19,0.5,0), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.FredokaOne, TextTransparency = 1})
        TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0, Position = UDim2.new(0.5,0,0.5,0)}):Play()
        wait(0.8)
        TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -(LoadSequenceText.TextBounds.X/2), 0.5, 0)}):Play()
        wait(0.3)
        TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
        wait(2)
        TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        MainWindow.Visible = true
        LoadSequenceLogo:Destroy()
        LoadSequenceText:Destroy()
    end

    if WindowConfig.IntroEnabled then
        LoadSequence()
    end

    local TabFunction = {}
    function TabFunction:MakeTab(TabConfig)
        TabConfig = TabConfig or {}
        TabConfig.Name = TabConfig.Name or "Tab"
        TabConfig.Icon = TabConfig.Icon or ""
        TabConfig.PremiumOnly = TabConfig.PremiumOnly or false
        local isPremium = LocalPlayer:GetAttribute("Premium") == true
        local TabFrame = SetChildren(SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,0,30), Parent = TabHolder}), {
            AddThemeObject(SetProps(MakeElement("Image", TabConfig.Icon), {AnchorPoint = Vector2.new(0,0.5), Size = UDim2.new(0,18,0,18), Position = UDim2.new(0,10,0.5,0), ImageTransparency = 0.4, Name = "Ico"}), "Text"),
            AddThemeObject(SetProps(MakeElement("Label", TabConfig.Name,14), {Size = UDim2.new(1,-35,1,0), Position = UDim2.new(0,35,0,0), Font = Enum.Font.FredokaOne, TextTransparency = 0.4, Name = "Title"}), "Text")
        })
        if GetIcon(TabConfig.Icon) then
            TabFrame.Ico.Image = GetIcon(TabConfig.Icon)
        end
        local Container = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255,255,255),5), {Size = UDim2.new(1,-150,1,-50), Position = UDim2.new(0,150,0,50), Parent = MainWindow, Visible = false, Name = "ItemContainer"}), {MakeElement("List",0,6), MakeElement("Padding",15,10,10,15)}), "Divider")
        AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            Container.CanvasSize = UDim2.new(0,0,0,Container.UIListLayout.AbsoluteContentSize.Y+30)
        end)
        if FirstTab then
            FirstTab = false
            TabFrame.Ico.ImageTransparency = 0
            TabFrame.Title.TextTransparency = 0
            TabFrame.Title.Font = Enum.Font.FredokaOne
            Container.Visible = true
        end
        AddConnection(TabFrame.MouseButton1Click, function()
            for _, Tab in pairs(TabHolder:GetChildren()) do
                if Tab:IsA("TextButton") then
                    Tab.Title.Font = Enum.Font.FredokaOne
                    TweenService:Create(Tab.Ico, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0.4}):Play()
                    TweenService:Create(Tab.Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
                end
            end
            for _, ItemContainer in pairs(MainWindow:GetChildren()) do
                if ItemContainer.Name == "ItemContainer" then
                    ItemContainer.Visible = false
                end
            end
            TweenService:Create(TabFrame.Ico, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
            TweenService:Create(TabFrame.Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
            TabFrame.Title.Font = Enum.Font.FredokaOne
            Container.Visible = true
        end)
        local function GetElements(ItemParent)
            local ElementFunction = {}
            function ElementFunction:AddLabel(Text)
                local LabelFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255),0,5), {Size = UDim2.new(1,0,0,30), BackgroundTransparency = 0.7, Parent = ItemParent}), {
                    AddThemeObject(SetProps(MakeElement("Label", Text,15), {Size = UDim2.new(1,-12,1,0), Position = UDim2.new(0,12,0,0), Font = Enum.Font.FredokaOne, Name = "Content"}), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke")
                }), "Second")
                local LabelFunction = {}
                function LabelFunction:Set(newText)
                    LabelFrame.Content.Text = newText
                end
                return LabelFunction
            end
            function ElementFunction:AddParagraph(Text, Content)
                Text = Text or "Text"
                Content = Content or "Content"
                local ParagraphFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255),0,5), {Size = UDim2.new(1,0,0,30), BackgroundTransparency = 0.7, Parent = ItemParent}), {
                    AddThemeObject(SetProps(MakeElement("Label", Text,15), {Size = UDim2.new(1,-12,0,14), Position = UDim2.new(0,12,0,10), Font = Enum.Font.FredokaOne, Name = "Title"}), "Text"),
                    AddThemeObject(SetProps(MakeElement("Label", "",13), {Size = UDim2.new(1,-24,0,0), Position = UDim2.new(0,12,0,26), Font = Enum.Font.FredokaOne, Name = "Content", TextWrapped = true}), "TextDark"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke")
                }), "Second")
                AddConnection(ParagraphFrame.Content:GetPropertyChangedSignal("Text"), function()
                    ParagraphFrame.Content.Size = UDim2.new(1,-24,0,ParagraphFrame.Content.TextBounds.Y)
                    ParagraphFrame.Size = UDim2.new(1,0,0,ParagraphFrame.Content.TextBounds.Y+35)
                end)
                ParagraphFrame.Content.Text = Content
                local ParagraphFunction = {}
                function ParagraphFunction:Set(newContent)
                    ParagraphFrame.Content.Text = newContent
                end
                return ParagraphFunction
            end    
            function ElementFunction:AddButton(ButtonConfig)
                ButtonConfig = ButtonConfig or {}
                ButtonConfig.Name = ButtonConfig.Name or "Button"
                ButtonConfig.Callback = ButtonConfig.Callback or function() end
                ButtonConfig.Icon = ButtonConfig.Icon or "rbxassetid://3944703587"
                local Button = {}
                local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
                local ButtonFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255),0,5), {Size = UDim2.new(1,0,0,33), Parent = ItemParent}), {
                    AddThemeObject(SetProps(MakeElement("Label", ButtonConfig.Name,15), {Size = UDim2.new(1,-12,1,0), Position = UDim2.new(0,12,0,0), Font = Enum.Font.FredokaOne, Name = "Content"}), "Text"),
                    AddThemeObject(SetProps(MakeElement("Image", ButtonConfig.Icon), {Size = UDim2.new(0,20,0,20), Position = UDim2.new(1,-30,0,7)}), "TextDark"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    Click
                }), "Second")
                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+3,
                                                         OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+3,
                                                         OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+3)
                    }):Play()
                end)
                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second
                    }):Play()
                end)
                AddConnection(Click.MouseButton1Up, function()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+3,
                                                         OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+3,
                                                         OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+3)
                    }):Play()
                    spawn(function() ButtonConfig.Callback() end)
                end)
                AddConnection(Click.MouseButton1Down, function()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+6,
                                                         OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+6,
                                                         OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+6)
                    }):Play()
                end)
                function Button:Set(text)
                    ButtonFrame.Content.Text = text
                end
                return Button
            end    
            function ElementFunction:AddToggle(ToggleConfig)
                ToggleConfig = ToggleConfig or {}
                ToggleConfig.Name = ToggleConfig.Name or "Toggle"
                ToggleConfig.Default = ToggleConfig.Default or false
                ToggleConfig.Callback = ToggleConfig.Callback or function() end
                ToggleConfig.Color = ToggleConfig.Color or Color3.fromRGB(9,99,195)
                ToggleConfig.Flag = ToggleConfig.Flag or nil
                ToggleConfig.Save = ToggleConfig.Save or false
                local Toggle = {Value = ToggleConfig.Default, Save = ToggleConfig.Save}
                local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
                local ToggleBox = SetChildren(SetProps(MakeElement("RoundFrame", ToggleConfig.Color,0,4), {Size = UDim2.new(0,24,0,24), Position = UDim2.new(1,-24,0.5,0), AnchorPoint = Vector2.new(0.5,0.5)}), {
                    SetProps(MakeElement("Stroke"), {Color = ToggleConfig.Color, Name = "Stroke", Transparency = 0.5}),
                    SetProps(MakeElement("Image", "rbxassetid://3944680095"), {Size = UDim2.new(0,20,0,20), AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0), ImageColor3 = Color3.fromRGB(255,255,255), Name = "Ico"})
                })
                local ToggleFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255),0,5), {Size = UDim2.new(1,0,0,38), Parent = ItemParent}), {
                    AddThemeObject(SetProps(MakeElement("Label", ToggleConfig.Name,15), {Size = UDim2.new(1,-12,1,0), Position = UDim2.new(0,12,0,0), Font = Enum.Font.FredokaOne, Name = "Content"}), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    ToggleBox, Click
                }), "Second")
                function Toggle:Set(val)
                    Toggle.Value = val
                    TweenService:Create(ToggleBox, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Toggle.Value and ToggleConfig.Color or OrionLib.Themes.Default.Divider
                    }):Play()
                    TweenService:Create(ToggleBox.Stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Color = Toggle.Value and ToggleConfig.Color or OrionLib.Themes.Default.Stroke
                    }):Play()
                    TweenService:Create(ToggleBox.Ico, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        ImageTransparency = Toggle.Value and 0 or 1,
                        Size = Toggle.Value and UDim2.new(0,20,0,20) or UDim2.new(0,8,0,8)
                    }):Play()
                    ToggleConfig.Callback(Toggle.Value)
                end
                Toggle:Set(Toggle.Value)
                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(ToggleFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+3,
                                                         OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+3,
                                                         OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+3)
                    }):Play()
                end)
                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(ToggleFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second
                    }):Play()
                end)
                AddConnection(Click.MouseButton1Up, function()
                    TweenService:Create(ToggleFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+3,
                                                         OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+3,
                                                         OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+3)
                    }):Play()
                    SaveCfg(game.GameId)
                    Toggle:Set(not Toggle.Value)
                end)
                AddConnection(Click.MouseButton1Down, function()
                    TweenService:Create(ToggleFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+6,
                                                         OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+6,
                                                         OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+6)
                    }):Play()
                end)
                if ToggleConfig.Flag then
                    OrionLib.Flags[ToggleConfig.Flag] = Toggle
                end
                return Toggle
            end  
            function ElementFunction:AddSlider(SliderConfig)
                SliderConfig = SliderConfig or {}
                SliderConfig.Name = SliderConfig.Name or "Slider"
                SliderConfig.Min = SliderConfig.Min or 0
                SliderConfig.Max = SliderConfig.Max or 100
                SliderConfig.Increment = SliderConfig.Increment or 1
                SliderConfig.Default = SliderConfig.Default or 50
                SliderConfig.Callback = SliderConfig.Callback or function() end
                SliderConfig.ValueName = SliderConfig.ValueName or ""
                SliderConfig.Color = SliderConfig.Color or Color3.fromRGB(9,149,98)
                SliderConfig.Flag = SliderConfig.Flag or nil
                SliderConfig.Save = SliderConfig.Save or false
                local Slider = {Value = SliderConfig.Default, Save = SliderConfig.Save}
                local Dragging = false
                local SliderDrag = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color,0,5), {Size = UDim2.new(0,0,1,0), BackgroundTransparency = 0.3, ClipsDescendants = true}), {
                    AddThemeObject(SetProps(MakeElement("Label", "value",13), {Size = UDim2.new(1,-12,0,14), Position = UDim2.new(0,12,0,6), Font = Enum.Font.FredokaOne, Name = "Value", TextTransparency = 0}), "Text")
                })
                local SliderBar = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color,0,5), {Size = UDim2.new(1,-24,0,26), Position = UDim2.new(0,12,0,30), BackgroundTransparency = 0.9}), {
                    SetProps(MakeElement("Stroke"), {Color = SliderConfig.Color}),
                    AddThemeObject(SetProps(MakeElement("Label", "value",13), {Size = UDim2.new(1,-12,0,14), Position = UDim2.new(0,12,0,6), Font = Enum.Font.FredokaOne, Name = "Value", TextTransparency = 0.8}), "Text"),
                    SliderDrag
                })
                local SliderFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255),0,4), {Size = UDim2.new(1,0,0,65), Parent = ItemParent}), {
                    AddThemeObject(SetProps(MakeElement("Label", SliderConfig.Name,15), {Size = UDim2.new(1,-12,0,14), Position = UDim2.new(0,12,0,10), Font = Enum.Font.FredokaOne, Name = "Content"}), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    SliderBar
                }), "Second")
                SliderBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = true
                    end
                end)
                SliderBar.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if Dragging then
                        local sizeScale = math.clamp((Mouse.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                        Slider:Set(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * sizeScale))
                        SaveCfg(game.GameId)
                    end
                end)
                function Slider:Set(val)
                    self.Value = math.clamp(Round(val, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
                    TweenService:Create(SliderDrag, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromScale((self.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min), 1)}):Play()
                    SliderBar.Value.Text = tostring(self.Value) .. " " .. SliderConfig.ValueName
                    SliderDrag.Value.Text = tostring(self.Value) .. " " .. SliderConfig.ValueName
                    SliderConfig.Callback(self.Value)
                end
                Slider:Set(Slider.Value)
                if SliderConfig.Flag then
                    OrionLib.Flags[SliderConfig.Flag] = Slider
                end
                return Slider
            end  
            function ElementFunction:AddDropdown(DropdownConfig)
                DropdownConfig = DropdownConfig or {}
                DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
                DropdownConfig.Options = DropdownConfig.Options or {}
                DropdownConfig.Default = DropdownConfig.Default or ""
                DropdownConfig.Callback = DropdownConfig.Callback or function() end
                DropdownConfig.Flag = DropdownConfig.Flag or nil
                DropdownConfig.Save = DropdownConfig.Save or false
                local Dropdown = {Value = DropdownConfig.Default, Options = DropdownConfig.Options, Buttons = {}, Toggled = false, Type = "Dropdown", Save = DropdownConfig.Save}
                local MaxElements = 5
                if not table.find(Dropdown.Options, Dropdown.Value) then
                    Dropdown.Value = "..."
                end
                local DropdownList = MakeElement("List")
                local DropdownContainer = AddThemeObject(SetProps(SetChildren(MakeElement("ScrollFrame", Color3.fromRGB(40,40,40),4), {DropdownList}), {Parent = ItemParent, Position = UDim2.new(0,0,0,38), Size = UDim2.new(1,0,1,-38), ClipsDescendants = true}), "Divider")
                local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
                local DropdownFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255),0,5), {Size = UDim2.new(1,0,0,38), Parent = ItemParent, ClipsDescendants = true}), {
                    DropdownContainer,
                    SetProps(SetChildren(MakeElement("TFrame"), {
                        AddThemeObject(SetProps(MakeElement("Label", DropdownConfig.Name,15), {Size = UDim2.new(1,-12,1,0), Position = UDim2.new(0,12,0,0), Font = Enum.Font.FredokaOne, Name = "Content"}), "Text"),
                        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072706796"), {Size = UDim2.new(0,20,0,20), AnchorPoint = Vector2.new(0,0.5), Position = UDim2.new(1,-30,0.5,0), ImageColor3 = Color3.fromRGB(240,240,240), Name = "Ico"}), "TextDark"),
                        AddThemeObject(SetProps(MakeElement("Label", "Selected",13), {Size = UDim2.new(1,-40,1,0), Font = Enum.Font.FredokaOne, Name = "Selected", TextXAlignment = Enum.TextXAlignment.Right}), "TextDark"),
                        AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-1), Name = "Line", Visible = false}), "Stroke"),
                        Click
                    }), {Size = UDim2.new(1,0,0,38), ClipsDescendants = true, Name = "F"})
                }), "Second")
                AddConnection(DropdownList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                    DropdownContainer.CanvasSize = UDim2.new(0,0,0,DropdownList.AbsoluteContentSize.Y)
                end)
                local function AddOptions(options)
                    for _, option in pairs(options) do
                        local OptionBtn = AddThemeObject(SetProps(SetChildren(MakeElement("Button", Color3.fromRGB(40,40,40)), {MakeElement("Corner",0,6), AddThemeObject(SetProps(MakeElement("Label", option,13,0.4), {Position = UDim2.new(0,8,0,0), Size = UDim2.new(1,-8,1,0), Name = "Title"}), "Text")}), {Parent = DropdownContainer, Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1, ClipsDescendants = true}), "Divider")
                        AddConnection(OptionBtn.MouseButton1Click, function()
                            Dropdown:Set(option)
                            SaveCfg(game.GameId)
                        end)
                        Dropdown.Buttons[option] = OptionBtn
                    end
                end
                function Dropdown:Refresh(options, delete)
                    if delete then
                        for _, v in pairs(Dropdown.Buttons) do
                            v:Destroy()
                        end
                        table.clear(Dropdown.Options)
                        table.clear(Dropdown.Buttons)
                    end
                    Dropdown.Options = options
                    AddOptions(Dropdown.Options)
                end
                function Dropdown:Set(value)
                    if not table.find(Dropdown.Options, value) then
                        Dropdown.Value = "..."
                        DropdownFrame.F.Selected.Text = Dropdown.Value
                        for _, v in pairs(Dropdown.Buttons) do
                            TweenService:Create(v, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
                            TweenService:Create(v.Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
                        end
                        return
                    end
                    Dropdown.Value = value
                    DropdownFrame.F.Selected.Text = Dropdown.Value
                    for _, v in pairs(Dropdown.Buttons) do
                        TweenService:Create(v, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
                        TweenService:Create(v.Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
                    end
                    TweenService:Create(Dropdown.Buttons[value], TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
                    TweenService:Create(Dropdown.Buttons[value].Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
                    return DropdownConfig.Callback(Dropdown.Value)
                end
                AddConnection(Click.MouseButton1Click, function()
                    Dropdown.Toggled = not Dropdown.Toggled
                    DropdownFrame.F.Line.Visible = Dropdown.Toggled
                    TweenService:Create(DropdownFrame.F.Ico, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = Dropdown.Toggled and 180 or 0}):Play()
                    if #Dropdown.Options > MaxElements then
                        TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Dropdown.Toggled and UDim2.new(1,0,0,38+(MaxElements*28)) or UDim2.new(1,0,0,38)}):Play()
                    else
                        TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Dropdown.Toggled and UDim2.new(1,0,0,DropdownList.AbsoluteContentSize.Y+38) or UDim2.new(1,0,0,38)}):Play()
                    end
                end)
                Dropdown:Refresh(Dropdown.Options, false)
                Dropdown:Set(Dropdown.Value)
                if DropdownConfig.Flag then
                    OrionLib.Flags[DropdownConfig.Flag] = Dropdown
                end
                return Dropdown
            end
            function ElementFunction:AddBind(BindConfig)
                BindConfig.Name = BindConfig.Name or "Bind"
                BindConfig.Default = BindConfig.Default or Enum.KeyCode.Unknown
                BindConfig.Hold = BindConfig.Hold or false
                BindConfig.Callback = BindConfig.Callback or function() end
                BindConfig.Flag = BindConfig.Flag or nil
                BindConfig.Save = BindConfig.Save or false
                local Bind = {Value, Binding = false, Type = "Bind", Save = BindConfig.Save}
                local Holding = false
                local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
                local BindBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255),0,4), {Size = UDim2.new(0,24,0,24), Position = UDim2.new(1,-12,0.5,0), AnchorPoint = Vector2.new(1,0.5)}), {
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name,14), {Size = UDim2.new(1,0,1,0), Font = Enum.Font.FredokaOne, TextXAlignment = Enum.TextXAlignment.Center, Name = "Value"}), "Text")
                }), "Main")
                local BindFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255),0,5), {Size = UDim2.new(1,0,0,38), Parent = ItemParent}), {
                    AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name,15), {Size = UDim2.new(1,-12,1,0), Position = UDim2.new(0,12,0,0), Font = Enum.Font.FredokaOne, Name = "Content"}), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    BindBox, Click
                }), "Second")
                AddConnection(BindBox.Value:GetPropertyChangedSignal("Text"), function()
                    TweenService:Create(BindBox, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0,BindBox.Value.TextBounds.X+16,0,24)}):Play()
                end)
                AddConnection(Click.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if Bind.Binding then return end
                        Bind.Binding = true
                        BindBox.Value.Text = ""
                    end
                end)
                AddConnection(UserInputService.InputBegan, function(input)
                    if UserInputService:GetFocusedTextBox() then return end
                    if (input.KeyCode.Name == Bind.Value or input.UserInputType.Name == Bind.Value) and not Bind.Binding then
                        if BindConfig.Hold then
                            Holding = true
                            BindConfig.Callback(Holding)
                        else
                            BindConfig.Callback()
                        end
                    elseif Bind.Binding then
                        local Key
                        pcall(function()
                            if not CheckKey(BlacklistedKeys, input.KeyCode) then
                                Key = input.KeyCode
                            end
                        end)
                        pcall(function()
                            if CheckKey(WhitelistedMouse, input.UserInputType) and not Key then
                                Key = input.UserInputType
                            end
                        end)
                        Key = Key or Bind.Value
                        Bind:Set(Key)
                        SaveCfg(game.GameId)
                    end
                end)
                AddConnection(UserInputService.InputEnded, function(input)
                    if input.KeyCode.Name == Bind.Value or input.UserInputType.Name == Bind.Value then
                        if BindConfig.Hold and Holding then
                            Holding = false
                            BindConfig.Callback(Holding)
                        end
                    end
                end)
                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(BindFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+3)}):Play()
                end)
                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(BindFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255, OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255, OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255)}):Play()
                end)
                AddConnection(Click.MouseButton1Up, function()
                    TweenService:Create(BindFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+3)}):Play()
                end)
                AddConnection(Click.MouseButton1Down, function()
                    TweenService:Create(BindFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+6, OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+6, OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+6)}):Play()
                end)
                function Bind:Set(Key)
                    Bind.Binding = false
                    Bind.Value = Key or Bind.Value
                    Bind.Value = Bind.Value.Name or Bind.Value
                    BindBox.Value.Text = Bind.Value
                end
                Bind:Set(BindConfig.Default)
                if BindConfig.Flag then
                    OrionLib.Flags[BindConfig.Flag] = Bind
                end
                return Bind
            end  
            function ElementFunction:AddTextbox(TextboxConfig)
                TextboxConfig = TextboxConfig or {}
                TextboxConfig.Name = TextboxConfig.Name or "Textbox"
                TextboxConfig.Default = TextboxConfig.Default or ""
                TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
                TextboxConfig.Callback = TextboxConfig.Callback or function() end
                local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
                local TextboxActual = AddThemeObject(Create("TextBox", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255,255,255), PlaceholderColor3 = Color3.fromRGB(210,210,210), PlaceholderText = "Input", Font = Enum.Font.FredokaOne, TextXAlignment = Enum.TextXAlignment.Center, TextSize = 14, ClearTextOnFocus = false}), "Text")
                local TextContainer = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255),0,4), {Size = UDim2.new(0,24,0,24), Position = UDim2.new(1,-12,0.5,0), AnchorPoint = Vector2.new(1,0.5)}), {AddThemeObject(MakeElement("Stroke"), "Stroke"), TextboxActual}), "Main")
                local TextboxFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255),0,5), {Size = UDim2.new(1,0,0,38), Parent = ItemParent}), {AddThemeObject(SetProps(MakeElement("Label", TextboxConfig.Name,15), {Size = UDim2.new(1,-12,1,0), Position = UDim2.new(0,12,0,0), Font = Enum.Font.FredokaOne, Name = "Content"}), "Text"), AddThemeObject(MakeElement("Stroke"), "Stroke"), TextContainer, Click}), "Second")
                AddConnection(TextboxActual:GetPropertyChangedSignal("Text"), function()
                    TweenService:Create(TextContainer, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0,TextboxActual.TextBounds.X+16,0,24)}):Play()
                end)
                AddConnection(TextboxActual.FocusLost, function()
                    TextboxConfig.Callback(TextboxActual.Text)
                    if TextboxConfig.TextDisappear then
                        TextboxActual.Text = ""
                    end
                end)
                TextboxActual.Text = TextboxConfig.Default
                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(TextboxFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+3)}):Play()
                end)
                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(TextboxFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second}):Play()
                end)
                AddConnection(Click.MouseButton1Up, function()
                    TweenService:Create(TextboxFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+3)}):Play()
                    TextboxActual:CaptureFocus()
                end)
                AddConnection(Click.MouseButton1Down, function()
                    TweenService:Create(TextboxFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R*255+6, OrionLib.Themes[OrionLib.SelectedTheme].Second.G*255+6, OrionLib.Themes[OrionLib.SelectedTheme].Second.B*255+6)}):Play()
                end)
            end 
            function ElementFunction:AddColorpicker(ColorpickerConfig)
                ColorpickerConfig = ColorpickerConfig or {}
                ColorpickerConfig.Name = ColorpickerConfig.Name or "Colorpicker"
                ColorpickerConfig.Default = ColorpickerConfig.Default or Color3.fromRGB(255,255,255)
                ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
                ColorpickerConfig.Flag = ColorpickerConfig.Flag or nil
                ColorpickerConfig.Save = ColorpickerConfig.Save or false
                local ColorH, ColorS, ColorV = 1,1,1
                local Colorpicker = {Value = ColorpickerConfig.Default, Toggled = false, Type = "Colorpicker", Save = ColorpickerConfig.Save}
                local ColorSelection = Create("ImageLabel", {Size = UDim2.new(0,18,0,18), Position = UDim2.new(select(3,Color3.toHSV(Colorpicker.Value))), ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5,0.5), BackgroundTransparency = 1, Image = "http://www.roblox.com/asset/?id=4805639000"})
                local HueSelection = Create("ImageLabel", {Size = UDim2.new(0,18,0,18), Position = UDim2.new(0.5,0,1-select(1,Color3.toHSV(Colorpicker.Value))), ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5,0.5), BackgroundTransparency = 1, Image = "http://www.roblox.com/asset/?id=4805639000"})
                local Color = Create("ImageLabel", {Size = UDim2.new(1,-25,1,0), Visible = false, Image = "rbxassetid://4155801252"}, {Create("UICorner", {CornerRadius = UDim.new(0,5)}), ColorSelection})
                local Hue = Create("Frame", {Size = UDim2.new(0,20,1,0), Position = UDim2.new(1,-20,0,0), Visible = false}, {Create("UIGradient", {Rotation = 270, Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00,Color3.fromRGB(255,0,4)), ColorSequenceKeypoint.new(0.20,Color3.fromRGB(234,255,0)), ColorSequenceKeypoint.new(0.40,Color3.fromRGB(21,255,0)), ColorSequenceKeypoint.new(0.60,Color3.fromRGB(0,255,255)), ColorSequenceKeypoint.new(0.80,Color3.fromRGB(0,17,255)), ColorSequenceKeypoint.new(0.90,Color3.fromRGB(255,0,251)), ColorSequenceKeypoint.new(1.00,Color3.fromRGB(255,0,4))}}), Create("UICorner", {CornerRadius = UDim.new(0,5)}), HueSelection})
                local ColorpickerContainer = Create("Frame", {Position = UDim2.new(0,0,0,32), Size = UDim2.new(1,0,1,-32), BackgroundTransparency = 1, ClipsDescendants = true}, {Hue, Color, Create("UIPadding", {PaddingLeft = UDim.new(0,35), PaddingRight = UDim.new(0,35), PaddingBottom = UDim.new(0,10), PaddingTop = UDim.new(0,17)})})
                local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
                local ColorpickerBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255),0,4), {Size = UDim2.new(0,24,0,24), Position = UDim2.new(1,-12,0.5,0), AnchorPoint = Vector2.new(1,0.5)}), {AddThemeObject(MakeElement("Stroke"), "Stroke")}), "Main")
                local ColorpickerFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255),0,5), {Size = UDim2.new(1,0,0,38), Parent = ItemParent}), {SetProps(SetChildren(MakeElement("TFrame"), {AddThemeObject(SetProps(MakeElement("Label", ColorpickerConfig.Name,15), {Size = UDim2.new(1,-12,1,0), Position = UDim2.new(0,12,0,0), Font = Enum.Font.FredokaOne, Name = "Content"}), "Text"), ColorpickerBox, Click, AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-1), Name = "Line", Visible = false}), "Stroke")}), {Size = UDim2.new(1,0,0,38), ClipsDescendants = true, Name = "F"}), ColorpickerContainer, AddThemeObject(MakeElement("Stroke"), "Stroke")}), "Second")
                AddConnection(Click.MouseButton1Click, function()
                    Colorpicker.Toggled = not Colorpicker.Toggled
                    TweenService:Create(ColorpickerFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Colorpicker.Toggled and UDim2.new(1,0,0,148) or UDim2.new(1,0,0,38)}):Play()
                    Color.Visible = Colorpicker.Toggled
                    Hue.Visible = Colorpicker.Toggled
                    ColorpickerFrame.F.Line.Visible = Colorpicker.Toggled
                end)
                local function UpdateColorPicker()
                    ColorpickerBox.BackgroundColor3 = Color3.fromHSV(ColorH,ColorS,ColorV)
                    Color.BackgroundColor3 = Color3.fromHSV(ColorH,1,1)
                    Colorpicker:Set(ColorpickerBox.BackgroundColor3)
                    ColorpickerConfig.Callback(ColorpickerBox.BackgroundColor3)
                    SaveCfg(game.GameId)
                end
                ColorH = 1 - (math.clamp(HueSelection.AbsolutePosition.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)
                ColorS = (math.clamp(ColorSelection.AbsolutePosition.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
                ColorV = 1 - (math.clamp(ColorSelection.AbsolutePosition.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)
                AddConnection(Color.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if ColorInput then ColorInput:Disconnect() end
                        ColorInput = AddConnection(RunService.RenderStepped, function()
                            local ColorX = (math.clamp(Mouse.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
                            local ColorY = (math.clamp(Mouse.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)
                            ColorSelection.Position = UDim2.new(ColorX,0,ColorY,0)
                            ColorS = ColorX
                            ColorV = 1 - ColorY
                            UpdateColorPicker()
                        end)
                    end
                end)
                AddConnection(Color.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if ColorInput then ColorInput:Disconnect() end
                    end
                end)
                AddConnection(Hue.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if HueInput then HueInput:Disconnect() end
                        HueInput = AddConnection(RunService.RenderStepped, function()
                            local HueY = (math.clamp(Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)
                            HueSelection.Position = UDim2.new(0.5,0,HueY,0)
                            ColorH = 1 - HueY
                            UpdateColorPicker()
                        end)
                    end
                end)
                AddConnection(Hue.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if HueInput then HueInput:Disconnect() end
                    end
                end)
                function Colorpicker:Set(val)
                    Colorpicker.Value = val
                    ColorpickerBox.BackgroundColor3 = Colorpicker.Value
                    ColorpickerConfig.Callback(Colorpicker.Value)
                end
                Colorpicker:Set(Colorpicker.Value)
                if ColorpickerConfig.Flag then
                    OrionLib.Flags[ColorpickerConfig.Flag] = Colorpicker
                end
                return Colorpicker
            end  
            return ElementFunction
        end

        local ElementFunction = {}
        function ElementFunction:AddSection(SectionConfig)
            SectionConfig.Name = SectionConfig.Name or "Section"
            local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {Size = UDim2.new(1,0,0,26), Parent = Container}), {
                AddThemeObject(SetProps(MakeElement("Label", SectionConfig.Name,14), {Size = UDim2.new(1,-12,0,16), Position = UDim2.new(0,0,0,3), Font = Enum.Font.FredokaOne}), "TextDark"),
                SetChildren(SetProps(MakeElement("TFrame"), {AnchorPoint = Vector2.new(0,0), Size = UDim2.new(1,0,1,-24), Position = UDim2.new(0,0,0,23), Name = "Holder"}), {MakeElement("List",0,6)})
            })
            AddConnection(SectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                SectionFrame.Size = UDim2.new(1,0,0,SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y+31)
                SectionFrame.Holder.Size = UDim2.new(1,0,0,SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
            end)
            local SectionFunction = {}
            for i, v in next, GetElements(SectionFrame.Holder) do
                SectionFunction[i] = v
            end
            return SectionFunction
        end

        for i, v in next, GetElements(Container) do
            ElementFunction[i] = v
        end

        if TabConfig.PremiumOnly and not isPremium then
            for i, v in next, ElementFunction do
                ElementFunction[i] = function() end
            end
            Container:FindFirstChild("UIListLayout"):Destroy()
            Container:FindFirstChild("UIPadding"):Destroy()
            SetChildren(SetProps(MakeElement("TFrame"), {Size = UDim2.new(1,0,1,0), Parent = ItemParent}), {
                AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://3610239960"), {Size = UDim2.new(0,18,0,18), Position = UDim2.new(0,15,0,15), ImageTransparency = 0.4}), "Text"),
                AddThemeObject(SetProps(MakeElement("Label", "Unauthorised Access",14), {Size = UDim2.new(1,-38,0,14), Position = UDim2.new(0,38,0,18), TextTransparency = 0.4}), "Text"),
                AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4483345875"), {Size = UDim2.new(0,56,0,56), Position = UDim2.new(0,84,0,110)}), "Text"),
                AddThemeObject(SetProps(MakeElement("Label", "Premium Features",14), {Size = UDim2.new(1,-150,0,14), Position = UDim2.new(0,150,0,112), Font = Enum.Font.FredokaOne}), "Text"),
                AddThemeObject(SetProps(MakeElement("Label", "This part of the script is locked to Sirius Premium users. Purchase Premium in the Discord server (discord.gg/sirius)",12), {Size = UDim2.new(1,-200,0,14), Position = UDim2.new(0,150,0,138), TextWrapped = true, TextTransparency = 0.4}), "Text")
            })
        end
        return ElementFunction
    end

    local Tabs = TabFunction

    -- Automatically add a "Settings" tab with a slider for menu transparency.
    local SettingsTab = Tabs:MakeTab({Name = "Settings", Icon = "rbxassetid://603107593", PremiumOnly = false})
    SettingsTab:AddSlider({
        Name = "Menu Transparency",
        Min = 0,       -- Fully opaque
        Max = 1,       -- Fully transparent
        Default = 0,   -- Start at opaque
        Increment = 0.05,
        ValueName = "",
        Callback = function(val)
            OrionLib:SetMenuTransparency(val)
        end
    })

    return Tabs
end

-----------------------
-- RETURN ORIONLIB
-----------------------
return OrionLib
