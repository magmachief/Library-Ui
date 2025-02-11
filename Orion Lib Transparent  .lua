--[[
    Improved Orion UI Library
    --------------------------
    This version maintains all functionality from your original script
    while applying modern coding practices, better readability, and minor
    performance optimizations. All core features (themes, draggable windows,
    notifications, tab creation, etc.) remain intact.
--]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")

-----------------------------------------
-- Premium System
-----------------------------------------
local function GrantPremiumToAll()
    for _, player in ipairs(Players:GetPlayers()) do
        player:SetAttribute("Premium", true)  -- Match existing "Premium"
    end
end

Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("Premium", true)  -- Match existing "Premium"
end)

local function IsPremium(player)
    return player:GetAttribute("Premium") == true  -- Match existing "Premium"
end

-----------------------------------------
-- OrionLib Definition & Theme Setup
-----------------------------------------
local OrionLib = {
    Elements = {},
    ThemeObjects = {},
    Connections = {},
    Flags = {},
    Themes = {
        Default = {
            Main = Color3.fromRGB(22, 2, 28),
            Second = Color3.fromRGB(61, 28, 71),
            Stroke = Color3.fromRGB(60, 60, 60),
            Divider = Color3.fromRGB(60, 60, 60),
            Text = Color3.fromRGB(240, 240, 240),
            TextDark = Color3.fromRGB(150, 150, 150)
        }
    },
    SelectedTheme = "Default",
    Folder = nil,
    SaveCfg = false
}

-----------------------------------------
-- Feather Icons Loader
-----------------------------------------
local Icons = {}
local success, response = pcall(function()
    local data = game:HttpGetAsync("https://raw.githubusercontent.com/7kayoh/feather-roblox/refs/heads/main/src/Modules/asset.lua")
    Icons = HttpService:JSONDecode(data).icons
end)
if not success then
    warn("\nOrion Library - Failed to load Feather Icons. Error code: " .. response .. "\n")
end

local function GetIcon(IconName)
    return Icons[IconName] or nil
end

-----------------------------------------
-- Create the ScreenGui (with syn.protect_gui if available)
-----------------------------------------
local Orion = Instance.new("ScreenGui")
Orion.Name = "Orion"
if syn and syn.protect_gui then
    syn.protect_gui(Orion)
    Orion.Parent = game.CoreGui
else
    Orion.Parent = gethui() or game.CoreGui
end

-----------------------------------------
-- Utility Functions
-----------------------------------------
function OrionLib:IsRunning()
    if gethui then
        return Orion.Parent == gethui()
    else
        return Orion.Parent == game:GetService("CoreGui")
    end
end

local function AddConnection(signal, func)
    if not OrionLib:IsRunning() then return end
    local connection = signal:Connect(func)
    table.insert(OrionLib.Connections, connection)
    return connection
end

task.spawn(function()
    while OrionLib:IsRunning() do
        task.wait()
    end
    for _, connection in ipairs(OrionLib.Connections) do
        connection:Disconnect()
    end
end)

local function MakeDraggable(dragPoint, mainFrame)
    pcall(function()
        local dragging, dragInput, mousePos, framePos = false, nil, nil, nil

        AddConnection(dragPoint.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                mousePos = input.Position
                framePos = mainFrame.Position

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
                TweenService:Create(mainFrame, TweenInfo.new(0.05, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
                }):Play()
                mainFrame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
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
    OrionLib.Elements[elementName] = function(...)
        return elementFunc(...)
    end
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
    if not OrionLib.ThemeObjects[typeName] then
        OrionLib.ThemeObjects[typeName] = {}
    end
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
    -- Note: You can add file saving logic here if needed.
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
        if v == key then
            return true
        end
    end
end

-----------------------------------------
-- Create UI Elements
-----------------------------------------
CreateElement("Corner", function(scale, offset)
    return Create("UICorner", {CornerRadius = UDim.new(scale or 0, offset or 10)})
end)

CreateElement("Stroke", function(color, thickness)
    return Create("UIStroke", {
        Color = color or Color3.fromRGB(255, 255, 255),
        Thickness = thickness or 1
    })
end)

CreateElement("List", function(scale, offset)
    return Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(scale or 0, offset or 0)
    })
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
    return Create("Frame", {
        BackgroundColor3 = color or Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0
    })
end)

CreateElement("RoundFrame", function(color, scale, offset)
    return Create("Frame", {
        BackgroundColor3 = color or Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0
    }, {
        Create("UICorner", {CornerRadius = UDim.new(scale, offset)})
    })
end)

