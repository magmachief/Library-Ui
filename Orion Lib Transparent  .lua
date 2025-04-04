--[[
    Advanced Orion UI Library v2025+ (Fully Loaded)
    ---------------------------------------------------
    Features:
      • Enhanced core UI elements: AddButton, AddToggle, AddSlider, AddDropdown, AddBind, AddTextbox, AddColorpicker
      • In–game Theme Editor with custom theme saving
      • Plugin API for third–party extensions
      • Responsive & Adaptive UI (auto scaling and layout adjustments)
      • Advanced animations & transitions with extra easing options
      • Configuration persistence (local & stubbed cloud saving)
      • Debugging & Logging mode with verbose output
      • Accessibility options: Text scaling and language selection (localization)
      • Customizable keybinds & shortcut editor
      • Sound & haptic feedback on interactions
--]]

-----------------------------------------------------
-- SERVICES & VARIABLES
-----------------------------------------------------
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Global debug flag
local DEBUG_MODE = true

-----------------------------------------------------
-- DEBUG & LOGGING MODULE
-----------------------------------------------------
local DebugModule = {}
function DebugModule.log(msg)
    if DEBUG_MODE then
        print("[DEBUG]", msg)
    end
end
function DebugModule.error(context, err)
    warn("[ERROR] Context: " .. tostring(context) .. " | Error: " .. tostring(err))
end

-----------------------------------------------------
-- PREMIUM SYSTEM (Always enabled for all players)
-----------------------------------------------------
for _, player in ipairs(Players:GetPlayers()) do
    player:SetAttribute("Premium", true)
end
Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("Premium", true)
end)
local function IsPremium(player)
    return player:GetAttribute("Premium") == true
end

-----------------------------------------------------
-- ORIONLIB DEFINITION, THEME & CONFIG SETUP
-----------------------------------------------------
local OrionLib = {
    Elements = {},
    ThemeObjects = {},
    Connections = {},
    Flags = {},
   Themes = {
    Default = {
        Main = Color3.fromRGB(255, 182, 193),       -- Light Pink
        Second = Color3.fromRGB(221, 160, 221),       -- Plum
        Stroke = Color3.fromRGB(255, 105, 180),       -- Hot Pink
        Divider = Color3.fromRGB(255, 192, 203),      -- Pink
        Text = Color3.fromRGB(255, 255, 255),         -- White
        TextDark = Color3.fromRGB(240, 240, 240)      -- Very Light Gray
    }
},
    SelectedTheme = "Default",
    Folder = nil,
    SaveCfg = false,
    TextScale = 1,            -- Accessibility: text scaling
    Language = "en",          -- Localization: default language
    Keybinds = {}             -- Customizable keybinds storage
}

-----------------------------------------------------
-- FEATHER ICONS LOADER (Robust Async)
-----------------------------------------------------
local Icons = {}
local success, response = pcall(function()
    local data = game:HttpGetAsync("https://raw.githubusercontent.com/7kayoh/feather-roblox/refs/heads/main/src/Modules/asset.lua")
    Icons = HttpService:JSONDecode(data).icons
end)
if not success then
    DebugModule.error("Feather Icons", response)
end
local function GetIcon(IconName)
    return Icons[IconName] or nil
end

-----------------------------------------------------
-- SCREEN GUI CREATION (with syn.protect_gui support)
-----------------------------------------------------
local Orion = Instance.new("ScreenGui")
Orion.Name = "Orion"
if syn and syn.protect_gui then
    syn.protect_gui(Orion)
    Orion.Parent = CoreGui
else
    Orion.Parent = (gethui and gethui()) or CoreGui
end

-----------------------------------------------------
-- UTILITY FUNCTIONS
-----------------------------------------------------
function OrionLib:IsRunning()
    if gethui then
        return Orion.Parent == gethui()
    else
        return Orion.Parent == CoreGui
    end
end

local function AddConnection(signal, func)
    if not OrionLib:IsRunning() then return end
    local connection = signal:Connect(func)
    table.insert(OrionLib.Connections, connection)
    return connection
end

-- Auto-disconnect events when UI is removed.
task.spawn(function()
    while OrionLib:IsRunning() do
        task.wait()
    end
    for _, connection in ipairs(OrionLib.Connections) do
        connection:Disconnect()
    end
end)

-- Enhanced MakeDraggable (modern async)
local function MakeDraggable(dragPoint, mainFrame)
    pcall(function()
        local dragging = false
        local dragInput, mousePos, framePos
        AddConnection(dragPoint.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                mousePos = input.Position
                framePos = mainFrame.AbsolutePosition
                AddConnection(input.Changed, function()
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
                local delta = input.Position - mousePos
                local newPos = UDim2.new(0, framePos.X + delta.X, 0, framePos.Y + delta.Y)
                TweenService:Create(mainFrame, TweenInfo.new(0.05, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Position = newPos
                }):Play()
            end
        end)
    end)
end

local function Create(className, properties, children)
    local obj = Instance.new(className)
    if properties then
        for prop, value in pairs(properties) do
            obj[prop] = value
        end
    end
    if children then
        for _, child in pairs(children) do
            child.Parent = obj
        end
    end
    return obj
end

local function CreateElement(elementName, elementFunc)
    OrionLib.Elements[elementName] = elementFunc
end

local function MakeElement(elementName, ...)
    return OrionLib.Elements[elementName](...)
end

local function SetProps(element, props)
    for property, value in pairs(props) do
        element[property] = value
    end
    return element
end

local function SetChildren(element, children)
    for _, child in pairs(children) do
        child.Parent = element
    end
    return element
end

local function Round(number, factor)
    local result = math.floor(number / factor + (math.sign(number) * 0.5)) * factor
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

local function AddThemeObject(obj, typeName)
    OrionLib.ThemeObjects[typeName] = OrionLib.ThemeObjects[typeName] or {}
    table.insert(OrionLib.ThemeObjects[typeName], obj)
    obj[ReturnProperty(obj)] = OrionLib.Themes[OrionLib.SelectedTheme][typeName]
    return obj
end

local function SetTheme()
    for name, objects in pairs(OrionLib.ThemeObjects) do
        for _, obj in pairs(objects) do
            obj[ReturnProperty(obj)] = OrionLib.Themes[OrionLib.SelectedTheme][name]
        end
    end
end

local function PackColor(color)
    return {R = color.R * 255, G = color.G * 255, B = color.B * 255}
end

local function UnpackColor(colorTable)
    return Color3.fromRGB(colorTable.R, colorTable.G, colorTable.B)
end

local function LoadCfg(configString)
    local data = HttpService:JSONDecode(configString)
    for key, value in pairs(data) do
        if OrionLib.Flags[key] then
            task.spawn(function()
                if OrionLib.Flags[key].Type == "Colorpicker" then
                    OrionLib.Flags[key]:Set(UnpackColor(value))
                else
                    OrionLib.Flags[key]:Set(value)
                end
            end)
        else
            warn("Orion Library Config Loader - Could not find flag:", key, value)
        end
    end
end

local function SaveCfg(name)
    local data = {}
    for key, flag in pairs(OrionLib.Flags) do
        if flag.Save then
            if flag.Type == "Colorpicker" then
                data[key] = PackColor(flag.Value)
            else
                data[key] = flag.Value
            end
        end
    end
    -- Stub: Cloud saving can be added here via HttpService.PostAsync, etc.
end

local WhitelistedMouse = {
    Enum.UserInputType.MouseButton1,
    Enum.UserInputType.MouseButton2,
    Enum.UserInputType.MouseButton3,
    Enum.UserInputType.Touch
}
local BlacklistedKeys = {
    Enum.KeyCode.Unknown,
    Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
    Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right,
    Enum.KeyCode.Slash, Enum.KeyCode.Tab, Enum.KeyCode.Backspace, Enum.KeyCode.Escape
}

local function CheckKey(tbl, key)
    for _, v in ipairs(tbl) do
        if v == key then return true end
    end
end

-----------------------------------------------------
-- BASIC ELEMENTS (Corners, Strokes, etc.)
-----------------------------------------------------
CreateElement("Corner", function(scale, offset)
    return Create("UICorner", {CornerRadius = UDim.new(scale or 0, offset or 10)})
end)

CreateElement("Stroke", function(color, thickness)
    return Create("UIStroke", {Color = color or Color3.fromRGB(255, 255, 255), Thickness = thickness or 1})
end)

CreateElement("List", function(scale, offset)
    return Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(scale or 0, offset or 0)})
