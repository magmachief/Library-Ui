-- Ultra Orion UI Library (Complete Version)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Sound effects
local ClickSound = Instance.new("Sound")
ClickSound.SoundId = "rbxassetid://1319977660"
ClickSound.Volume = 0.3
ClickSound.Parent = SoundService

local HoverSound = Instance.new("Sound")
HoverSound.SoundId = "rbxassetid://1319977660"
HoverSound.Volume = 0.2
HoverSound.Parent = SoundService

-- Debug mode
local DEBUG_MODE = true

-- Debug module
local DebugModule = {}
function DebugModule.log(msg)
    if DEBUG_MODE then
        print("[DEBUG]", msg)
    end
end
function DebugModule.error(context, err)
    warn("[ERROR] Context: "..tostring(context).." | Error: "..tostring(err))
end

-- Premium system (always enabled)
for _, player in ipairs(Players:GetPlayers()) do
    player:SetAttribute("Premium", true)
end
Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("Premium", true)
end)
local function IsPremium(player)
    return player:GetAttribute("Premium") == true
end

-- Main library definition
local OrionLib = {
    Elements = {},
    ThemeObjects = {},
    Connections = {},
    Flags = {},
    Plugins = {},
    Themes = {
        Default = {
            Main = Color3.fromRGB(255, 182, 193),       -- Light Pink
            Second = Color3.fromRGB(221, 160, 221),     -- Plum
            Stroke = Color3.fromRGB(255, 105, 180),     -- Hot Pink
            Divider = Color3.fromRGB(255, 192, 203),    -- Pink
            Text = Color3.fromRGB(255, 255, 255),       -- White
            TextDark = Color3.fromRGB(240, 240, 240)    -- Light Gray
        },
        Dark = {
            Main = Color3.fromRGB(25, 25, 25),
            Second = Color3.fromRGB(40, 40, 40),
            Stroke = Color3.fromRGB(60, 60, 60),
            Divider = Color3.fromRGB(30, 30, 30),
            Text = Color3.fromRGB(255, 255, 255),
            TextDark = Color3.fromRGB(200, 200, 200)
        }
    },
    SelectedTheme = "Default",
    Folder = nil,
    SaveCfg = false,
    TextScale = 1,
    Language = "en",
    Keybinds = {},
    MobileMode = false
}

-- Check if mobile
if UserInputService.TouchEnabled then
    OrionLib.MobileMode = true
end

-- Screen GUI creation
local Orion = Instance.new("ScreenGui")
Orion.Name = "Orion"
if syn and syn.protect_gui then
    syn.protect_gui(Orion)
    Orion.Parent = CoreGui
else
    Orion.Parent = (gethui and gethui()) or CoreGui
end

-- Utility functions
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

-- Auto-disconnect events when UI is removed
task.spawn(function()
    while OrionLib:IsRunning() do
        task.wait()
    end
    for _, connection in ipairs(OrionLib.Connections) do
        connection:Disconnect()
    end
end)

-- Enhanced MakeDraggable with mobile support
local function MakeDraggable(dragPoint, mainFrame)
    pcall(function()
        local dragging = false
        local dragInput, mousePos, framePos
        
        local function updatePosition(input)
            if dragging then
                local delta
                if input.UserInputType == Enum.UserInputType.Touch then
                    delta = input.Position - mousePos
                else
                    delta = input.Position - mousePos
                end
                local newPos = UDim2.new(0, framePos.X + delta.X, 0, framePos.Y + delta.Y)
                TweenService:Create(mainFrame, TweenInfo.new(0.05, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Position = newPos
                }):Play()
            end
        end
        
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
        
        AddConnection(UserInputService.InputChanged, updatePosition)
    end)
end

-- Element creation functions
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