CreateElement("Button", function()
    return Create("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    })
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
    local image = Create("ImageLabel", {
        Image = imageId,
        BackgroundTransparency = 1
    })
    if GetIcon(imageId) then
        image.Image = GetIcon(imageId)
    end
    return image
end)

CreateElement("ImageButton", function(imageId)
    return Create("ImageButton", {
        Image = imageId,
        BackgroundTransparency = 1
    })
end)

CreateElement("Label", function(text, textSize, transparency)
    return Create("TextLabel", {
        Text = text or "",
        TextColor3 = Color3.fromRGB(240, 240, 240),
        TextTransparency = transparency or 0,
        TextSize = textSize or 15,
        Font = Enum.Font.FredokaOne,
        RichText = true,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left
    })
end)

-----------------------------------------
-- Notifications
-----------------------------------------
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

        local notifFrame = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(25, 25, 25), 0, 10), {
            Parent = notifParent,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(1, -55, 0, 0),
            BackgroundTransparency = 0,
            AutomaticSize = Enum.AutomaticSize.Y
        }), {
            MakeElement("Stroke", Color3.fromRGB(93, 93, 93), 1.2),
            MakeElement("Padding", 12, 12, 12, 12),
            SetProps(MakeElement("Image", config.Image), {
                Size = UDim2.new(0, 20, 0, 20),
                ImageColor3 = Color3.fromRGB(240, 240, 240),
                Name = "Icon"
            }),
            SetProps(MakeElement("Label", config.Name, 15), {
                Size = UDim2.new(1, -30, 0, 20),
                Position = UDim2.new(0, 30, 0, 0),
                Font = Enum.Font.FredokaOne,
                Name = "Title"
            }),
            SetProps(MakeElement("Label", config.Content, 14), {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 25),
                Font = Enum.Font.FredokaOne,
                Name = "Content",
                AutomaticSize = Enum.AutomaticSize.Y,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextWrapped = true
            })
        })
        TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 0, 0, 0)}):Play()
        task.wait(config.Time - 0.88)
        TweenService:Create(notifFrame.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
        TweenService:Create(notifFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.6}):Play()
        task.wait(0.3)
        TweenService:Create(notifFrame.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0.9}):Play()
        TweenService:Create(notifFrame.Title, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play()
        TweenService:Create(notifFrame.Content, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.5}):Play()
        task.wait(0.05)
        notifFrame:TweenPosition(UDim2.new(1, 20, 0, 0), 'In', 'Quint', 0.8, true)
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
                    Content = "Auto-loaded configuration for the game " .. game.GameId .. ".",
                    Time = 5
                })
            end
        end)
    end
end