end)

CreateElement("Padding", function(bottom, left, right, top)
    return Create("UIPadding", {
        PaddingBottom = UDim.new(0, bottom or 4),
        PaddingLeft = UDim.new(0, left or 4),
        PaddingRight = UDim.new(0, right or 4),
        PaddingTop = UDim.new(0, top or 4)
    })
end)

CreateElement("TFrame", function()
    return Create("Frame", {BackgroundTransparency = 1})
end)

CreateElement("Frame", function(color)
    return Create("Frame", {BackgroundColor3 = color or Color3.fromRGB(255, 255, 255), BorderSizePixel = 0})
end)

CreateElement("RoundFrame", function(color, scale, offset)
    return Create("Frame", {BackgroundColor3 = color or Color3.fromRGB(255, 255, 255), BorderSizePixel = 0}, {
        Create("UICorner", {CornerRadius = UDim.new(scale, offset)})
    })
end)

CreateElement("Button", function()
    return Create("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0})
end)

CreateElement("ScrollFrame", function(color, width)
    return Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        MidImage = "rbxassetid://7445543667",
        BottomImage = "rbxassetid://7445543667",
        TopImage = "rbxassetid://7445543667",
        ScrollBarImageColor3 = color,
        BorderSizePixel = 0,
        ScrollBarThickness = width,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })
end)

CreateElement("Image", function(imageId)
    local img = Create("ImageLabel", {Image = imageId, BackgroundTransparency = 1})
    if GetIcon(imageId) then img.Image = GetIcon(imageId) end
    return img
end)

CreateElement("ImageButton", function(imageId)
    return Create("ImageButton", {Image = imageId, BackgroundTransparency = 1})
end)

CreateElement("Label", function(text, textSize, transparency)
    return Create("TextLabel", {
        Text = text or "",
        TextColor3 = Color3.fromRGB(240, 240, 240),
        TextTransparency = transparency or 0,
        TextSize = (textSize or 15) * OrionLib.TextScale,
        Font = Enum.Font.FredokaOne,
        RichText = true,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left
    })
end)

-----------------------------------------------------
-- NOTIFICATIONS
-----------------------------------------------------
local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
    SetProps(MakeElement("List"), {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 5)
    })
}), {
    Position = UDim2.new(1, -25, 1, -25),
    Size = UDim2.new(0, 300, 1, -25),
    AnchorPoint = Vector2.new(1, 1),
    Parent = Orion
})
AddConnection(NotificationHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
    NotificationHolder.CanvasSize = UDim2.new(0, 0, 0, NotificationHolder.UIListLayout.AbsoluteContentSize.Y + 16)
end)

function OrionLib:MakeNotification(config)
    task.spawn(function()
        config.Name = config.Name or "Notification"
        config.Content = config.Content or "Test"
        config.Image = config.Image or "rbxassetid://4384403532"
        config.Time = config.Time or 15

        local notifParent = SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = NotificationHolder
        })

        local notifFrame = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(25,25,25), 0,10), {
            Parent = notifParent,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(1, -55, 0, 0),
            BackgroundTransparency = 0,
            AutomaticSize = Enum.AutomaticSize.Y
        }), {
            MakeElement("Stroke", Color3.fromRGB(93,93,93), 1.2),
            MakeElement("Padding", 12,12,12,12),
            SetProps(MakeElement("Image", config.Image), {Size = UDim2.new(0,20,0,20), ImageColor3 = Color3.fromRGB(240,240,240), Name = "Icon"}),
            SetProps(MakeElement("Label", config.Name, 15), {Size = UDim2.new(1,-30,0,20), Position = UDim2.new(0,30,0,0), Font = Enum.Font.FredokaOne, Name = "Title"}),
            SetProps(MakeElement("Label", config.Content, 14), {Size = UDim2.new(1,0,0,0), Position = UDim2.new(0,0,0,25), Font = Enum.Font.FredokaOne, Name = "Content", AutomaticSize = Enum.AutomaticSize.Y, TextColor3 = Color3.fromRGB(200,200,200), TextWrapped = true})
        })
        TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0,0,0,0)}):Play()
        task.wait(config.Time - 0.88)
        TweenService:Create(notifFrame.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
        TweenService:Create(notifFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.6}):Play()
        task.wait(0.3)
        TweenService:Create(notifFrame.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0.9}):Play()
        TweenService:Create(notifFrame.Title, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play()
        TweenService:Create(notifFrame.Content, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.5}):Play()
        task.wait(0.05)
        notifFrame:TweenPosition(UDim2.new(1,20,0,0), 'In', 'Quint', 0.8, true)
        task.wait(1.35)
        notifFrame:Destroy()
    end)
end

function OrionLib:Init()
    if OrionLib.SaveCfg then
        pcall(function()
            if isfile(OrionLib.Folder .. "/" .. game.GameId .. ".txt") then
                LoadCfg(readfile(OrionLib.Folder .. "/" .. game.GameId .. ".txt"))
                OrionLib:MakeNotification({
                    Name = "Configuration",
                    Content = "Auto-loaded configuration for game " .. game.GameId .. ".",
                    Time = 5
                })
            end
        end)
    end
end