-- Notification system
local NotificationHolder = Create("Frame", {
    Parent = Orion,
    Position = UDim2.new(1, -25, 1, -25),
    Size = UDim2.new(0, 300, 1, -25),
    AnchorPoint = Vector2.new(1, 1),
    BackgroundTransparency = 1
}, {
    Create("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 5)
    })
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

        local notifParent = Create("Frame", {
            Parent = NotificationHolder,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1
        })

        local notifFrame = Create("Frame", {
            Parent = notifParent,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(1, -55, 0, 0),
            BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
            BackgroundTransparency = 0,
            AutomaticSize = Enum.AutomaticSize.Y
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 10)}),
            Create("UIStroke", {
                Color = OrionLib.Themes[OrionLib.SelectedTheme].Stroke,
                Thickness = 1.2
            }),
            Create("UIPadding", {
                PaddingBottom = UDim.new(0, 12),
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                PaddingTop = UDim.new(0, 12)
            }),
            Create("ImageLabel", {
                Size = UDim2.new(0, 20, 0, 20),
                ImageColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
                Image = config.Image,
                Name = "Icon",
                BackgroundTransparency = 1
            }),
            Create("TextLabel", {
                Size = UDim2.new(1, -30, 0, 20),
                Position = UDim2.new(0, 30, 0, 0),
                Font = Enum.Font.FredokaOne,
                Name = "Title",
                Text = config.Name,
                TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
                TextSize = 15,
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left
            }),
            Create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 25),
                Font = Enum.Font.FredokaOne,
                Name = "Content",
                Text = config.Content,
                TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].TextDark,
                TextSize = 14,
                BackgroundTransparency = 1,
                TextWrapped = true,
                AutomaticSize = Enum.AutomaticSize.Y
            })
        })

        -- Animation sequence
        TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()
        
        task.wait(config.Time - 0.88)
        
        -- Fade out sequence
        TweenService:Create(notifFrame.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {
            ImageTransparency = 1
        }):Play()
        
        TweenService:Create(notifFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {
            BackgroundTransparency = 0.6
        }):Play()
        
        task.wait(0.3)
        
        TweenService:Create(notifFrame.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {
            Transparency = 0.9
        }):Play()
        
        TweenService:Create(notifFrame.Title, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {
            TextTransparency = 0.4
        }):Play()
        
        TweenService:Create(notifFrame.Content, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {
            TextTransparency = 0.5
        }):Play()
        
        task.wait(0.05)
        
        -- Slide out animation
        notifFrame:TweenPosition(UDim2.new(1, 20, 0, 0), 'In', 'Quint', 0.8, true)
        
        task.wait(1.35)
        notifFrame:Destroy()
    end)
end

