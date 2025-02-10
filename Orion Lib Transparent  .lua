-- Enhanced OrionLib v1.0
-- Features:
--  • Improved animations using SmoothTween (Sine/InOut easing)
--  • Draggable toggle icon for mobile
--  • A fully functional mobile console (like the PC console)
--  • Original OrionLib functionality (MakeWindow, notifications, elements, etc.)
-- 
-- NOTE: This is an all–in–one script. Adjust asset IDs, colors, sizes and positions as needed.
--       It assumes your exploit environment supports loadstring and (if applicable) syn.protect_gui.
-- 
-- IMPORTANT: Use this script only in a safe testing environment.

-----------------------------------------------------
-- SERVICES & VARIABLES
-----------------------------------------------------
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local HttpService     = game:GetService("HttpService")
local Players         = game:GetService("Players")
local LocalPlayer     = Players.LocalPlayer
local Mouse           = LocalPlayer:GetMouse()

-----------------------------------------------------
-- HELPER FUNCTIONS
-----------------------------------------------------

-- SmoothTween: a helper function to run tweens with Sine/InOut easing by default.
local function SmoothTween(instance, properties, duration, easingStyle, easingDirection)
	easingStyle = easingStyle or Enum.EasingStyle.Sine
	easingDirection = easingDirection or Enum.EasingDirection.InOut
	local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)
	local tween = TweenService:Create(instance, tweenInfo, properties)
	tween:Play()
	return tween
end

-- Create: simplifies instance creation.
local function Create(instanceType, parent, props, children)
	local obj = Instance.new(instanceType)
	if parent then obj.Parent = parent end
	if props then
		for i, v in pairs(props) do
			obj[i] = v
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = obj
		end
	end
	return obj
end

-- SetProps: set multiple properties at once.
local function SetProps(instance, props)
	if instance and props then
		for i, v in pairs(props) do
			instance[i] = v
		end
	end
	return instance
end

-- Connection handling
local Connections = {}
local function AddConnection(signal, func)
	local connection = signal:Connect(func)
	table.insert(Connections, connection)
	return connection
end