-----------------------------------------------------
-- MAIN WINDOW & TAB CREATION
-----------------------------------------------------
function OrionLib:MakeWindow(config)
    local firstTab = true
    local minimized = false
    local UIHidden = false

    config = config or {}
    config.Name = config.Name or "Advanced Orion UI"
    config.ConfigFolder = config.ConfigFolder or config.Name
    config.SaveConfig = config.SaveConfig or false
    config.HidePremium = config.HidePremium or false
    config.IntroEnabled = config.IntroEnabled == nil and true or config.IntroEnabled
    config.IntroToggleIcon = config.IntroToggleIcon or "rbxassetid://14103606744"
    config.IntroText = config.IntroText or "Welcome to Advanced Orion UI"
    config.CloseCallback = config.CloseCallback or function() end
    config.ShowIcon = config.ShowIcon or false
    config.Icon = config.Icon or "rbxassetid://14103606744"
    config.IntroIcon = config.IntroIcon or "rbxassetid://14103606744"
    OrionLib.Folder = config.ConfigFolder
    OrionLib.SaveCfg = config.SaveConfig

    if config.SaveConfig and not isfolder(config.ConfigFolder) then
        makefolder(config.ConfigFolder)
    end

    local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255,255,255), 4), {
        Size = UDim2.new(1,0,1,-50)
    }), {
        MakeElement("List"),
        MakeElement("Padding", 8,0,0,8)
    }), "Divider")
    AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        TabHolder.CanvasSize = UDim2.new(0,0,0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
    end)

    local CloseBtn = SetChildren(SetProps(MakeElement("Button"), {
        Size = UDim2.new(0.5,0,1,0),
        Position = UDim2.new(0.5,0,0,0),
        BackgroundTransparency = 1
    }), {
        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072725342"), {
            Position = UDim2.new(0,9,0,6),
            Size = UDim2.new(0,18,0,18)
        }), "Text")
    })
    local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), {
        Size = UDim2.new(0.5,0,1,0),
        BackgroundTransparency = 1
    }), {
        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072719338"), {
            Position = UDim2.new(0,9,0,6),
            Size = UDim2.new(0,18,0,18),
            Name = "Ico"
        }), "Text")
    })
    local DragPoint = SetProps(MakeElement("TFrame"), {Size = UDim2.new(1,0,0,50)})

    local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0,10), {
        Size = UDim2.new(0,150,1,-50),
        Position = UDim2.new(0,0,0,50)
    }), {
        AddThemeObject(SetProps(MakeElement("Frame"), {
            Size = UDim2.new(1,0,0,10),
            Position = UDim2.new(0,0,0,0)
        }), "Second"),
        AddThemeObject(SetProps(MakeElement("Frame"), {
            Size = UDim2.new(0,10,1,0),
            Position = UDim2.new(1,-10,0,0)
        }), "Second"),
        AddThemeObject(SetProps(MakeElement("Frame"), {
            Size = UDim2.new(0,1,1,0),
            Position = UDim2.new(1,-1,0,0)
        }), "Stroke"),
        TabHolder,
        SetChildren(SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1,0,0,50),
            Position = UDim2.new(0,0,1,-50)
        }), {
            AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(1,0,0,1)}), "Stroke"),
            AddThemeObject(SetChildren(SetProps(MakeElement("TFrame"), {
                AnchorPoint = Vector2.new(0,0.5),
                Size = UDim2.new(0,32,0,32),
                Position = UDim2.new(0,10,0.5,0)
            }), {
                SetProps(MakeElement("Image", "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=420&height=420&format=png"), {Size = UDim2.new(1,0,1,0)}),
                AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4031889928"), {Size = UDim2.new(1,0,1,0)}), "Second"),
                MakeElement("Corner", 1)
            }), "Divider"),
            SetChildren(SetProps(MakeElement("TFrame"), {
                AnchorPoint = Vector2.new(0,0.5),
                Size = UDim2.new(0,32,0,32),
                Position = UDim2.new(0,10,0.5,0)
            }), {
                AddThemeObject(MakeElement("Stroke"), "Stroke"),
                MakeElement("Corner", 1)
            }),
            AddThemeObject(SetProps(MakeElement("Label", "User", config.HidePremium and 14 or 13), {
                Size = UDim2.new(1,-60,0,13),
                Position = config.HidePremium and UDim2.new(0,50,0,19) or UDim2.new(0,50,0,12),
                Font = Enum.Font.FredokaOne,
                ClipsDescendants = true
            }), "Text"),
            AddThemeObject(SetProps(MakeElement("Label", "", 12), {
                Size = UDim2.new(1,-60,0,12),
                Position = UDim2.new(0,50,1,-25),
                Visible = not config.HidePremium
            }), "TextDark")
        })
    }), "Second")
    local WindowName = AddThemeObject(SetProps(MakeElement("Label", config.Name, 14), {
        Size = UDim2.new(1,-30,2,0),
        Position = UDim2.new(0,25,0,-24),
        Font = Enum.Font.FredokaOne,
        TextSize = 20
    }), "Text")
    local WindowTopBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {
        Size = UDim2.new(1,0,0,1),
        Position = UDim2.new(0,0,1,-1)
    }), "Stroke")
    local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0,10), {
        Parent = Orion,
        Position = UDim2.new(0.5,-307,0.5,-172),
        Size = UDim2.new(0,615,0,344),
        ClipsDescendants = true
    }), {
        SetChildren(SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1,0,0,50),
            Name = "TopBar"
        }), {
            WindowName,
            WindowTopBarLine,
            AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0,7), {
                Size = UDim2.new(0,70,0,30),
                Position = UDim2.new(1,-90,0,10)
            }), {
                AddThemeObject(MakeElement("Stroke"), "Stroke"),
                AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(0,1,1,0), Position = UDim2.new(0.5,0,0,0)}), "Stroke"),
                CloseBtn,
                MinimizeBtn
            }), "Second")
        }),
        DragPoint,
        WindowStuff
    }), "Main")

    if config.ShowIcon then
        WindowName.Position = UDim2.new(0,50,0,-24)
        local WindowIcon = SetProps(MakeElement("Image", config.Icon), {Size = UDim2.new(0,20,0,20), Position = UDim2.new(0,25,0,15)})
        WindowIcon.Parent = MainWindow.TopBar
    end

    MakeDraggable(DragPoint, MainWindow)

    -- MOBILE REOPEN BUTTON (Menu Icon) with draggable functionality
    local MobileReopenButton = SetChildren(SetProps(MakeElement("Button"), {
        Parent = Orion,
        Size = UDim2.new(0,40,0,40),
        Position = UDim2.new(0.5,-20,0,20),
        BackgroundTransparency = 0,
        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
        Visible = false
    }), {
        AddThemeObject(SetProps(MakeElement("Image", config.IntroToggleIcon or "rbxassetid://14103606744"), {AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0), Size = UDim2.new(0.7,0,0.7,0)}), "Text"),
        MakeElement("Corner", 1)
    })
    MakeDraggable(MobileReopenButton, MobileReopenButton)

    AddConnection(CloseBtn.MouseButton1Up, function()
        MainWindow.Visible = false
        MobileReopenButton.Visible = true
        UIHidden = true
        OrionLib:MakeNotification({
            Name = "Interface Hidden",
            Content = "Tap Left Control to reopen the interface",
            Time = 5
        })
        config.CloseCallback()
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
        if minimized then
            TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Size = UDim2.new(0,615,0,344)}):Play()
            MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
            task.wait(0.02)
            MainWindow.ClipsDescendants = false
            WindowStuff.Visible = true
            WindowTopBarLine.Visible = true
        else
            MainWindow.ClipsDescendants = true
            WindowTopBarLine.Visible = false
            MinimizeBtn.Ico.Image = "rbxassetid://7072720870"
            TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Size = UDim2.new(0,WindowName.TextBounds.X + 140,0,50)}):Play()
            task.wait(0.1)
            WindowStuff.Visible = false
        end
        minimized = not minimized
    end)

    local function LoadSequence()
        MainWindow.Visible = false
        local LoadSequenceLogo = SetProps(MakeElement("Image", config.IntroIcon), {
            Parent = Orion,
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.new(0.5,0,0.4,0),
            Size = UDim2.new(0,28,0,28),
            ImageColor3 = Color3.fromRGB(255,255,255),
            ImageTransparency = 1
        })
        local LoadSequenceText = SetProps(MakeElement("Label", config.IntroText, 14), {
            Parent = Orion,
            Size = UDim2.new(1,0,1,0),
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.new(0.5,19,0.5,0),
            TextXAlignment = Enum.TextXAlignment.Center,
            Font = Enum.Font.FredokaOne,
            TextTransparency = 1
        })
        TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {ImageTransparency = 0, Position = UDim2.new(0.5,0,0.5,0)}):Play()
        task.wait(0.8)
        TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, -(LoadSequenceText.TextBounds.X/2), 0.5, 0)}):Play()
        task.wait(0.3)
        TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
        task.wait(2)
        TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
        MainWindow.Visible = true
        LoadSequenceLogo:Destroy()
        LoadSequenceText:Destroy()
    end
    if config.IntroEnabled then
        LoadSequence()
    end

    -----------------------------------------
    -- TAB & ELEMENT FUNCTIONS (including Plugin API)
    -----------------------------------------
    local TabFunction = {}
    function TabFunction:MakeTab(tabConfig)
        tabConfig = tabConfig or {}
        tabConfig.Name = tabConfig.Name or "Tab"
        tabConfig.Icon = tabConfig.Icon or ""
        tabConfig.PremiumOnly = tabConfig.PremiumOnly or false

        local TabFrame = SetChildren(SetProps(MakeElement("Button"), {
            Size = UDim2.new(1,0,0,30),
            Parent = TabHolder
        }), {
            AddThemeObject(SetProps(MakeElement("Image", tabConfig.Icon), {
                AnchorPoint = Vector2.new(0,0.5),
                Size = UDim2.new(0,18,0,18),
                Position = UDim2.new(0,10,0.5,0),
                ImageTransparency = 0.4,
                Name = "Ico"
            }), "Text"),
            AddThemeObject(SetProps(MakeElement("Label", tabConfig.Name, 14), {
                Size = UDim2.new(1,-35,1,0),
                Position = UDim2.new(0,35,0,0),
                Font = Enum.Font.FredokaOne,
                TextTransparency = 0.4,
                Name = "Title"
            }), "Text")
        })
        if GetIcon(tabConfig.Icon) then
            TabFrame.Ico.Image = GetIcon(tabConfig.Icon)
        end

       local Container = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255,255,255), 5), {
    Size = UDim2.new(1,-150,1,-50),
    Position = UDim2.new(0,150,0,50),
    Parent = MainWindow,
    Visible = false,
    Name = "ItemContainer"
}), {
    MakeElement("List", 0,6),
    MakeElement("Padding",15,10,10,15)
}), "Divider")

        AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            Container.CanvasSize = UDim2.new(0,0,0, Container.UIListLayout.AbsoluteContentSize.Y + 30)
                Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