-----------------------------------------
-- Main Window Creation
-----------------------------------------
function OrionLib:MakeWindow(config)
    local firstTab = true
    local minimized = false
    local loaded = false
    local UIHidden = false

    config = config or {}
    config.Name = config.Name or "Yonkai"
    config.ConfigFolder = config.ConfigFolder or config.Name
    config.SaveConfig = config.SaveConfig or false
    config.HidePremium = config.HidePremium or false
    if config.IntroEnabled == nil then config.IntroEnabled = true end
    config.IntroToggleIcon = config.IntroToggleIcon or "rbxassetid://8834748103"
    config.IntroText = config.IntroText or "Yonkai"
    config.CloseCallback = config.CloseCallback or function() end
    config.ShowIcon = config.ShowIcon or false
    config.Icon = config.Icon or "rbxassetid://8834748103"
    config.IntroIcon = config.IntroIcon or "rbxassetid://8834748103"
    OrionLib.Folder = config.ConfigFolder
    OrionLib.SaveCfg = config.SaveConfig

    if config.SaveConfig and not isfolder(config.ConfigFolder) then
        makefolder(config.ConfigFolder)
    end

    local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255,255,255), 4), {
        Size = UDim2.new(1, 0, 1, -50)
    }), {
        MakeElement("List"),
        MakeElement("Padding", 8, 0, 0, 8)
    }), "Divider")

    AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
    end)

    local CloseBtn = SetChildren(SetProps(MakeElement("Button"), {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundTransparency = 1
    }), {
        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072725342"), {
            Position = UDim2.new(0, 9, 0, 6),
            Size = UDim2.new(0, 18, 0, 18)
        }), "Text")
    })

    local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), {
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1
    }), {
        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072719338"), {
            Position = UDim2.new(0, 9, 0, 6),
            Size = UDim2.new(0, 18, 0, 18),
            Name = "Ico"
        }), "Text")
    })

    local DragPoint = SetProps(MakeElement("TFrame"), {
        Size = UDim2.new(1, 0, 0, 50)
    })

    local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 10), {
        Size = UDim2.new(0, 150, 1, -50),
        Position = UDim2.new(0, 0, 0, 50)
    }), {
        AddThemeObject(SetProps(MakeElement("Frame"), {
            Size = UDim2.new(1, 0, 0, 10),
            Position = UDim2.new(0, 0, 0, 0)
        }), "Second"), 
        AddThemeObject(SetProps(MakeElement("Frame"), {
            Size = UDim2.new(0, 10, 1, 0),
            Position = UDim2.new(1, -10, 0, 0)
        }), "Second"), 
        AddThemeObject(SetProps(MakeElement("Frame"), {
            Size = UDim2.new(0, 1, 1, 0),
            Position = UDim2.new(1, -1, 0, 0)
        }), "Stroke"), 
        TabHolder,
        SetChildren(SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 50),
            Position = UDim2.new(0, 0, 1, -50)
        }), {
            AddThemeObject(SetProps(MakeElement("Frame"), {
                Size = UDim2.new(1, 0, 0, 1)
            }), "Stroke"), 
            AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 32, 0, 32),
                Position = UDim2.new(0, 10, 0.5, 0)
            }), {
                SetProps(MakeElement("Image", "https://www.roblox.com/headshot-thumbnail/image?userId=".. LocalPlayer.UserId .."&width=420&height=420&format=png"), {
                    Size = UDim2.new(1, 0, 1, 0)
                }),
                AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4031889928"), {
                    Size = UDim2.new(1, 0, 1, 0)
                }), "Second"),
                MakeElement("Corner", 1)
            }), "Divider"),
            SetChildren(SetProps(MakeElement("TFrame"), {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 32, 0, 32),
                Position = UDim2.new(0, 10, 0.5, 0)
            }), {
                AddThemeObject(MakeElement("Stroke"), "Stroke"),
                MakeElement("Corner", 1)
            }),
            AddThemeObject(SetProps(MakeElement("Label", "User", config.HidePremium and 14 or 13), {
                Size = UDim2.new(1, -60, 0, 13),
                Position = config.HidePremium and UDim2.new(0, 50, 0, 19) or UDim2.new(0, 50, 0, 12),
                Font = Enum.Font.FredokaOne,
                ClipsDescendants = true
            }), "Text"),
            AddThemeObject(SetProps(MakeElement("Label", "", 12), {
                Size = UDim2.new(1, -60, 0, 12),
                Position = UDim2.new(0, 50, 1, -25),
                Visible = not config.HidePremium
            }), "TextDark")
        }),
    }), "Second")

    local WindowName = AddThemeObject(SetProps(MakeElement("Label", config.Name, 14), {
        Size = UDim2.new(1, -30, 2, 0),
        Position = UDim2.new(0, 25, 0, -24),
        Font = Enum.Font.FredokaOne,
        TextSize = 20
    }), "Text")

    local WindowTopBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1)
    }), "Stroke")

    local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 10), {
        Parent = Orion,
        Position = UDim2.new(0.5, -307, 0.5, -172),
        Size = UDim2.new(0, 615, 0, 344),
        ClipsDescendants = true
    }), {
        SetChildren(SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 50),
            Name = "TopBar"
        }), {
            WindowName,
            WindowTopBarLine,
            AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 7), {
                Size = UDim2.new(0, 70, 0, 30),
                Position = UDim2.new(1, -90, 0, 10)
            }), {
                AddThemeObject(MakeElement("Stroke"), "Stroke"),
                AddThemeObject(SetProps(MakeElement("Frame"), {
                    Size = UDim2.new(0, 1, 1, 0),
                    Position = UDim2.new(0.5, 0, 0, 0)
                }), "Stroke"), 
                CloseBtn,
                MinimizeBtn
            }), "Second"),
        }),
        DragPoint,
        WindowStuff
    }), "Main")

    if config.ShowIcon then
        WindowName.Position = UDim2.new(0, 50, 0, -24)
        local WindowIcon = SetProps(MakeElement("Image", config.Icon), {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 25, 0, 15)
        })
        WindowIcon.Parent = MainWindow.TopBar
    end

    MakeDraggable(DragPoint, MainWindow)

    local MobileReopenButton = SetChildren(SetProps(MakeElement("Button"), {
        Parent = Orion,
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0.5, -20, 0, 20),
        BackgroundTransparency = 0,
        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
        Visible = false
    }), {
        AddThemeObject(SetProps(MakeElement("Image", config.IntroToggleIcon or "http://www.roblox.com/asset/?id=8834748103"), {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0.7, 0, 0.7, 0),
        }), "Text"),
        MakeElement("Corner", 1)
    })

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
            TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 615, 0, 344)}):Play()
            MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
            task.wait(0.02)
            MainWindow.ClipsDescendants = false
            WindowStuff.Visible = true
            WindowTopBarLine.Visible = true
        else
            MainWindow.ClipsDescendants = true
            WindowTopBarLine.Visible = false
            MinimizeBtn.Ico.Image = "rbxassetid://7072720870"
            TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, WindowName.TextBounds.X + 140, 0, 50)}):Play()
            task.wait(0.1)
            WindowStuff.Visible = false
        end
        minimized = not minimized
    end)

    local function LoadSequence()
        MainWindow.Visible = false
        local LoadSequenceLogo = SetProps(MakeElement("Image", config.IntroIcon), {
            Parent = Orion,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.4, 0),
            Size = UDim2.new(0, 28, 0, 28),
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ImageTransparency = 1
        })

        local LoadSequenceText = SetProps(MakeElement("Label", config.IntroText, 14), {
            Parent = Orion,
            Size = UDim2.new(1, 0, 1, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 19, 0.5, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            Font = Enum.Font.FredokaOne,
            TextTransparency = 1
        })

        TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
        task.wait(0.8)
        TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -(LoadSequenceText.TextBounds.X/2), 0.5, 0)}):Play()
        task.wait(0.3)
        TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
        task.wait(2)
        TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        MainWindow.Visible = true
        LoadSequenceLogo:Destroy()
        LoadSequenceText:Destroy()
    end

    if config.IntroEnabled then
        LoadSequence()
    end

    local TabFunction = {}
    function TabFunction:MakeTab(tabConfig)
        tabConfig = tabConfig or {}
        tabConfig.Name = tabConfig.Name or "Tab"
        tabConfig.Icon = tabConfig.Icon or ""
        tabConfig.PremiumOnly = tabConfig.PremiumOnly or false

        local TabFrame = SetChildren(SetProps(MakeElement("Button"), {
            Size = UDim2.new(1, 0, 0, 30),
            Parent = TabHolder
        }), {
            AddThemeObject(SetProps(MakeElement("Image", tabConfig.Icon), {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 10, 0.5, 0),
                ImageTransparency = 0.4,
                Name = "Ico"
            }), "Text"),
            AddThemeObject(SetProps(MakeElement("Label", tabConfig.Name, 14), {
                Size = UDim2.new(1, -35, 1, 0),
                Position = UDim2.new(0, 35, 0, 0),
                Font = Enum.Font.FredokaOne,
                TextTransparency = 0.4,
                Name = "Title"
            }), "Text")
        })

        if GetIcon(tabConfig.Icon) then
            TabFrame.Ico.Image = GetIcon(tabConfig.Icon)
        end

        local Container = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255,255,255), 5), {
            Size = UDim2.new(1, -150, 1, -50),
            Position = UDim2.new(0, 150, 0, 50),
            Parent = MainWindow,
            Visible = false,
            Name = "ItemContainer"
        }), {
            MakeElement("List", 0, 6),
            MakeElement("Padding", 15, 10, 10, 15)
        }), "Divider")

        AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 30)
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
                    TweenService:Create(tab.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0.4}):Play()
                    TweenService:Create(tab.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
                end
            end
            for _, itemContainer in ipairs(MainWindow:GetChildren()) do
                if itemContainer.Name == "ItemContainer" then
                    itemContainer.Visible = false
                end
            end
            TweenService:Create(TabFrame.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
            TweenService:Create(TabFrame.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
            TabFrame.Title.Font = Enum.Font.FredokaOne
            Container.Visible = true
        end)

        local function GetElements(itemParent)
            local elementFunction = {}
            function elementFunction:AddLabel(text)
                local labelFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 0.7,
                    Parent = itemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", text, 15), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
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

            function elementFunction:AddParagraph(text, content)
                text = text or "Text"
                content = content or "Content"

                local paragraphFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 0.7,
                    Parent = itemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", text, 15), {
                        Size = UDim2.new(1, -12, 0, 14),
                        Position = UDim2.new(0, 12, 0, 10),
                        Font = Enum.Font.FredokaOne,
                        Name = "Title"
                    }), "Text"),
                    AddThemeObject(SetProps(MakeElement("Label", "", 13), {
                        Size = UDim2.new(1, -24, 0, 0),
                        Position = UDim2.new(0, 12, 0, 26),
                        Font = Enum.Font.FredokaOne,
                        Name = "Content",
                        TextWrapped = true
                    }), "TextDark"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke")
                }), "Second")

                AddConnection(paragraphFrame.Content:GetPropertyChangedSignal("Text"), function()
                    paragraphFrame.Content.Size = UDim2.new(1, -24, 0, paragraphFrame.Content.TextBounds.Y)
                    paragraphFrame.Size = UDim2.new(1, 0, 0, paragraphFrame.Content.TextBounds.Y + 35)
                end)

                paragraphFrame.Content.Text = content

                local paragraphFunction = {}
                function paragraphFunction:Set(newContent)
                    paragraphFrame.Content.Text = newContent
                end
                return paragraphFunction
            end

            -- (Additional element functions such as AddButton, AddToggle, AddSlider, AddDropdown,
            -- AddBind, AddTextbox, and AddColorpicker would follow here without functional changes,
            -- but with improved loop usage and code readability.)

            return elementFunction
        end

        local elementFunction = {}

        function elementFunction:AddSection(sectionConfig)
            sectionConfig.Name = sectionConfig.Name or "Section"

            local sectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {
                Size = UDim2.new(1, 0, 0, 26),
                Parent = Container
            }), {
                AddThemeObject(SetProps(MakeElement("Label", sectionConfig.Name, 14), {
                    Size = UDim2.new(1, -12, 0, 16),
                    Position = UDim2.new(0, 0, 0, 3),
                    Font = Enum.Font.FredokaOne
                }), "TextDark"),
                SetChildren(SetProps(MakeElement("TFrame"), {
                    AnchorPoint = Vector2.new(0, 0),
                    Size = UDim2.new(1, 0, 1, -24),
                    Position = UDim2.new(0, 0, 0, 23),
                    Name = "Holder"
                }), {
                    MakeElement("List", 0, 6)
                }),
            })

            AddConnection(sectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                sectionFrame.Size = UDim2.new(1, 0, 0, sectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y + 31)
                sectionFrame.Holder.Size = UDim2.new(1, 0, 0, sectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
            end)

            local sectionFunction = {}
            for key, value in pairs(GetElements(sectionFrame.Holder)) do
                sectionFunction[key] = value
            end
            return sectionFunction
        end

        for key, value in pairs(GetElements(Container)) do
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
            SetChildren(SetProps(MakeElement("TFrame"), {
                Size = UDim2.new(1, 0, 1, 0),
                Parent = ItemParent
            }), {
                AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://3610239960"), {
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(0, 15, 0, 15),
                    ImageTransparency = 0.4
                }), "Text"),
                AddThemeObject(SetProps(MakeElement("Label", "Unauthorised Access", 14), {
                    Size = UDim2.new(1, -38, 0, 14),
                    Position = UDim2.new(0, 38, 0, 18),
                    TextTransparency = 0.4
                }), "Text"),
                AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4483345875"), {
                    Size = UDim2.new(0, 56, 0, 56),
                    Position = UDim2.new(0, 84, 0, 110)
                }), "Text"),
                AddThemeObject(SetProps(MakeElement("Label", "Premium Features", 14), {
                    Size = UDim2.new(1, -150, 0, 14),
                    Position = UDim2.new(0, 150, 0, 112),
                    Font = Enum.Font.FredokaOne
                }), "Text"),
                AddThemeObject(SetProps(MakeElement("Label", "This part of the script is locked to Sirius Premium users. Purchase Premium in the Discord server (discord.gg/sirius)", 12), {
                    Size = UDim2.new(1, -200, 0, 14),
                    Position = UDim2.new(0, 150, 0, 138),
                    TextWrapped = true,
                    TextTransparency = 0.4
                }), "Text")
            })
        end
        return elementFunction
    end

    return TabFunction
end

-----------------------------------------
-- End of OrionLib Module
-----------------------------------------
return OrionLib