-- Main window creation
function OrionLib:MakeWindow(config)
    config = config or {}
    config.Name = config.Name or "Orion UI"
    config.ConfigFolder = config.ConfigFolder or config.Name
    config.SaveConfig = config.SaveConfig or false
    config.HidePremium = config.HidePremium or false
    config.IntroEnabled = config.IntroEnabled == nil and true or config.IntroEnabled
    config.IntroToggleIcon = config.IntroToggleIcon or "rbxassetid://14103606744"
    config.IntroText = config.IntroText or "Welcome to Orion UI"
    config.CloseCallback = config.CloseCallback or function() end
    config.ShowIcon = config.ShowIcon or false
    config.Icon = config.Icon or "rbxassetid://14103606744"
    config.IntroIcon = config.IntroIcon or "rbxassetid://14103606744"
    
    OrionLib.Folder = config.ConfigFolder
    OrionLib.SaveCfg = config.SaveConfig

    if config.SaveConfig and not isfolder(config.ConfigFolder) then
        makefolder(config.ConfigFolder)
    end

    -- Main window frame
    local MainWindow = Create("Frame", {
        Parent = Orion,
        Position = UDim2.new(0.5, -307, 0.5, -172),
        Size = UDim2.new(0, 615, 0, 344),
        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
        ClipsDescendants = true
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 10)}),
        Create("UIStroke", {
            Color = OrionLib.Themes[OrionLib.SelectedTheme].Stroke,
            Thickness = 1
        })
    })

    -- Top bar
    local TopBar = Create("Frame", {
        Parent = MainWindow,
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        Name = "TopBar"
    })

    -- Window title
    local WindowName = Create("TextLabel", {
        Parent = TopBar,
        Size = UDim2.new(1, -30, 2, 0),
        Position = UDim2.new(0, 25, 0, -24),
        Font = Enum.Font.FredokaOne,
        Text = config.Name,
        TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
        TextSize = 20,
        BackgroundTransparency = 1
    })

    -- Top bar line
    local WindowTopBarLine = Create("Frame", {
        Parent = TopBar,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Stroke
    })

    -- Close and minimize buttons
    local CloseBtn = Create("TextButton", {
        Parent = TopBar,
        Size = UDim2.new(0, 70, 0, 30),
        Position = UDim2.new(1, -90, 0, 10),
        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
        AutoButtonColor = false,
        Text = ""
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 7)}),
        Create("UIStroke", {
            Color = OrionLib.Themes[OrionLib.SelectedTheme].Stroke,
            Thickness = 1
        }),
        Create("ImageLabel", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 9, 0, 6),
        Image = "rbxassetid://7072725342",
        ImageColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
        BackgroundTransparency = 1
        })
    })

    local MinimizeBtn = Create("TextButton", {
        Parent = TopBar,
        Size = UDim2.new(0, 70, 0, 30),
        Position = UDim2.new(1, -170, 0, 10),
        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
        AutoButtonColor = false,
        Text = ""
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 7)}),
        Create("UIStroke", {
            Color = OrionLib.Themes[OrionLib.SelectedTheme].Stroke,
            Thickness = 1
        }),
        Create("ImageLabel", {
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 9, 0, 6),
            Image = "rbxassetid://7072719338",
            ImageColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
            BackgroundTransparency = 1,
            Name = "Ico"
        })
    })

    -- Drag point for window movement
    local DragPoint = Create("Frame", {
        Parent = MainWindow,
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1
    })

    -- Tab holder
    local TabHolder = Create("ScrollingFrame", {
        Parent = MainWindow,
        Size = UDim2.new(0, 150, 1, -50),
        Position = UDim2.new(0, 0, 0, 50),
        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Divider,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        BorderSizePixel = 0
    }, {
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8)
        }),
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 0),
            PaddingTop = UDim.new(0, 8)
        })
    })

    AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
    end)

    -- Mobile reopen button
    local MobileReopenButton = Create("TextButton", {
        Parent = Orion,
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0.5, -20, 0, 20),
        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
        AutoButtonColor = false,
        Visible = false
    }, {
        Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
        Create("ImageLabel", {
            Size = UDim2.new(0.7, 0, 0.7, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Image = config.IntroToggleIcon,
            ImageColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
            BackgroundTransparency = 1
        })
    })

    -- Make draggable
    MakeDraggable(DragPoint, MainWindow)
    MakeDraggable(MobileReopenButton, MobileReopenButton)

    -- Window controls
    local minimized = false
    local UIHidden = false

    AddConnection(CloseBtn.MouseButton1Up, function()
        ClickSound:Play()
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
            ClickSound:Play()
            MainWindow.Visible = true
            MobileReopenButton.Visible = false
            UIHidden = false
        end
    end)

    AddConnection(MobileReopenButton.Activated, function()
        ClickSound:Play()
        MainWindow.Visible = true
        MobileReopenButton.Visible = false
        UIHidden = false
    end)

    AddConnection(MinimizeBtn.MouseButton1Up, function()
        ClickSound:Play()
        if minimized then
            -- Restore window
            TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
                Size = UDim2.new(0, 615, 0, 344)
            }):Play()
            MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
            task.wait(0.02)
            MainWindow.ClipsDescendants = false
            TabHolder.Visible = true
            WindowTopBarLine.Visible = true
        else
            -- Minimize window
            MainWindow.ClipsDescendants = true
            WindowTopBarLine.Visible = false
            MinimizeBtn.Ico.Image = "rbxassetid://7072720870"
            TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
                Size = UDim2.new(0, WindowName.TextBounds.X + 140, 0, 50)
            }):Play()
            task.wait(0.1)
            TabHolder.Visible = false
        end
        minimized = not minimized
    end)

    -- Intro sequence
    local function LoadSequence()
        MainWindow.Visible = false
        local LoadSequenceLogo = Create("ImageLabel", {
            Parent = Orion,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.4, 0),
            Size = UDim2.new(0, 28, 0, 28),
            Image = config.IntroIcon,
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ImageTransparency = 1,
            BackgroundTransparency = 1
        })

        local LoadSequenceText = Create("TextLabel", {
            Parent = Orion,
            Size = UDim2.new(1, 0, 1, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 19, 0.5, 0),
            Text = config.IntroText,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextTransparency = 1,
            TextSize = 14,
            Font = Enum.Font.FredokaOne,
            TextXAlignment = Enum.TextXAlignment.Center,
            BackgroundTransparency = 1
        })

        -- Logo animation
        TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            ImageTransparency = 0,
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        
        task.wait(0.8)
        
        -- Text animation
        TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Position = UDim2.new(0.5, -(LoadSequenceText.TextBounds.X / 2), 0.5, 0)
        }):Play()
        
        task.wait(0.3)
        
        TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            TextTransparency = 0
        }):Play()
        
        task.wait(2)
        
        -- Fade out
        TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            TextTransparency = 1
        }):Play()
        
        MainWindow.Visible = true
        LoadSequenceLogo:Destroy()
        LoadSequenceText:Destroy()
    end

    if config.IntroEnabled then
        LoadSequence()
    end

    -- Tab functions
    local TabFunction = {}
    function TabFunction:MakeTab(tabConfig)
        tabConfig = tabConfig or {}
        tabConfig.Name = tabConfig.Name or "Tab"
        tabConfig.Icon = tabConfig.Icon or ""
        tabConfig.PremiumOnly = tabConfig.PremiumOnly or false

        local TabFrame = Create("TextButton", {
            Parent = TabHolder,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = ""
        }, {
            Create("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 10, 0.5, 0),
                Image = tabConfig.Icon,
                ImageTransparency = 0.4,
                ImageColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
                BackgroundTransparency = 1,
                Name = "Ico"
            }),
            Create("TextLabel", {
                Size = UDim2.new(1, -35, 1, 0),
                Position = UDim2.new(0, 35, 0, 0),
                Font = Enum.Font.FredokaOne,
                Text = tabConfig.Name,
                TextTransparency = 0.4,
                TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
                TextSize = 14,
                BackgroundTransparency = 1,
                Name = "Title"
            })
        })

        local Container = Create("ScrollingFrame", {
            Parent = MainWindow,
            Size = UDim2.new(1, -150, 1, -50),
            Position = UDim2.new(0, 150, 0, 50),
            BackgroundTransparency = 1,
            ScrollBarThickness = 5,
            ScrollBarImageColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Divider,
            Visible = false,
            Name = "ItemContainer"
        }, {
            Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6)
            }),
            Create("UIPadding", {
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 15),
                PaddingTop = UDim.new(0, 15)
            })
        })

        AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 30)
        end)

        -- Activate first tab by default
        local firstTab = true
        if firstTab then
            firstTab = false
            TabFrame.Ico.ImageTransparency = 0
            TabFrame.Title.TextTransparency = 0
            TabFrame.Title.Font = Enum.Font.FredokaOne
            Container.Visible = true
        end

        -- Tab switching
        AddConnection(TabFrame.MouseButton1Click, function()
            ClickSound:Play()
            for _, tab in ipairs(TabHolder:GetChildren()) do
                if tab:IsA("TextButton") then
                    tab.Title.Font = Enum.Font.FredokaOne
                    TweenService:Create(tab.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        ImageTransparency = 0.4
                    }):Play()
                    TweenService:Create(tab.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        TextTransparency = 0.4
                    }):Play()
                end
            end
            
            for _, itemContainer in ipairs(MainWindow:GetChildren()) do
                if itemContainer.Name == "ItemContainer" then
                    itemContainer.Visible = false
                end
            end
            
            TweenService:Create(TabFrame.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                ImageTransparency = 0
            }):Play()
            TweenService:Create(TabFrame.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                TextTransparency = 0
            }):Play()
            TabFrame.Title.Font = Enum.Font.FredokaOne
            Container.Visible = true
        end)

        -- Element functions
        local ElementFunction = {}

        function ElementFunction:AddLabel(text)
            local labelFrame = Create("Frame", {
                Parent = Container,
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
                BackgroundTransparency = 0.7
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
                Create("UIStroke", {
                    Color = OrionLib.Themes[OrionLib.SelectedTheme].Stroke,
                    Thickness = 1
                }),
                Create("TextLabel", {
                    Size = UDim2.new(1, -12, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                    Font = Enum.Font.FredokaOne,
                    Text = text,
                    TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
                    TextSize = 15,
                    BackgroundTransparency = 1,
                    Name = "Content"
                })
            })

            local labelFunction = {}
            function labelFunction:Set(newText)
                labelFrame.Content.Text = newText
            end
            return labelFunction
        end

        function ElementFunction:AddButton(buttonConfig)
            buttonConfig = buttonConfig or {}
            buttonConfig.Name = buttonConfig.Name or "Button"
            buttonConfig.Callback = buttonConfig.Callback or function() end
            buttonConfig.Icon = buttonConfig.Icon or "rbxassetid://3944703587"

            local button = {}
            local buttonFrame = Create("Frame", {
                Parent = Container,
                Size = UDim2.new(1, 0, 0, 33),
                BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
                Create("UIStroke", {
                    Color = OrionLib.Themes[OrionLib.SelectedTheme].Stroke,
                    Thickness = 1
                }),
                Create("TextLabel", {
                    Size = UDim2.new(1, -12, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                    Font = Enum.Font.FredokaOne,
                    Text = buttonConfig.Name,
                    TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
                    TextSize = 15,
                    BackgroundTransparency = 1,
                    Name = "Content"
                }),
                Create("ImageLabel", {
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(1, -30, 0, 7),
                    Image = buttonConfig.Icon,
                    ImageColor3 = OrionLib.Themes[OrionLib.SelectedTheme].TextDark,
                    BackgroundTransparency = 1
                }),
                Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    AutoButtonColor = false
                })
            })

            local buttonClick = buttonFrame:FindFirstChildOfClass("TextButton")

            -- Hover effects
            AddConnection(buttonClick.MouseEnter, function()
                HoverSound:Play()
                TweenService:Create(buttonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                    BackgroundColor3 = Color3.fromRGB(
                        OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
                        OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
                        OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
                }):Play()
            end)

            AddConnection(buttonClick.MouseLeave, function()
                TweenService:Create(buttonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                    BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second
                }):Play()
            end)

            -- Click effects
            AddConnection(buttonClick.MouseButton1Up, function()
                ClickSound:Play()
                TweenService:Create(buttonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                    BackgroundColor3 = Color3.fromRGB(
                        OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
                        OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
                        OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
                }):Play()
                task.spawn(buttonConfig.Callback)
            end)

            AddConnection(buttonClick.MouseButton1Down, function()
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
            toggleConfig.Color = toggleConfig.Color or Color3.fromRGB(9, 99, 195)
            toggleConfig.Flag = toggleConfig.Flag or nil
            toggleConfig.Save = toggleConfig.Save or false

            local toggle = {Value = toggleConfig.Default, Save = toggleConfig.Save}
            local toggleFrame = Create("Frame", {
                Parent = Container,
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
                Create("UIStroke", {
                    Color = OrionLib.Themes[OrionLib.SelectedTheme].Stroke,
                    Thickness = 1
                }),
                Create("TextLabel", {
                    Size = UDim2.new(1, -12, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                    Font = Enum.Font.FredokaOne,
                    Text = toggleConfig.Name,
                    TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
                    TextSize = 15,
                    BackgroundTransparency = 1,
                    Name = "Content"
                }),
                Create("Frame", {
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(1, -24, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = toggleConfig.Default and toggleConfig.Color or OrionLib.Themes.Default.Divider
                }, {
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
                    Create("UIStroke", {
                        Color = toggleConfig.Default and toggleConfig.Color or OrionLib.Themes.Default.Stroke,
                        Transparency = 0.5,
                        Name = "Stroke"
                    }),
                    Create("ImageLabel", {
                        Size = UDim2.new(0, toggleConfig.Default and 20 or 8, 0, toggleConfig.Default and 20 or 8),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        Image = "rbxassetid://3944680095",
                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                        ImageTransparency = toggleConfig.Default and 0 or 1,
                        Name = "Ico"
                    })
                }),
                Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    AutoButtonColor = false
                })
            })

            local toggleBox = toggleFrame:FindFirstChildOfClass("Frame")
            local toggleClick = toggleFrame:FindFirstChildOfClass("TextButton")

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
        Size = self.Value and UDim2.new(0, 20, 0, 20) or UDim2.new(0, 8, 0, 8)
    }):Play()
    toggleConfig.Callback(self.Value)