-- MakeDraggable: makes any GUI draggable by a designated “drag point.”
local function MakeDraggable(DragPoint, Main)
	local dragging = false
	local dragInput, mousePos, framePos

	AddConnection(DragPoint.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			mousePos = input.Position
			framePos = Main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	AddConnection(DragPoint.InputChanged, function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	AddConnection(UserInputService.InputChanged, function(input)
		if input == dragInput and dragging then
			local delta = input.Position - mousePos
			SmoothTween(Main, {Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)}, 0.05, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		end
	end)
end

-----------------------------------------------------
-- ORIONLIB CORE
-----------------------------------------------------
local OrionLib = {}
OrionLib.Connections   = Connections
OrionLib.Elements      = {}
OrionLib.Flags         = {}
OrionLib.ThemeObjects  = {}
OrionLib.Themes        = {
	Default = {
		Main      = Color3.fromRGB(22, 2, 28),
		Second    = Color3.fromRGB(61, 28, 71),
		Stroke    = Color3.fromRGB(60, 60, 60),
		Divider   = Color3.fromRGB(60, 60, 60),
		Text      = Color3.fromRGB(240, 240, 240),
		TextDark  = Color3.fromRGB(150, 150, 150)
	}
}
OrionLib.SelectedTheme = "Default"
OrionLib.SaveCfg       = false
OrionLib.Folder        = "OrionConfig"

-- Create the main GUI. Use syn.protect_gui if available.
local Orion = Create("ScreenGui", nil, {Name = "Orion"}, nil)
if syn and syn.protect_gui then
	syn.protect_gui(Orion)
	Orion.Parent = game:GetService("CoreGui")
else
	Orion.Parent = gethui() or game:GetService("CoreGui")
end
OrionLib.MainGui = Orion

-----------------------------------------------------
-- NOTIFICATION SYSTEM
-----------------------------------------------------
-- Create a notification holder in the bottom–right corner.
local NotificationHolder = Create("Frame", Orion, {
	Size = UDim2.new(0, 300, 1, -25),
	Position = UDim2.new(1, -25, 1, -25),
	AnchorPoint = Vector2.new(1, 1),
	BackgroundTransparency = 1
})
local NotificationList = Create("UIListLayout", NotificationHolder, {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 5)
})
AddConnection(NotificationList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
	NotificationHolder.CanvasSize = UDim2.new(0, 0, 0, NotificationList.AbsoluteContentSize.Y + 16)
end)
OrionLib.NotificationHolder = NotificationHolder

-- MakeNotification: shows a notification with smooth animations.
function OrionLib:MakeNotification(Config)
	Config = Config or {}
	Config.Name    = Config.Name or "Notification"
	Config.Content = Config.Content or "Test Notification"
	Config.Image   = Config.Image or "rbxassetid://4384403532"
	Config.Time    = Config.Time or 5

	local NotificationParent = Create("Frame", NotificationHolder, {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y
	})
	local NotificationFrame = Create("Frame", NotificationParent, {
		Size = UDim2.new(1, 0, 0, 80),
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		BorderSizePixel = 0,
		Position = UDim2.new(1, -55, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y
	})
	local Icon = Create("ImageLabel", NotificationFrame, {
		Image = Config.Image,
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundTransparency = 1,
		ImageColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text
	})
	local Title = Create("TextLabel", NotificationFrame, {
		Text = Config.Name,
		Font = Enum.Font.FredokaOne,
		TextSize = 15,
		Size = UDim2.new(1, -40, 0, 20),
		Position = UDim2.new(0, 40, 0, 10),
		BackgroundTransparency = 1,
		TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text
	})
	local Content = Create("TextLabel", NotificationFrame, {
		Text = Config.Content,
		Font = Enum.Font.FredokaOne,
		TextSize = 14,
		Size = UDim2.new(1, -20, 0, 40),
		Position = UDim2.new(0, 10, 0, 35),
		BackgroundTransparency = 1,
		TextWrapped = true,
		TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].TextDark
	})
	SmoothTween(NotificationFrame, {Position = UDim2.new(0, 0, 0, 0)}, 0.5)
	task.spawn(function()
		wait(Config.Time - 0.8)
		SmoothTween(Icon, {ImageTransparency = 1}, 0.4)
		SmoothTween(Title, {TextTransparency = 0.5}, 0.4)
		SmoothTween(Content, {TextTransparency = 0.5}, 0.4)
		wait(0.5)
		NotificationFrame:TweenPosition(UDim2.new(1, 20, 0, 0), 'In', 'Quint', 0.8, true)
		wait(1)
		NotificationParent:Destroy()
	end)
end

-----------------------------------------------------
-- WINDOW CREATION (MakeWindow)
-----------------------------------------------------
function OrionLib:MakeWindow(WindowConfig)
	WindowConfig = WindowConfig or {}
	WindowConfig.Name          = WindowConfig.Name or "Orion Window"
	WindowConfig.ConfigFolder  = WindowConfig.ConfigFolder or WindowConfig.Name
	WindowConfig.SaveConfig    = WindowConfig.SaveConfig or false
	WindowConfig.IntroEnabled  = WindowConfig.IntroEnabled == nil and true or WindowConfig.IntroEnabled
	WindowConfig.IntroIcon     = WindowConfig.IntroIcon or "rbxassetid://8834748103"
	WindowConfig.IntroText     = WindowConfig.IntroText or "Orion"
	OrionLib.Folder             = WindowConfig.ConfigFolder
	OrionLib.SaveCfg            = WindowConfig.SaveConfig

	-- Create folder if saving config
	if WindowConfig.SaveConfig and not isfolder(WindowConfig.ConfigFolder) then
		makefolder(WindowConfig.ConfigFolder)
	end

	-- Main Window
	local MainWindow = Create("Frame", Orion, {
		Size = UDim2.new(0, 615, 0, 344),
		Position = UDim2.new(0.5, -307, 0.5, -172),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ClipsDescendants = true
	})
	-- Top Bar
	local TopBar = Create("Frame", MainWindow, {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
		BorderSizePixel = 0
	})
	local WindowName = Create("TextLabel", TopBar, {
		Text = WindowConfig.Name,
		Font = Enum.Font.FredokaOne,
		TextSize = 20,
		Size = UDim2.new(1, -30, 1, 0),
		Position = UDim2.new(0, 25, 0, 0),
		BackgroundTransparency = 1,
		TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text
	})
	local CloseBtn = Create("TextButton", TopBar, {
		Size = UDim2.new(0, 35, 1, 0),
		Position = UDim2.new(1, -35, 0, 0),
		Text = "X",
		Font = Enum.Font.FredokaOne,
		TextSize = 20,
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(255, 0, 0)
	})
	local MinimizeBtn = Create("TextButton", TopBar, {
		Size = UDim2.new(0, 35, 1, 0),
		Position = UDim2.new(1, -70, 0, 0),
		Text = "-",
		Font = Enum.Font.FredokaOne,
		TextSize = 20,
		BackgroundTransparency = 1,
		TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text
	})
	-- Content Container (for tabs, sections, etc.)
	local ContentContainer = Create("Frame", MainWindow, {
		Name = "ContentContainer",
		Size = UDim2.new(1, 0, 1, -50),
		Position = UDim2.new(0, 0, 0, 50),
		BackgroundTransparency = 1
	})
	-- Make the window draggable via the TopBar.
	MakeDraggable(TopBar, MainWindow)
	-- Close Button functionality
	CloseBtn.MouseButton1Click:Connect(function()
		SmoothTween(MainWindow, {Position = UDim2.new(0.5, 0, 1.2, 0)}, 0.3)
		wait(0.3)
		MainWindow:Destroy()
		OrionLib:MakeNotification({Name = "Interface Hidden", Content = "Press Left Control to reopen.", Time = 5})
	end)
	-- Minimize Button functionality
	local Minimized = false
	MinimizeBtn.MouseButton1Click:Connect(function()
		if Minimized then
			SmoothTween(MainWindow, {Size = UDim2.new(0, 615, 0, 344)}, 0.5)
			MinimizeBtn.Text = "-"
			ContentContainer.Visible = true
		else
			SmoothTween(MainWindow, {Size = UDim2.new(0, WindowName.TextBounds.X + 140, 0, 50)}, 0.5)
			MinimizeBtn.Text = "+"
			ContentContainer.Visible = false
		end
		Minimized = not Minimized
	end)
	OrionLib.MainWindow = MainWindow

	-- Return a table with functions to add elements to the window.
	return {
		AddLabel = function(text)
			local lbl = Create("TextLabel", ContentContainer, {
				Text = text,
				Font = Enum.Font.FredokaOne,
				TextSize = 15,
				BackgroundTransparency = 1,
				TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
				Size = UDim2.new(1, 0, 0, 30)
			})
			return lbl
		end,
		AddButton = function(ButtonConfig)
			ButtonConfig = ButtonConfig or {}
			ButtonConfig.Name = ButtonConfig.Name or "Button"
			ButtonConfig.Callback = ButtonConfig.Callback or function() end
			local btn = Create("TextButton", ContentContainer, {
				Text = ButtonConfig.Name,
				Font = Enum.Font.FredokaOne,
				TextSize = 15,
				BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
				TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
				Size = UDim2.new(1, 0, 0, 35)
			})
			btn.MouseButton1Click:Connect(function()
				SmoothTween(btn, {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
					OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
					OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}, 0.25)
				task.spawn(ButtonConfig.Callback)
			end)
			return btn
		end,
		-- (Additional element functions like AddToggle, AddSlider, etc. can be added here.)
	}
end

-----------------------------------------------------
-- MOBILE TOGGLE ICON (Draggable)
-----------------------------------------------------
local MobileReopenButton = Create("TextButton", nil, {
	Size = UDim2.new(0, 40, 0, 40),
	Position = UDim2.new(0.5, -20, 0, 20),
	BackgroundTransparency = 0,
	BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
	Text = ""
})
if syn and syn.protect_gui then
	syn.protect_gui(MobileReopenButton)
	MobileReopenButton.Parent = game:GetService("CoreGui")
else
	MobileReopenButton.Parent = gethui() or game:GetService("CoreGui")
end
MakeDraggable(MobileReopenButton, MobileReopenButton)
MobileReopenButton.MouseButton1Click:Connect(function()
	if OrionLib.MainWindow then
		OrionLib.MainWindow.Visible = true
		MobileReopenButton.Visible = false
	end
end)

-----------------------------------------------------
-- MOBILE CONSOLE
-----------------------------------------------------
function OrionLib:MakeMobileConsole()
	local consoleGui = Create("ScreenGui", nil, {Name = "MobileConsole", ResetOnSpawn = false})
	if syn and syn.protect_gui then
		syn.protect_gui(consoleGui)
	end
	consoleGui.Parent = game:GetService("CoreGui")
	
	local consoleFrame = Create("Frame", consoleGui, {
		Name = "ConsoleFrame",
		Size = UDim2.new(0, 300, 0, 400),
		Position = UDim2.new(0.5, -150, 0.5, -200),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BorderSizePixel = 0
	})
	MakeDraggable(consoleFrame, consoleFrame)
	
	-- Title Bar
	local titleBar = Create("Frame", consoleFrame, {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BorderSizePixel = 0
	})
	local titleLabel = Create("TextLabel", titleBar, {
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = "Mobile Console",
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.SourceSans,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	local closeButton = Create("TextButton", titleBar, {
		Size = UDim2.new(0, 30, 1, 0),
		Position = UDim2.new(1, -30, 0, 0),
		Text = "X",
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(1, 0, 0),
		Font = Enum.Font.SourceSansBold,
		TextSize = 18
	})
	closeButton.MouseButton1Click:Connect(function()
		SmoothTween(consoleFrame, {Position = UDim2.new(0.5, 0, 1.2, 0)}, 0.3)
		wait(0.3)
		consoleGui:Destroy()
	end)
	
	-- Output Box (Scrolling Frame)
	local outputBox = Create("ScrollingFrame", consoleFrame, {
		Name = "OutputBox",
		Size = UDim2.new(1, -20, 1, -100),
		Position = UDim2.new(0, 10, 0, 40),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderSizePixel = 0,
		ScrollBarThickness = 4
	})
	local outputLayout = Create("UIListLayout", outputBox, {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5)
	})
	
	-- Input Box and Execute Button
	local inputBox = Create("TextBox", consoleFrame, {
		Name = "InputBox",
		Size = UDim2.new(1, -80, 0, 40),
		Position = UDim2.new(0, 10, 1, -50),
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		TextColor3 = Color3.new(1, 1, 1),
		PlaceholderText = "Enter command...",
		ClearTextOnFocus = false,
		Font = Enum.Font.SourceSans,
		TextSize = 18
	})
	local executeButton = Create("TextButton", consoleFrame, {
		Name = "ExecuteButton",
		Size = UDim2.new(0, 60, 0, 40),
		Position = UDim2.new(1, -70, 1, -50),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		Text = "Run",
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.SourceSansBold,
		TextSize = 18
	})
	
	-- Function to append output text
	local function appendOutput(text)
		local newLabel = Create("TextLabel", outputBox, {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = text,
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.SourceSans,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left
		})
		outputBox.CanvasSize = UDim2.new(0, 0, 0, outputLayout.AbsoluteContentSize.Y)
	end
	
	executeButton.MouseButton1Click:Connect(function()
		local command = inputBox.Text
		appendOutput("> " .. command)
		local success, result = pcall(function()
			local func = loadstring(command)
			if func then
				return func()
			end
		end)
		if not success then
			appendOutput("Error: " .. tostring(result))
		elseif result ~= nil then
			appendOutput(tostring(result))
		end
		inputBox.Text = ""
		wait()
		outputBox.CanvasSize = UDim2.new(0, 0, 0, outputLayout.AbsoluteContentSize.Y)
	end)
	
	-- Animate console in
	local origPos = consoleFrame.Position
	consoleFrame.Position = UDim2.new(0.5, 0, 1.2, 0)
	SmoothTween(consoleFrame, {Position = origPos}, 0.5)
end

-- Toggle function for the mobile console.
OrionLib.ToggleMobileConsole = function()
	if not game:GetService("CoreGui"):FindFirstChild("MobileConsole") then
		OrionLib:MakeMobileConsole()
	end
end

-- (For testing, toggle the mobile console with F9.)
AddConnection(UserInputService.InputBegan, function(input)
	if input.KeyCode == Enum.KeyCode.F9 then
		OrionLib.ToggleMobileConsole()
	end
end)

-----------------------------------------------------
-- DESTROY FUNCTION
-----------------------------------------------------
function OrionLib:Destroy()
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	if self.MainGui then
		self.MainGui:Destroy()
	end
end

-----------------------------------------------------
-- RETURN ORIONLIB
-----------------------------------------------------
return OrionLib