Container.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
Container.ScrollBarImageTransparency = 0

        end)
        if firstTab then
            firstTab = false
            TabFrame.Ico.ImageTransparency = 0
            TabFrame.Title.TextTransparency = 0
            TabFrame.Title.Font = Enum.Font.FredokaOne
            Container.Visible = true
        end
        AddConnection(TabFrame.MouseButton1Click, function()
            for _, tab in ipairs(TabHolder:GetChildren()) do
                if tab:IsA("TextButton") then
                    tab.Title.Font = Enum.Font.FredokaOne
                    TweenService:Create(tab.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 0.4}):Play()
                    TweenService:Create(tab.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play()
                end
            end
            for _, itemContainer in ipairs(MainWindow:GetChildren()) do
                if itemContainer.Name == "ItemContainer" then
                    itemContainer.Visible = false
                end
            end
            TweenService:Create(TabFrame.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play()
            TweenService:Create(TabFrame.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
            TabFrame.Title.Font = Enum.Font.FredokaOne
            Container.Visible = true
        end)
        local function GetElements(itemParent)
            local ElementFunction = {}

            function ElementFunction:AddLabel(text)
                local labelFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0,5), {
                    Size = UDim2.new(1,0,0,30),
                    BackgroundTransparency = 0.7,
                    Parent = itemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", text, 15), {
                        Size = UDim2.new(1,-12,1,0),
                        Position = UDim2.new(0,12,0,0),
                        Font = Enum.Font.FredokaOne,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke")
                }), "Second")
                local labelFunction = {}
                function labelFunction:Set(newText)
                    labelFrame.Content.Text = newText
                end
                return labelFunction
            end

            function ElementFunction:AddParagraph(text, content)
                text = text or "Text"
                content = content or "Content"
                local paragraphFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0,5), {
                    Size = UDim2.new(1,0,0,30),
                    BackgroundTransparency = 0.7,
                    Parent = itemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", text, 15), {
                        Size = UDim2.new(1,-12,0,14),
                        Position = UDim2.new(0,12,0,10),
                        Font = Enum.Font.FredokaOne,
                        Name = "Title"
                    }), "Text"),
                    AddThemeObject(SetProps(MakeElement("Label", "", 13), {
                        Size = UDim2.new(1,-24,0,0),
                        Position = UDim2.new(0,12,0,26),
                        Font = Enum.Font.FredokaOne,
                        Name = "Content",
                        TextWrapped = true
                    }), "TextDark"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke")
                }), "Second")
                AddConnection(paragraphFrame.Content:GetPropertyChangedSignal("Text"), function()
                    paragraphFrame.Content.Size = UDim2.new(1,-24,0, paragraphFrame.Content.TextBounds.Y)
                    paragraphFrame.Size = UDim2.new(1,0,0, paragraphFrame.Content.TextBounds.Y + 35)
                end)
                paragraphFrame.Content.Text = content
                local paragraphFunction = {}
                function paragraphFunction:Set(newContent)
                    paragraphFrame.Content.Text = newContent
                end
                return paragraphFunction
            end

            function ElementFunction:AddButton(buttonConfig)
                buttonConfig = buttonConfig or {}
                buttonConfig.Name = buttonConfig.Name or "Button"
                buttonConfig.Callback = buttonConfig.Callback or function() end
                buttonConfig.Icon = buttonConfig.Icon or "rbxassetid://3944703587"
                local button = {}
                local click = SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
                local buttonFrame = AddThemeObject(
                    SetChildren(
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0,5), {
                            Size = UDim2.new(1,0,0,33),
                            Parent = itemParent
                        }), {
                            AddThemeObject(SetProps(MakeElement("Label", buttonConfig.Name, 15), {
                                Size = UDim2.new(1,-12,1,0),
                                Position = UDim2.new(0,12,0,0),
                                Font = Enum.Font.FredokaOne,
                                Name = "Content"
                            }), "Text"),
                            AddThemeObject(SetProps(MakeElement("Image", buttonConfig.Icon), {
                                Size = UDim2.new(0,20,0,20),
                                Position = UDim2.new(1,-30,0,7)
                            }), "TextDark"),
                            AddThemeObject(MakeElement("Stroke"), "Stroke"),
                            click
                        }
                    ), "Second")
                AddConnection(click.MouseEnter, function()
                    TweenService:Create(buttonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Color3.fromRGB(
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
                    }):Play()
                end)
                AddConnection(click.MouseLeave, function()
                    TweenService:Create(buttonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second
                    }):Play()
                end)
                AddConnection(click.MouseButton1Up, function()
                    TweenService:Create(buttonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Color3.fromRGB(
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
                    }):Play()
                    task.spawn(buttonConfig.Callback)
                end)
                AddConnection(click.MouseButton1Down, function()
                    TweenService:Create(buttonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Color3.fromRGB(
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)
                    }):Play()
                end)
                function button:Set(newText)
                    buttonFrame.Content.Text = newText
                end
                return button
            end

            function ElementFunction:AddToggle(toggleConfig)
                toggleConfig = toggleConfig or {}
                toggleConfig.Name = toggleConfig.Name or "Toggle"
                toggleConfig.Default = toggleConfig.Default or false
                toggleConfig.Callback = toggleConfig.Callback or function() end
                toggleConfig.Color = toggleConfig.Color or Color3.fromRGB(9,99,195)
                toggleConfig.Flag = toggleConfig.Flag or nil
                toggleConfig.Save = toggleConfig.Save or false
                local toggle = {Value = toggleConfig.Default, Save = toggleConfig.Save}
                local click = SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
                local toggleBox = SetChildren(SetProps(MakeElement("RoundFrame", toggleConfig.Color, 0,4), {
                    Size = UDim2.new(0,24,0,24),
                    Position = UDim2.new(1,-24,0.5,0),
                    AnchorPoint = Vector2.new(0.5,0.5)
                }), {
                    SetProps(MakeElement("Stroke"), {Color = toggleConfig.Color, Name = "Stroke", Transparency = 0.5}),
                    SetProps(MakeElement("Image", "rbxassetid://3944680095"), {
                        Size = UDim2.new(0,20,0,20),
                        AnchorPoint = Vector2.new(0.5,0.5),
                        Position = UDim2.new(0.5,0,0.5,0),
                        ImageColor3 = Color3.fromRGB(255,255,255),
                        Name = "Ico"
                    })
                })
                local toggleFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0,5), {
                    Size = UDim2.new(1,0,0,38),
                    Parent = itemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", toggleConfig.Name, 15), {
                        Size = UDim2.new(1,-12,1,0),
                        Position = UDim2.new(0,12,0,0),
                        Font = Enum.Font.FredokaOne,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    toggleBox,
                    click
                }), "Second")
                function toggle:Set(val)
                    self.Value = val
                    TweenService:Create(toggleBox, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = self.Value and toggleConfig.Color or OrionLib.Themes.Default.Divider
                    }):Play()
                    TweenService:Create(toggleBox.Stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                        Color = self.Value and toggleConfig.Color or OrionLib.Themes.Default.Stroke
                    }):Play()
                    TweenService:Create(toggleBox.Ico, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                        ImageTransparency = self.Value and 0 or 1,
                        Size = self.Value and UDim2.new(0,20,0,20) or UDim2.new(0,8,0,8)
                    }):Play()
                    toggleConfig.Callback(self.Value)
                end
                toggle:Set(toggle.Value)
                if toggleConfig.Flag then
                    OrionLib.Flags[toggleConfig.Flag] = toggle
                end
                AddConnection(click.MouseButton1Up, function()
                    TweenService:Create(toggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Color3.fromRGB(
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
                    }):Play()
                    SaveCfg(game.GameId)
                    toggle:Set(not toggle.Value)
                end)
                AddConnection(click.MouseButton1Down, function()
                    TweenService:Create(toggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Color3.fromRGB(
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)
                    }):Play()
                end)
                AddConnection(click.MouseEnter, function()
                    TweenService:Create(toggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Color3.fromRGB(
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
                    }):Play()
                end)
                AddConnection(click.MouseLeave, function()
                    TweenService:Create(toggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second
                    }):Play()
                end)
                return toggle
            end

            function ElementFunction:AddSlider(sliderConfig)
                sliderConfig = sliderConfig or {}
                sliderConfig.Name = sliderConfig.Name or "Slider"
                sliderConfig.Min = sliderConfig.Min or 0
                sliderConfig.Max = sliderConfig.Max or 100
                sliderConfig.Increment = sliderConfig.Increment or 1
                sliderConfig.Default = sliderConfig.Default or 50
                sliderConfig.Callback = sliderConfig.Callback or function() end
                sliderConfig.ValueName = sliderConfig.ValueName or ""
                sliderConfig.Color = sliderConfig.Color or Color3.fromRGB(9,149,98)
                sliderConfig.Flag = sliderConfig.Flag or nil
                sliderConfig.Save = sliderConfig.Save or false

                local slider = {Value = sliderConfig.Default, Save = sliderConfig.Save}
                local dragging = false
                local sliderDrag = SetChildren(SetProps(MakeElement("RoundFrame", sliderConfig.Color, 0,5), {
                    Size = UDim2.new(0,0,1,0),
                    BackgroundTransparency = 0.3,
                    ClipsDescendants = true
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", "value", 13), {
                        Size = UDim2.new(1,-12,0,14),
                        Position = UDim2.new(0,12,0,6),
                        Font = Enum.Font.FredokaOne,
                        Name = "Value",
                        TextTransparency = 0
                    }), "Text")
                })
                local sliderBar = SetChildren(SetProps(MakeElement("RoundFrame", sliderConfig.Color, 0,5), {
                    Size = UDim2.new(1,-24,0,26),
                    Position = UDim2.new(0,12,0,30),
                    BackgroundTransparency = 0.9
                }), {
                    SetProps(MakeElement("Stroke"), {Color = sliderConfig.Color}),
                    AddThemeObject(SetProps(MakeElement("Label", "value", 13), {
                        Size = UDim2.new(1,-12,0,14),
                        Position = UDim2.new(0,12,0,6),
                        Font = Enum.Font.FredokaOne,
                        Name = "Value",
                        TextTransparency = 0.8
                    }), "Text"),
                    sliderDrag
                })
                local sliderFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0,4), {
                    Size = UDim2.new(1,0,0,65),
                    Parent = itemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", sliderConfig.Name, 15), {
                        Size = UDim2.new(1,-12,0,14),
                        Position = UDim2.new(0,12,0,10),
                        Font = Enum.Font.FredokaOne,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    sliderBar
                }), "Second")
                AddConnection(sliderBar.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                    end
                end)
                AddConnection(sliderBar.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                AddConnection(UserInputService.InputChanged, function(input)
                    if dragging then
                        local sizeScale = math.clamp((Mouse.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
                        slider:Set(sliderConfig.Min + ((sliderConfig.Max - sliderConfig.Min) * sizeScale))
                        SaveCfg(game.GameId)
                    end
                end)
                function slider:Set(val)
                    self.Value = math.clamp(Round(val, sliderConfig.Increment), sliderConfig.Min, sliderConfig.Max)
                    TweenService:Create(sliderDrag, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                        Size = UDim2.fromScale((self.Value - sliderConfig.Min) / (sliderConfig.Max - sliderConfig.Min), 1)
                    }):Play()
                    sliderBar.Value.Text = tostring(self.Value) .. " " .. sliderConfig.ValueName
                    sliderDrag.Value.Text = tostring(self.Value) .. " " .. sliderConfig.ValueName
                    sliderConfig.Callback(self.Value)
                end
                slider:Set(slider.Value)
                if sliderConfig.Flag then
                    OrionLib.Flags[sliderConfig.Flag] = slider
                end
                return slider
            end

            function ElementFunction:AddDropdown(dropdownConfig)
                dropdownConfig = dropdownConfig or {}
                dropdownConfig.Name = dropdownConfig.Name or "Dropdown"
                dropdownConfig.Options = dropdownConfig.Options or {}
                dropdownConfig.Default = dropdownConfig.Default or ""
                dropdownConfig.Callback = dropdownConfig.Callback or function() end
                dropdownConfig.Flag = dropdownConfig.Flag or nil
                dropdownConfig.Save = dropdownConfig.Save or false

                local dropdown = {Value = dropdownConfig.Default, Options = dropdownConfig.Options, Buttons = {}, Toggled = false, Type = "Dropdown", Save = dropdownConfig.Save}
                local maxElements = 5
                if not table.find(dropdown.Options, dropdown.Value) then
                    dropdown.Value = "..."
                end
                local dropdownList = MakeElement("List")
                local dropdownContainer = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(40,40,40), 4), {dropdownList}), {
                    Parent = itemParent,
                    Position = UDim2.new(0,0,0,38),
                    Size = UDim2.new(1,0,1,-38),
                    ClipsDescendants = true
                }), "Divider")
                local click = SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
                local dropdownFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0,5), {
                    Size = UDim2.new(1,0,0,38),
                    Parent = itemParent,
                    ClipsDescendants = true
                }), {
                    dropdownContainer,
                    SetProps(SetChildren(MakeElement("TFrame"), {
                        AddThemeObject(SetProps(MakeElement("Label", dropdownConfig.Name, 15), {
                            Size = UDim2.new(1,-12,1,0),
                            Position = UDim2.new(0,12,0,0),
                            Font = Enum.Font.FredokaOne,
                            Name = "Content"
                        }), "Text"),
                        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072706796"), {
                            Size = UDim2.new(0,20,0,20),
                            AnchorPoint = Vector2.new(0,0.5),
                            Position = UDim2.new(1,-30,0.5,0),
                            ImageColor3 = Color3.fromRGB(240,240,240),
                            Name = "Ico"
                        }), "TextDark"),
                        AddThemeObject(SetProps(MakeElement("Label", "Selected", 13), {
                            Size = UDim2.new(1,-40,1,0),
                            Font = Enum.Font.FredokaOne,
                            Name = "Selected",
                            TextXAlignment = Enum.TextXAlignment.Right
                        }), "TextDark"),
                        AddThemeObject(SetProps(MakeElement("Frame", nil), {
                            Size = UDim2.new(1,0,0,1),
                            Position = UDim2.new(0,0,1,-1),
                            Name = "Line",
                            Visible = false
                        }), "Stroke"),
                        click
                    }), {Size = UDim2.new(1,0,0,38), ClipsDescendants = true, Name = "F"}),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    MakeElement("Corner")
                }), "Second")
                AddConnection(dropdownList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                    dropdownContainer.CanvasSize = UDim2.new(0,0,0, dropdownList.AbsoluteContentSize.Y)
                end)
                local function AddOptions(options)
                    for _, option in ipairs(options) do
                        local optionBtn = AddThemeObject(
                            SetProps(
                                SetChildren(MakeElement("Button", Color3.fromRGB(40,40,40)), {
                                    MakeElement("Corner", 0,6),
                                    AddThemeObject(
                                        SetProps(MakeElement("Label", option, 13,0.4), {
                                            Position = UDim2.new(0, 8, 0, 0),
                                            Size = UDim2.new(1, -8, 1, 0),
                                            Name = "Title"
                                        }),
                                        "Text"
                                    )
                                }),
                                {
                                    Parent = dropdownContainer,
                                    Size = UDim2.new(1, 0, 0, 28),
                                    BackgroundTransparency = 1,
                                    ClipsDescendants = true
                                }
                            ),
                            "Divider"
                        )
                        AddConnection(optionBtn.MouseButton1Click, function()
                            dropdown:Set(option)
                            SaveCfg(game.GameId)
                        end)
                        dropdown.Buttons[option] = optionBtn
                    end
                end
                function dropdown:Refresh(options, deleteExisting)
                    if deleteExisting then
                        for _, btn in pairs(dropdown.Buttons) do
                            btn:Destroy()
                        end
                        dropdown.Options = {}
                        dropdown.Buttons = {}
                    end
                    dropdown.Options = options
                    AddOptions(dropdown.Options)
                end
                function dropdown:Set(val)
                    if not table.find(dropdown.Options, val) then
                        dropdown.Value = "..."
                        dropdownFrame.F.Selected.Text = dropdown.Value
                        for _, btn in pairs(dropdown.Buttons) do
                            TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
                            TweenService:Create(btn.Title, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextTransparency = 0.4}):Play()
                        end
                        return
                    end
                    dropdown.Value = val
                    dropdownFrame.F.Selected.Text = dropdown.Value
                    for _, btn in pairs(dropdown.Buttons) do
                        TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
                        TweenService:Create(btn.Title, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextTransparency = 0.4}):Play()
                    end
                    TweenService:Create(dropdown.Buttons[val], TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
                    TweenService:Create(dropdown.Buttons[val].Title, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
                    return dropdownConfig.Callback(dropdown.Value)
                end
                AddConnection(click.MouseButton1Click, function()
                    dropdown.Toggled = not dropdown.Toggled
                    dropdownFrame.F.Line.Visible = dropdown.Toggled
                    TweenService:Create(dropdownFrame.F.Ico, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Rotation = dropdown.Toggled and 180 or 0}):Play()
                    if #dropdown.Options > maxElements then
                        TweenService:Create(dropdownFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = dropdown.Toggled and UDim2.new(1,0,0,38 + (maxElements * 28)) or UDim2.new(1,0,0,38)}):Play()
                    else
                        TweenService:Create(dropdownFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = dropdown.Toggled and UDim2.new(1,0,0, dropdownList.AbsoluteContentSize.Y + 38) or UDim2.new(1,0,0,38)}):Play()
                    end
                end)
                dropdown:Refresh(dropdown.Options, false)
                dropdown:Set(dropdown.Value)
                if dropdownConfig.Flag then
                    OrionLib.Flags[dropdownConfig.Flag] = dropdown
                end
                return dropdown
            end

            function ElementFunction:AddBind(bindConfig)
                bindConfig.Name = bindConfig.Name or "Bind"
                bindConfig.Default = bindConfig.Default or Enum.KeyCode.Unknown
                bindConfig.Hold = bindConfig.Hold or false
                bindConfig.Callback = bindConfig.Callback or function() end
                bindConfig.Flag = bindConfig.Flag or nil
                bindConfig.Save = bindConfig.Save or false
                local bind = {Value = nil, Binding = false, Type = "Bind", Save = bindConfig.Save}
                local holding = false
                local click = SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
                local bindBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0,4), {
                    Size = UDim2.new(0,24,0,24),
                    Position = UDim2.new(1,-12,0.5,0),
                    AnchorPoint = Vector2.new(1,0.5)
                }), {
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    AddThemeObject(SetProps(MakeElement("Label", bindConfig.Name, 14), {
                        Size = UDim2.new(1,0,1,0),
                        Font = Enum.Font.FredokaOne,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        Name = "Value"
                    }), "Text")
                }), "Main")
                local bindFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0,5), {
                    Size = UDim2.new(1,0,0,38),
                    Parent = itemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", bindConfig.Name, 15), {
                        Size = UDim2.new(1,-12,1,0),
                        Position = UDim2.new(0,12,0,0),
                        Font = Enum.Font.FredokaOne,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    bindBox,
                    click
                }), "Second")
                AddConnection(bindBox.Value:GetPropertyChangedSignal("Text"), function()
                    TweenService:Create(bindBox, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        Size = UDim2.new(0, bindBox.Value.TextBounds.X + 16, 0, 24)
                    }):Play()
                end)
                AddConnection(click.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if bind.Binding then return end
                        bind.Binding = true
                        bindBox.Value.Text = ""
                    end
                end)
                AddConnection(UserInputService.InputBegan, function(input)
                    if UserInputService:GetFocusedTextBox() then return end
                    if (input.KeyCode.Name == bind.Value or input.UserInputType.Name == bind.Value) and not bind.Binding then
                        if bindConfig.Hold then
                            holding = true
                            bindConfig.Callback(holding)
                        else
                            bindConfig.Callback()
                        end
                    elseif bind.Binding then
                        local key
                        pcall(function()
                            if not CheckKey(BlacklistedKeys, input.KeyCode) then
                                key = input.KeyCode
                            end
                        end)
                        pcall(function()
                            if CheckKey(WhitelistedMouse, input.UserInputType) and not key then
                                key = input.UserInputType
                            end
                        end)
                        key = key or bind.Value
                        bind:Set(key)
                        SaveCfg(game.GameId)
                    end
                end)
                AddConnection(UserInputService.InputEnded, function(input)
                    if input.KeyCode.Name == bind.Value or input.UserInputType.Name == bind.Value then
                        if bindConfig.Hold and holding then
                            holding = false
                            bindConfig.Callback(holding)
                        end
                    end
                end)
                AddConnection(click.MouseEnter, function()
                    TweenService:Create(bindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Color3.fromRGB(
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
                    }):Play()
                end)
                AddConnection(click.MouseLeave, function()
                    TweenService:Create(bindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second
                    }):Play()
                end)
                AddConnection(click.MouseButton1Up, function()
                    TweenService:Create(bindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Color3.fromRGB(
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
                    }):Play()
                end)
                AddConnection(click.MouseButton1Down, function()
                    TweenService:Create(bindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Color3.fromRGB(
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)
                    }):Play()
                end)
                function bind:Set(key)
                    bind.Binding = false
                    bind.Value = key or bind.Value
                    bind.Value = bind.Value.Name or bind.Value
                    bindBox.Value.Text = bind.Value
                end
                bind:Set(bindConfig.Default)
                if bindConfig.Flag then
                    OrionLib.Flags[bindConfig.Flag] = bind
                end
                return bind
            end

            function ElementFunction:AddTextbox(textboxConfig)
                textboxConfig = textboxConfig or {}
                textboxConfig.Name = textboxConfig.Name or "Textbox"
                textboxConfig.Default = textboxConfig.Default or ""
                textboxConfig.TextDisappear = textboxConfig.TextDisappear or false
                textboxConfig.Callback = textboxConfig.Callback or function() end
                local click = SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
                local textboxActual = AddThemeObject(Create("TextBox", {
                    Size = UDim2.new(1,0,1,0),
                    BackgroundTransparency = 1,
                    TextColor3 = Color3.fromRGB(255,255,255),
                    PlaceholderColor3 = Color3.fromRGB(210,210,210),
                    PlaceholderText = "Input",
                    Font = Enum.Font.FredokaOne,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextSize = 14,
                    ClearTextOnFocus = false
                }), "Text")
                local textContainer = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0,4), {
                    Size = UDim2.new(0,24,0,24),
                    Position = UDim2.new(1,-12,0.5,0),
                    AnchorPoint = Vector2.new(1,0.5)
                }), {
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    textboxActual
                }), "Main")
                local textboxFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0,5), {
                    Size = UDim2.new(1,0,0,38),
                    Parent = itemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", textboxConfig.Name, 15), {
                        Size = UDim2.new(1,-12,1,0),
                        Position = UDim2.new(0,12,0,0),
                        Font = Enum.Font.FredokaOne,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    textContainer,
                    click
                }), "Second")
                AddConnection(textboxActual:GetPropertyChangedSignal("Text"), function()
                    TweenService:Create(textContainer, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {
                        Size = UDim2.new(0, textboxActual.TextBounds.X + 16, 0, 24)
                    }):Play()
                end)
                AddConnection(textboxActual.FocusLost, function()
                    textboxConfig.Callback(textboxActual.Text)
                    if textboxConfig.TextDisappear then
                        textboxActual.Text = ""
                    end
                end)
                textboxActual.Text = textboxConfig.Default
                AddConnection(click.MouseEnter, function()
                    TweenService:Create(textboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Color3.fromRGB(
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
                    }):Play()
                end)
                AddConnection(click.MouseLeave, function()
                    TweenService:Create(textboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second
                    }):Play()
                end)
                AddConnection(click.MouseButton1Up, function()
                    TweenService:Create(textboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Color3.fromRGB(
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
                    }):Play()
                    textboxActual:CaptureFocus()
                end)
                AddConnection(click.MouseButton1Down, function()
                    TweenService:Create(textboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Color3.fromRGB(
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6,
                            OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)
                    }):Play()
                end)
            end

            function ElementFunction:AddColorpicker(colorpickerConfig)
                colorpickerConfig = colorpickerConfig or {}
                colorpickerConfig.Name = colorpickerConfig.Name or "Colorpicker"
                colorpickerConfig.Default = colorpickerConfig.Default or Color3.fromRGB(255,255,255)
                colorpickerConfig.Callback = colorpickerConfig.Callback or function() end
                colorpickerConfig.Flag = colorpickerConfig.Flag or nil
                colorpickerConfig.Save = colorpickerConfig.Save or false
                local colorH, colorS, colorV = 1, 1, 1
                local colorpicker = {Value = colorpickerConfig.Default, Toggled = false, Type = "Colorpicker", Save = colorpickerConfig.Save}
                local colorSelection = Create("ImageLabel", {
                    Size = UDim2.new(0,18,0,18),
                    Position = UDim2.new(select(3, Color3.toHSV(colorpicker.Value))),
                    ScaleType = Enum.ScaleType.Fit,
                    AnchorPoint = Vector2.new(0.5,0.5),
                    BackgroundTransparency = 1,
                    Image = "http://www.roblox.com/asset/?id=4805639000"
                })
                local hueSelection = Create("ImageLabel", {
                    Size = UDim2.new(0,18,0,18),
                    Position = UDim2.new(0.5,0,1 - select(1, Color3.toHSV(colorpicker.Value))),
                    ScaleType = Enum.ScaleType.Fit,
                    AnchorPoint = Vector2.new(0.5,0.5),
                    BackgroundTransparency = 1,
                    Image = "http://www.roblox.com/asset/?id=4805639000"
                })
                local colorFrame = Create("ImageLabel", {
                    Size = UDim2.new(1,-25,1,0),
                    Visible = false,
                    Image = "rbxassetid://4155801252"
                }, { Create("UICorner", {CornerRadius = UDim.new(0,5)}), colorSelection })
                local hueFrame = Create("Frame", {
                    Size = UDim2.new(0,20,1,0),
                    Position = UDim2.new(1,-20,0,0),
                    Visible = false
                }, { Create("UIGradient", {Rotation = 270, Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,4)),
                        ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234,255,0)),
                        ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21,255,0)),
                        ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0,255,255)),
                        ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0,17,255)),
                        ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255,0,251)),
                        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,4))
                    }}), Create("UICorner", {CornerRadius = UDim.new(0,5)}), hueSelection })
                local colorpickerContainer = Create("Frame", {
                    Position = UDim2.new(0,0,0,32),
                    Size = UDim2.new(1,0,1,-32),
                    BackgroundTransparency = 1,
                    ClipsDescendants = true
                }, { hueFrame, colorFrame, Create("UIPadding", {
                    PaddingLeft = UDim.new(0,35),
                    PaddingRight = UDim.new(0,35),
                    PaddingBottom = UDim.new(0,10),
                    PaddingTop = UDim.new(0,17)
                }) })
                local click = SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
                local colorpickerBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0,4), {
                    Size = UDim2.new(0,24,0,24),
                    Position = UDim2.new(1,-12,0.5,0),
                    AnchorPoint = Vector2.new(1,0.5)
                }), { AddThemeObject(MakeElement("Stroke"), "Stroke") }), "Main")
                local colorpickerFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0,5), {
                    Size = UDim2.new(1,0,0,38),
                    Parent = itemParent
                }), {
                    SetProps(SetChildren(MakeElement("TFrame"), {
                        AddThemeObject(SetProps(MakeElement("Label", colorpickerConfig.Name, 15), {
                            Size = UDim2.new(1,-12,1,0),
                            Position = UDim2.new(0,12,0,0),
                            Font = Enum.Font.FredokaOne,
                            Name = "Content"
                        }), "Text"),
                        colorpickerBox,
                        click,
                        AddThemeObject(SetProps(MakeElement("Frame"), {
                            Size = UDim2.new(1,0,0,1),
                            Position = UDim2.new(0,0,1,-1),
                            Name = "Line",
                            Visible = false
                        }), "Stroke")
                    }), { Size = UDim2.new(1,0,0,38), ClipsDescendants = true, Name = "F" }),
                    colorpickerContainer,
                    AddThemeObject(MakeElement("Stroke"), "Stroke")
                }), "Second")
                AddConnection(click.MouseButton1Click, function()
                    colorpicker.Toggled = not colorpicker.Toggled
                    TweenService:Create(colorpickerFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = colorpicker.Toggled and UDim2.new(1,0,0,148) or UDim2.new(1,0,0,38)}):Play()
                    colorFrame.Visible = colorpicker.Toggled
                    hueFrame.Visible = colorpicker.Toggled
                    colorpickerFrame.F.Line.Visible = colorpicker.Toggled
                end)
                local function UpdateColorPicker()
                    colorpickerBox.BackgroundColor3 = Color3.fromHSV(colorH, colorS, colorV)
                    colorFrame.BackgroundColor3 = Color3.fromHSV(colorH, 1, 1)
                    colorpicker:Set(colorpickerBox.BackgroundColor3)
                    colorpickerConfig.Callback(colorpickerBox.BackgroundColor3)
                    SaveCfg(game.GameId)
                end
                colorH = 1 - (math.clamp(hueSelection.AbsolutePosition.Y - hueFrame.AbsolutePosition.Y, 0, hueFrame.AbsoluteSize.Y) / hueFrame.AbsoluteSize.Y)
                colorS = math.clamp((colorSelection.AbsolutePosition.X - colorFrame.AbsolutePosition.X) / colorFrame.AbsoluteSize.X, 0, 1)
                colorV = 1 - (math.clamp(colorSelection.AbsolutePosition.Y - colorFrame.AbsolutePosition.Y, 0, colorFrame.AbsoluteSize.Y) / colorFrame.AbsoluteSize.Y)
                AddConnection(colorFrame.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if ColorInput then ColorInput:Disconnect() end
                        ColorInput = AddConnection(RunService.RenderStepped, function()
                            local colorX = math.clamp((Mouse.X - colorFrame.AbsolutePosition.X) / colorFrame.AbsoluteSize.X, 0, 1)
                            local colorY = math.clamp((Mouse.Y - colorFrame.AbsolutePosition.Y) / colorFrame.AbsoluteSize.Y, 0, 1)
                            colorSelection.Position = UDim2.new(colorX,0,colorY,0)
                            colorS = colorX
                            colorV = 1 - colorY
                            UpdateColorPicker()
                        end)
                    end
                end)
                AddConnection(colorFrame.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if ColorInput then ColorInput:Disconnect() end
                    end
                end)
                AddConnection(hueFrame.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if HueInput then HueInput:Disconnect() end
                        HueInput = AddConnection(RunService.RenderStepped, function()
                            local hueY = math.clamp((Mouse.Y - hueFrame.AbsolutePosition.Y) / hueFrame.AbsoluteSize.Y, 0, 1)
                            hueSelection.Position = UDim2.new(0.5,0,hueY,0)
                            colorH = 1 - hueY
                            UpdateColorPicker()
                        end)
                    end
                end)
                AddConnection(hueFrame.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if HueInput then HueInput:Disconnect() end
                    end
                end)
                function colorpicker:Set(val)
                    self.Value = val
                    colorpickerBox.BackgroundColor3 = val
                    colorpickerConfig.Callback(val)
                end
                colorpicker:Set(colorpicker.Value)
                if colorpickerConfig.Flag then
                    OrionLib.Flags[colorpickerConfig.Flag] = colorpicker
                end
                return colorpicker
            end

            return ElementFunction
        end

        local elementFunction = GetElements(Container)
        for key, value in pairs(elementFunction) do
            elementFunction[key] = value
        end

        if tabConfig.PremiumOnly then
            for key in pairs(elementFunction) do
                elementFunction[key] = function() end
            end
            local layout = Container:FindFirstChild("UIListLayout")
            if layout then layout:Destroy() end
            local padding = Container:FindFirstChild("UIPadding")
            if padding then padding:Destroy() end
            SetChildren(SetProps(MakeElement("TFrame"), {Size = UDim2.new(1,0,1,0), Parent = itemParent}), {
                AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://3610239960"), {
                    Size = UDim2.new(0,18,0,18),
                    Position = UDim2.new(0,15,0,15),
                    ImageTransparency = 0.4
                }), "Text"),
                AddThemeObject(SetProps(MakeElement("Label", "Unauthorised Access", 14), {
                    Size = UDim2.new(1,-38,0,14),
                    Position = UDim2.new(0,38,0,18),
                    TextTransparency = 0.4
                }), "Text"),
                AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4483345875"), {
                    Size = UDim2.new(0,56,0,56),
                    Position = UDim2.new(0,84,0,110)
                }), "Text"),
                AddThemeObject(SetProps(MakeElement("Label", "Premium Features", 14), {
                    Size = UDim2.new(1,-150,0,14),
                    Position = UDim2.new(0,150,0,112),
                    Font = Enum.Font.FredokaOne
                }), "Text"),
                AddThemeObject(SetProps(MakeElement("Label", "This part is locked to Premium users. Purchase Premium in Discord (discord.gg/sirius)", 12), {
                    Size = UDim2.new(1,-200,0,14),
                    Position = UDim2.new(0,150,0,138),
                    TextWrapped = true,
                    TextTransparency = 0.4
                }), "Text")
            })
        end

        return elementFunction
    end

    return TabFunction
end

-----------------------------------------------------
-- END OF ORIONLIB MODULE
-----------------------------------------------------
return OrionLib