end

toggle:Set(toggle.Value)

if toggleConfig.Flag then
    OrionLib.Flags[toggleConfig.Flag] = toggle
end

-- Hover effects
AddConnection(toggleClick.MouseEnter, function()
    HoverSound:Play()
    TweenService:Create(toggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
        BackgroundColor3 = Color3.fromRGB(
            OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
            OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
            OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
    }):Play()
end)

AddConnection(toggleClick.MouseLeave, function()
    TweenService:Create(toggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second
    }):Play()
end)

-- Click effects
AddConnection(toggleClick.MouseButton1Up, function()
    ClickSound:Play()
    TweenService:Create(toggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
        BackgroundColor3 = Color3.fromRGB(
            OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
            OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
            OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
    }):Play()
    toggle:Set(not toggle.Value)
end)

AddConnection(toggleClick.MouseButton1Down, function()
    TweenService:Create(toggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
        BackgroundColor3 = Color3.fromRGB(
            OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6,
            OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6,
            OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)
    }):Play()
end)

return toggle
end

function ElementFunction:AddDropdown(dropdownConfig)
    dropdownConfig = dropdownConfig or {}
    dropdownConfig.Name = dropdownConfig.Name or "Dropdown"
    dropdownConfig.Options = dropdownConfig.Options or {}
    dropdownConfig.Default = dropdownConfig.Default or 1
    dropdownConfig.Callback = dropdownConfig.Callback or function() end
    dropdownConfig.Multi = dropdownConfig.Multi or false

    local dropdown = {Value = dropdownConfig.Default, Options = dropdownConfig.Options}
    local dropdownFrame = Create("Frame", {
        Parent = Container,
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
        ClipsDescendants = true
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
        Create("UIStroke", {
            Color = OrionLib.Themes[OrionLib.SelectedTheme].Stroke,
            Thickness = 1
        }),
        Create("TextLabel", {
            Size = UDim2.new(1, -12, 0, 18),
            Position = UDim2.new(0, 12, 0, 5),
            Font = Enum.Font.FFredokaOne,
            Text = dropdownConfig.Name,
            TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
            TextSize = 14,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        Create("TextButton", {
            Size = UDim2.new(1, -24, 0, 20),
            Position = UDim2.new(0, 12, 0, 20),
            Font = Enum.Font.FFredokaOne,
            Text = dropdownConfig.Options[dropdownConfig.Default] or "Select...",
            TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].TextDark,
            TextSize = 14,
            BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
            BackgroundTransparency = 0.7,
            AutoButtonColor = false
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 3)}),
            Create("UIStroke", {
                Color = OrionLib.Themes[OrionLib.SelectedTheme].Stroke,
                Thickness = 0.8
            }),
            Create("ImageLabel", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new(1, -20, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                Image = "rbxassetid://3926305904",
                ImageColor3 = OrionLib.Themes[OrionLib.SelectedTheme].TextDark,
                ImageRectOffset = Vector2.new(324, 364),
                ImageRectSize = Vector2.new(36, 36),
                BackgroundTransparency = 1
            })
        })
    })

    local dropdownButton = dropdownFrame:FindFirstChildOfClass("TextButton")
    local dropdownOpen = false
    local optionFrames = {}

    local function UpdateDropdown()
        dropdownButton.Text = dropdownConfig.Multi and "Select..." or
            (dropdownConfig.Options[dropdown.Value] or "Select...")
    end

    local function ToggleDropdown()
        dropdownOpen = not dropdownOpen
        for _, frame in pairs(optionFrames) do
            frame.Visible = dropdownOpen
        end
        dropdownFrame.Size = dropdownOpen and UDim2.new(1, 0, 0, 38 + (#dropdownConfig.Options * 25)) or UDim2.new(1, 0, 0, 38)
    end

    for i, option in pairs(dropdownConfig.Options) do
        local optionFrame = Create("TextButton", {
            Parent = dropdownFrame,
            Size = UDim2.new(1, -24, 0, 20),
            Position = UDim2.new(0, 12, 0, 20 + (i * 25)),
            Font = Enum.Font.FFredokaOne,
            Text = option,
            TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].TextDark,
            TextSize = 14,
            BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
            BackgroundTransparency = 0.7,
            AutoButtonColor = false,
            Visible = false
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 3)}),
            Create("UIStroke", {
                Color = OrionLib.Themes[OrionLib.SelectedTheme].Stroke,
                Thickness = 0.8
            })
        })
        table.insert(optionFrames, optionFrame)

        AddConnection(optionFrame.MouseButton1Click, function()
            if dropdownConfig.Multi then
                -- Multi-select logic
            else
                dropdown.Value = i
                dropdownConfig.Callback(dropdown.Value)
                ToggleDropdown()
                UpdateDropdown()
            end
        end)
    end

    AddConnection(dropdownButton.MouseButton1Click, function()
        ToggleDropdown()
    end)

    function dropdown:Refresh(newOptions, keepValue)
        self.Options = newOptions or self.Options
        if not keepValue then
            self.Value = 1
        end
        UpdateDropdown()
    end

    return dropdown
end

-- Initialize the library
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

return OrionLib

