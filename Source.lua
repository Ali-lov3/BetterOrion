local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local OrionLib = {
	Elements = {},
	ThemeObjects = {},
	Connections = {},
	Flags = {},
	Themes = {
		Default = {
			Main = Color3.fromRGB(17, 17, 21),
			Second = Color3.fromRGB(24, 24, 29),
			Stroke = Color3.fromRGB(52, 52, 60),
			Divider = Color3.fromRGB(42, 42, 49),
			Text = Color3.fromRGB(237, 237, 242),
			TextDark = Color3.fromRGB(148, 148, 160)
		}
	},
	SelectedTheme = "Default",
	Folder = nil,
	SaveCfg = false
}

local Lucide
pcall(function()
	Lucide = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/icons.lua"))()
end)

local function ResolveIcon(Icon)
	if type(Icon) == "number" then return "rbxassetid://" .. Icon end
	if type(Icon) == "string" then
		if string.match(Icon, "^rbxassetid://") or string.match(Icon, "^https?://") then return Icon end
		if string.match(Icon, "^%d+$") then return "rbxassetid://" .. Icon end
		local Name = string.lower(Icon)
		if type(Lucide) == "function" then
			local ok, Data = pcall(Lucide, Name)
			if ok and type(Data) == "table" then
				local Id = Data.id or Data.Id or Data[1]
				local Size = Data.imageRectSize or Data.ImageRectSize or Data[2]
				local Offset = Data.imageRectOffset or Data.imageRectPosition or Data.ImageRectOffset or Data[3]
				if Id then return "rbxassetid://" .. tostring(Id), Offset, Size end
			end
		elseif type(Lucide) == "table" then
			for _, Set in { Lucide["48px"], Lucide["256px"], Lucide } do
				if type(Set) == "table" then
					local Data = Set[Name]
					if type(Data) == "table" and Data[1] then
						return "rbxassetid://" .. tostring(Data[1]), Data[3], Data[2]
					end
				end
			end
		end
		return Icon
	end
	return ""
end

local function ToVector2(Value)
	if typeof(Value) == "Vector2" then return Value end
	if type(Value) == "table" then return Vector2.new(Value[1] or Value.X or 0, Value[2] or Value.Y or 0) end
	return Vector2.new(0, 0)
end

local function ApplyIcon(Object, Icon)
	if not Icon or Icon == "" then return end
	local Image, Offset, Size = ResolveIcon(Icon)
	Object.Image = Image
	if Offset then Object.ImageRectOffset = ToVector2(Offset) end
	if Size then Object.ImageRectSize = ToVector2(Size) end
end

local Orion = Instance.new("ScreenGui")
Orion.Name = "Orion"
if syn then
	syn.protect_gui(Orion)
	Orion.Parent = game.CoreGui
else
	Orion.Parent = gethui() or game.CoreGui
end

if gethui then
	for _, Interface in ipairs(gethui():GetChildren()) do
		if Interface.Name == Orion.Name and Interface ~= Orion then
			Interface:Destroy()
		end
	end
else
	for _, Interface in ipairs(game.CoreGui:GetChildren()) do
		if Interface.Name == Orion.Name and Interface ~= Orion then
			Interface:Destroy()
		end
	end
end

function OrionLib:IsRunning()
	if gethui then
		return Orion.Parent == gethui()
	else
		return Orion.Parent == game:GetService("CoreGui")
	end

end

local function GetInset()
	if Orion.IgnoreGuiInset then
		return Vector2.new(0, 0)
	end
	local TopLeft = GuiService:GetGuiInset()
	return TopLeft
end

local function GetInputPosition(Input)
	if Input.UserInputType == Enum.UserInputType.Touch then
		return Vector2.new(Input.Position.X, Input.Position.Y) - GetInset()
	end
	return Vector2.new(Mouse.X, Mouse.Y)
end

local function IsPointerStart(Input)
	return Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch
end

local function LockScrolling(Object, Locked)
	local Parent = Object.Parent
	while Parent do
		if Parent:IsA("ScrollingFrame") then
			Parent.ScrollingEnabled = not Locked
		end
		Parent = Parent.Parent
	end
end

local function AddConnection(Signal, Function)
	if (not OrionLib:IsRunning()) then
		return
	end
	local SignalConnect = Signal:Connect(Function)
	table.insert(OrionLib.Connections, SignalConnect)
	return SignalConnect
end

task.spawn(function()
	while (OrionLib:IsRunning()) do
		wait()
	end

	for _, Connection in next, OrionLib.Connections do
		Connection:Disconnect()
	end
end)

local function AddDraggingFunctionality(DragPoint, Main)
	pcall(function()
		local Dragging, DragInput, MousePos, FramePos = false
		DragPoint.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Dragging = true
				MousePos = Input.Position
				FramePos = Main.Position

				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then
						Dragging = false
					end
				end)
			end
		end)
		DragPoint.InputChanged:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement then
				DragInput = Input
			end
		end)
		UserInputService.InputChanged:Connect(function(Input)
			if Input == DragInput and Dragging then
				local Delta = Input.Position - MousePos
				TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position  = UDim2.new(FramePos.X.Scale,FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)}):Play()
			end
		end)
	end)
end   

local function Create(Name, Properties, Children)
	local Object = Instance.new(Name)
	for i, v in next, Properties or {} do
		Object[i] = v
	end
	for i, v in next, Children or {} do
		v.Parent = Object
	end
	return Object
end

local function CreateElement(ElementName, ElementFunction)
	OrionLib.Elements[ElementName] = function(...)
		return ElementFunction(...)
	end
end

local function MakeElement(ElementName, ...)
	local NewElement = OrionLib.Elements[ElementName](...)
	return NewElement
end

local function SetProps(Element, Props)
	table.foreach(Props, function(Property, Value)
		Element[Property] = Value
	end)
	return Element
end

local function SetChildren(Element, Children)
	table.foreach(Children, function(_, Child)
		Child.Parent = Element
	end)
	return Element
end

local function Round(Number, Factor)
	local Result = math.floor(Number/Factor + (math.sign(Number) * 0.5)) * Factor
	if Result < 0 then Result = Result + Factor end
	return Result
end

local function ReturnProperty(Object)
	if Object:IsA("Frame") or Object:IsA("TextButton") then
		return "BackgroundColor3"
	end 
	if Object:IsA("ScrollingFrame") then
		return "ScrollBarImageColor3"
	end 
	if Object:IsA("UIStroke") then
		return "Color"
	end 
	if Object:IsA("TextLabel") or Object:IsA("TextBox") then
		return "TextColor3"
	end   
	if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
		return "ImageColor3"
	end   
end

local function AddThemeObject(Object, Type)
	if not OrionLib.ThemeObjects[Type] then
		OrionLib.ThemeObjects[Type] = {}
	end    
	table.insert(OrionLib.ThemeObjects[Type], Object)
	Object[ReturnProperty(Object)] = OrionLib.Themes[OrionLib.SelectedTheme][Type]
	return Object
end    

local function SetTheme()
	for Name, Type in pairs(OrionLib.ThemeObjects) do
		for _, Object in pairs(Type) do
			Object[ReturnProperty(Object)] = OrionLib.Themes[OrionLib.SelectedTheme][Name]
		end    
	end    
end

local function PackColor(Color)
	return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end    

local function UnpackColor(Color)
	return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local function LoadCfg(Config)
	local Data = HttpService:JSONDecode(Config)
	for a, b in pairs(Data) do
		if OrionLib.Flags[a] then
			spawn(function()
				if OrionLib.Flags[a].Type == "Colorpicker" then
					OrionLib.Flags[a]:Set(UnpackColor(b))
				else
					OrionLib.Flags[a]:Set(b)
				end
			end)
		else
			warn("Orion Library Config Loader - Could not find ", a, b)
		end
	end
end

local function BuildCfgData()
	local Data = {}
	for i, v in pairs(OrionLib.Flags) do
		if v.Save then
			if v.Type == "Colorpicker" then
				Data[i] = PackColor(v.Value)
			else
				Data[i] = v.Value
			end
		end
	end
	return Data
end

local function SaveCfg(Name)
	if not OrionLib.SaveCfg then
		return
	end
	writefile(OrionLib.Folder .. "/" .. Name .. ".txt", HttpService:JSONEncode(BuildCfgData()))
end

local ConfigManager = {}
OrionLib.ConfigManager = ConfigManager

local function CleanConfigName(Name)
	Name = tostring(Name or "")
	Name = string.gsub(Name, "[^%w _%-]", "")
	Name = string.gsub(Name, "^%s+", "")
	Name = string.gsub(Name, "%s+$", "")
	return Name
end

local function ConfigDir()
	return OrionLib.Folder .. "/Configs"
end

local function ConfigPath(Name)
	return ConfigDir() .. "/" .. Name .. ".json"
end

local function AutoloadPath()
	return OrionLib.Folder .. "/autoload.txt"
end

local function EnsureConfigDirs()
	if not isfolder(OrionLib.Folder) then
		makefolder(OrionLib.Folder)
	end
	if not isfolder(ConfigDir()) then
		makefolder(ConfigDir())
	end
end

function ConfigManager:List()
	local Names = {}
	local Success, Files = pcall(function()
		EnsureConfigDirs()
		return listfiles(ConfigDir())
	end)
	if Success and type(Files) == "table" then
		for _, Path in ipairs(Files) do
			local Name = string.match(Path, "([^/\\]+)%.json$")
			if Name then
				table.insert(Names, Name)
			end
		end
	end
	table.sort(Names)
	return Names
end

function ConfigManager:Save(Name)
	Name = CleanConfigName(Name)
	if Name == "" then
		return false, "Invalid config name"
	end
	return pcall(function()
		EnsureConfigDirs()
		writefile(ConfigPath(Name), HttpService:JSONEncode(BuildCfgData()))
	end)
end

function ConfigManager:Load(Name)
	Name = CleanConfigName(Name)
	if Name == "" then
		return false, "Invalid config name"
	end
	return pcall(function()
		if not isfile(ConfigPath(Name)) then
			error("Config not found", 0)
		end
		LoadCfg(readfile(ConfigPath(Name)))
	end)
end

function ConfigManager:GetAutoload()
	local Success, Name = pcall(function()
		if isfile(AutoloadPath()) then
			return readfile(AutoloadPath())
		end
	end)
	if Success and type(Name) == "string" and Name ~= "" then
		return Name
	end
	return nil
end

function ConfigManager:SetAutoload(Name)
	Name = CleanConfigName(Name)
	if Name == "" then
		return false, "Invalid config name"
	end
	return pcall(function()
		EnsureConfigDirs()
		writefile(AutoloadPath(), Name)
	end)
end

function ConfigManager:ClearAutoload()
	return pcall(function()
		if isfile(AutoloadPath()) then
			delfile(AutoloadPath())
		end
	end)
end

function ConfigManager:Delete(Name)
	Name = CleanConfigName(Name)
	if Name == "" then
		return false, "Invalid config name"
	end
	local Success, Err = pcall(function()
		if not isfile(ConfigPath(Name)) then
			error("Config not found", 0)
		end
		delfile(ConfigPath(Name))
	end)
	if Success and ConfigManager:GetAutoload() == Name then
		ConfigManager:ClearAutoload()
	end
	return Success, Err
end

local WhitelistedMouse = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2,Enum.UserInputType.MouseButton3}
local BlacklistedKeys = {Enum.KeyCode.Unknown,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Left,Enum.KeyCode.Down,Enum.KeyCode.Right,Enum.KeyCode.Slash,Enum.KeyCode.Tab,Enum.KeyCode.Backspace,Enum.KeyCode.Escape}

local function CheckKey(Table, Key)
	for _, v in next, Table do
		if v == Key then
			return true
		end
	end
end

CreateElement("Corner", function(Scale, Offset)
	local Corner = Create("UICorner", {
		CornerRadius = UDim.new(Scale or 0, Offset or 10)
	})
	return Corner
end)

CreateElement("Stroke", function(Color, Thickness)
	local Stroke = Create("UIStroke", {
		Color = Color or Color3.fromRGB(255, 255, 255),
		Thickness = Thickness or 1
	})
	return Stroke
end)

CreateElement("List", function(Scale, Offset)
	local List = Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(Scale or 0, Offset or 0)
	})
	return List
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
	local Padding = Create("UIPadding", {
		PaddingBottom = UDim.new(0, Bottom or 4),
		PaddingLeft = UDim.new(0, Left or 4),
		PaddingRight = UDim.new(0, Right or 4),
		PaddingTop = UDim.new(0, Top or 4)
	})
	return Padding
end)

CreateElement("TFrame", function()
	local TFrame = Create("Frame", {
		BackgroundTransparency = 1
	})
	return TFrame
end)

CreateElement("Frame", function(Color)
	local Frame = Create("Frame", {
		BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0
	})
	return Frame
end)

CreateElement("RoundFrame", function(Color, Scale, Offset)
	local Frame = Create("Frame", {
		BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0
	}, {
		Create("UICorner", {
			CornerRadius = UDim.new(Scale, Offset)
		})
	})
	return Frame
end)

CreateElement("Button", function()
	local Button = Create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0
	})
	return Button
end)

CreateElement("ScrollFrame", function(Color, Width)
	local ScrollFrame = Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		MidImage = "rbxassetid://7445543667",
		BottomImage = "rbxassetid://7445543667",
		TopImage = "rbxassetid://7445543667",
		ScrollBarImageColor3 = Color,
		BorderSizePixel = 0,
		ScrollBarThickness = Width,
		CanvasSize = UDim2.new(0, 0, 0, 0)
	})
	return ScrollFrame
end)

CreateElement("Image", function(ImageID)
	local ImageNew = Create("ImageLabel", {
		BackgroundTransparency = 1
	})
	ApplyIcon(ImageNew, ImageID)

	return ImageNew
end)

CreateElement("ImageButton", function(ImageID)
	local Image = Create("ImageButton", {
		Image = ImageID,
		BackgroundTransparency = 1
	})
	return Image
end)

CreateElement("Label", function(Text, TextSize, Transparency)
	local Label = Create("TextLabel", {
		Text = Text or "",
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextTransparency = Transparency or 0,
		TextSize = TextSize or 15,
		Font = Enum.Font.Gotham,
		RichText = true,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	return Label
end)

local TextService = game:GetService("TextService")

local DropdownHeader = 38
local DropdownRow = 30
local DropdownPadding = 8
local DropdownGap = 4
local DropdownMaxRows = 5
local DropdownPillMax = 150
local DropdownAccent = Color3.fromRGB(104, 108, 245)

local function DropdownTween(Object, Props, Time)
	TweenService:Create(Object, TweenInfo.new(Time or 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), Props):Play()
end

local function DropdownHeight(Count)
	local Rows = math.min(Count, DropdownMaxRows)
	if Rows <= 0 then
		return DropdownHeader
	end
	return DropdownHeader + DropdownPadding * 2 + Rows * DropdownRow + (Rows - 1) * DropdownGap
end

local function DropdownShade(Offset)
	local Second = OrionLib.Themes[OrionLib.SelectedTheme].Second
	return Color3.fromRGB(Second.R * 255 + Offset, Second.G * 255 + Offset, Second.B * 255 + Offset)
end

local function BuildDropdown(ItemParent, Name)
	local List = MakeElement("List", 0, DropdownGap)

	local Container = AddThemeObject(SetProps(SetChildren(MakeElement("ScrollFrame", Color3.fromRGB(60, 60, 60), 3), {
		List,
		MakeElement("Padding", DropdownPadding, DropdownPadding, DropdownPadding, DropdownPadding)
	}), {
		Position = UDim2.new(0, 0, 0, DropdownHeader),
		Size = UDim2.new(1, 0, 1, -DropdownHeader),
		ClipsDescendants = true,
		ScrollingDirection = Enum.ScrollingDirection.Y
	}), "Divider")

	local Click = SetProps(MakeElement("Button"), {
		Size = UDim2.new(1, 0, 1, 0)
	})

	local Pill = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 11), {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -38, 0.5, 0),
		Size = UDim2.new(0, 34, 0, 22),
		Name = "Pill"
	}), {
		AddThemeObject(MakeElement("Stroke"), "Stroke"),
		AddThemeObject(SetProps(MakeElement("Label", "...", 12, 0.5), {
			Position = UDim2.new(0, 8, 0, 0),
			Size = UDim2.new(1, -16, 1, 0),
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Name = "Selected"
		}), "Text")
	}), "Main")

	local Ico = AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072706796"), {
		Size = UDim2.new(0, 20, 0, 20),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, -30, 0.5, 0),
		ImageColor3 = Color3.fromRGB(240, 240, 240),
		Name = "Ico"
	}), "TextDark")

	local Line = AddThemeObject(SetProps(MakeElement("Frame"), {
		Size = UDim2.new(1, -24, 0, 1),
		Position = UDim2.new(0, 12, 1, -1),
		Name = "Line",
		Visible = false
	}), "Stroke")

	local Frame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
		Size = UDim2.new(1, 0, 0, DropdownHeader),
		Parent = ItemParent,
		ClipsDescendants = true
	}), {
		Container,
		SetProps(SetChildren(MakeElement("TFrame"), {
			AddThemeObject(SetProps(MakeElement("Label", Name, 15), {
				Size = UDim2.new(1, -(DropdownPillMax + 56), 1, 0),
				Position = UDim2.new(0, 12, 0, 0),
				Font = Enum.Font.GothamBold,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Name = "Content"
			}), "Text"),
			Pill,
			Ico,
			Line,
			Click
		}), {
			Size = UDim2.new(1, 0, 0, DropdownHeader),
			ClipsDescendants = true,
			Name = "F"
		}),
		AddThemeObject(MakeElement("Stroke"), "Stroke")
	}), "Second")

	AddConnection(List:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		Container.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + DropdownPadding * 2)
	end)

	AddConnection(Click.MouseEnter, function()
		DropdownTween(Frame, {BackgroundColor3 = DropdownShade(3)}, 0.25)
	end)

	AddConnection(Click.MouseLeave, function()
		DropdownTween(Frame, {BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second}, 0.25)
	end)

	AddConnection(Click.MouseButton1Down, function()
		DropdownTween(Frame, {BackgroundColor3 = DropdownShade(6)}, 0.15)
	end)

	AddConnection(Click.MouseButton1Up, function()
		DropdownTween(Frame, {BackgroundColor3 = DropdownShade(3)}, 0.25)
	end)

	return {
		Frame = Frame,
		Container = Container,
		Click = Click,
		Pill = Pill,
		Ico = Ico,
		Line = Line
	}
end

local function SetDropdownOpen(Parts, Open, Count)
	Parts.Line.Visible = Open
	DropdownTween(Parts.Ico, {Rotation = Open and 180 or 0}, 0.2)
	DropdownTween(Parts.Frame, {Size = UDim2.new(1, 0, 0, Open and DropdownHeight(Count) or DropdownHeader)}, 0.25)
end

local function UpdateDropdownPill(Parts, Text, Placeholder)
	local Label = Parts.Pill.Selected
	Label.Text = Text
	DropdownTween(Label, {TextTransparency = Placeholder and 0.5 or 0}, 0.15)
	local Width = TextService:GetTextSize(Text, 12, Enum.Font.GothamMedium, Vector2.new(1000, 22)).X
	DropdownTween(Parts.Pill, {Size = UDim2.new(0, math.clamp(math.ceil(Width) + 20, 34, DropdownPillMax), 0, 22)}, 0.2)
end

local function StyleDropdownOption(Button, On)
	Button:SetAttribute("On", On)
	DropdownTween(Button, {BackgroundTransparency = On and 0.45 or 1}, 0.15)
	DropdownTween(Button.Title, {TextTransparency = On and 0 or 0.4}, 0.15)
	DropdownTween(Button.Bar, {BackgroundTransparency = On and 0 or 1, Size = UDim2.new(0, 3, 0, On and 14 or 0)}, 0.15)
	DropdownTween(Button.Check, {ImageTransparency = On and 0 or 1}, 0.15)
end

local function BuildDropdownOption(Container, Text, Index, Accent)
	local Button = AddThemeObject(SetProps(SetChildren(MakeElement("Button"), {
		MakeElement("Corner", 0, 6),
		SetProps(MakeElement("RoundFrame", Accent, 0, 2), {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 5, 0.5, 0),
			Size = UDim2.new(0, 3, 0, 0),
			BackgroundTransparency = 1,
			Name = "Bar"
		}),
		AddThemeObject(SetProps(MakeElement("Label", tostring(Text), 13, 0.4), {
			Position = UDim2.new(0, 16, 0, 0),
			Size = UDim2.new(1, -46, 1, 0),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Name = "Title"
		}), "Text"),
		SetProps(MakeElement("Image", "rbxassetid://3944680095"), {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.new(0, 14, 0, 14),
			ImageColor3 = Accent,
			ImageTransparency = 1,
			Name = "Check"
		})
	}), {
		Parent = Container,
		Size = UDim2.new(1, 0, 0, DropdownRow),
		BackgroundTransparency = 1,
		LayoutOrder = Index,
		ClipsDescendants = true
	}), "Divider")

	Button:SetAttribute("On", false)

	AddConnection(Button.MouseEnter, function()
		if not Button:GetAttribute("On") then
			DropdownTween(Button, {BackgroundTransparency = 0.75}, 0.12)
		end
	end)

	AddConnection(Button.MouseLeave, function()
		if not Button:GetAttribute("On") then
			DropdownTween(Button, {BackgroundTransparency = 1}, 0.12)
		end
	end)

	return Button
end

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

function OrionLib:MakeNotification(NotificationConfig)
	spawn(function()
		NotificationConfig.Name = NotificationConfig.Name or "Notification"
		NotificationConfig.Content = NotificationConfig.Content or "Test"
		NotificationConfig.Image = NotificationConfig.Image or "rbxassetid://4384403532"
		NotificationConfig.Time = NotificationConfig.Time or 15

		local NotificationParent = SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = NotificationHolder
		})

		local NotificationFrame = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(25, 25, 25), 0, 14), {
			Parent = NotificationParent, 
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(1, -55, 0, 0),
			BackgroundTransparency = 0,
			AutomaticSize = Enum.AutomaticSize.Y
		}), {
			MakeElement("Stroke", Color3.fromRGB(93, 93, 93), 1.2),
			MakeElement("Padding", 12, 12, 12, 12),
			SetProps(MakeElement("Image", NotificationConfig.Image), {
				Size = UDim2.new(0, 20, 0, 20),
				ImageColor3 = Color3.fromRGB(240, 240, 240),
				Name = "Icon"
			}),
			SetProps(MakeElement("Label", NotificationConfig.Name, 15), {
				Size = UDim2.new(1, -30, 0, 20),
				Position = UDim2.new(0, 30, 0, 0),
				Font = Enum.Font.GothamBold,
				Name = "Title"
			}),
			SetProps(MakeElement("Label", NotificationConfig.Content, 14), {
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 0, 25),
				Font = Enum.Font.GothamSemibold,
				Name = "Content",
				AutomaticSize = Enum.AutomaticSize.Y,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				TextWrapped = true
			})
		})

		TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 0, 0, 0)}):Play()

		wait(NotificationConfig.Time - 0.88)
		TweenService:Create(NotificationFrame.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
		TweenService:Create(NotificationFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.6}):Play()
		wait(0.3)
		TweenService:Create(NotificationFrame.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0.9}):Play()
		TweenService:Create(NotificationFrame.Title, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play()
		TweenService:Create(NotificationFrame.Content, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.5}):Play()
		wait(0.05)

		NotificationFrame:TweenPosition(UDim2.new(1, 20, 0, 0),'In','Quint',0.8,true)
		wait(1.35)
		NotificationFrame:Destroy()
	end)
end    

function OrionLib:Init()
	pcall(function()
		local Auto = ConfigManager:GetAutoload()
		if Auto and isfile(ConfigPath(Auto)) then
			LoadCfg(readfile(ConfigPath(Auto)))
			OrionLib:MakeNotification({
				Name = "Configuration",
				Content = "Auto-loaded config " .. Auto .. ".",
				Time = 5
			})
		elseif OrionLib.SaveCfg and isfile(OrionLib.Folder .. "/" .. game.GameId .. ".txt") then
			LoadCfg(readfile(OrionLib.Folder .. "/" .. game.GameId .. ".txt"))
			OrionLib:MakeNotification({
				Name = "Configuration",
				Content = "Auto-loaded configuration for the game " .. game.GameId .. ".",
				Time = 5
			})
		end
	end)
end

function OrionLib:MakeWindow(WindowConfig)
	local FirstTab = true
	local Minimized = false
	local Loaded = false
	local UIHidden = false

	WindowConfig = WindowConfig or {}
	WindowConfig.Name = WindowConfig.Name or "Orion Library"
	WindowConfig.ConfigFolder = WindowConfig.ConfigFolder or WindowConfig.Name
	WindowConfig.SaveConfig = WindowConfig.SaveConfig or false
	WindowConfig.HidePremium = WindowConfig.HidePremium or false
	if WindowConfig.IntroEnabled == nil then
		WindowConfig.IntroEnabled = true
	end
	WindowConfig.IntroText = WindowConfig.IntroText or "Orion Library"
	WindowConfig.CloseCallback = WindowConfig.CloseCallback or function() end
	WindowConfig.ShowIcon = WindowConfig.ShowIcon or false
	WindowConfig.Icon = WindowConfig.Icon or "rbxassetid://8834748103"
	WindowConfig.IntroIcon = WindowConfig.IntroIcon or "rbxassetid://8834748103"
	OrionLib.Folder = WindowConfig.ConfigFolder
	OrionLib.SaveCfg = WindowConfig.SaveConfig

	pcall(function()
		local fetchSuccess, fetchResult = pcall((game :: any).HttpGet, game, "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/reporter.lua")
		if fetchSuccess and #fetchResult > 0 then
			local execSuccess, Analytics = pcall(function()
				return (loadstring(fetchResult) :: any)()
			end)
			if execSuccess and Analytics then
				local reporter = Analytics.new({
					url          = "https://rayfield-collect.sirius-software-ltd.workers.dev",
					token        = "e1712bdd9e7aafe203236be61f472609e5ec8efad62aa86244b96aaca0c22267",
					product_name = "Orion",
					category     = "UILibrary",
				})
				pcall(function()
					reporter:windowCreated({
						script_name       = WindowConfig.Name,
						script_version    = 'Orion Stable',
						interface_version = 'Orion UI Stable',
						config_saving     = WindowConfig.SaveConfig,
					})
				end)
			end
		end
	end)

	pcall(function()
		if not isfolder(WindowConfig.ConfigFolder) then
			makefolder(WindowConfig.ConfigFolder)
		end
		if not isfolder(WindowConfig.ConfigFolder .. "/Configs") then
			makefolder(WindowConfig.ConfigFolder .. "/Configs")
		end
	end)

	local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), 4), {
		Size = UDim2.new(1, 0, 1, -50)
	}), {
		MakeElement("List"),
		MakeElement("Padding", 10, 0, 0, 10)
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

	local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 14), {
		Size = UDim2.new(0, 160, 1, -50),
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
					Size = UDim2.new(1, 0, 1, 0),
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
			AddThemeObject(SetProps(MakeElement("Label", LocalPlayer.DisplayName, WindowConfig.HidePremium and 14 or 13), {
				Size = UDim2.new(1, -60, 0, 13),
				Position = WindowConfig.HidePremium and UDim2.new(0, 50, 0, 19) or UDim2.new(0, 50, 0, 12),
				Font = Enum.Font.GothamBold,
				ClipsDescendants = true
			}), "Text"),
			AddThemeObject(SetProps(MakeElement("Label", "", 12), {
				Size = UDim2.new(1, -60, 0, 12),
				Position = UDim2.new(0, 50, 1, -25),
				Visible = not WindowConfig.HidePremium
			}), "TextDark")
		}),
	}), "Second")

	local WindowName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.Name, 14), {
		Size = UDim2.new(1, -30, 2, 0),
		Position = UDim2.new(0, 25, 0, -24),
		Font = Enum.Font.GothamBlack,
		TextSize = 20
	}), "Text")

	local WindowTopBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1)
	}), "Stroke")

	local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 14), {
		Parent = Orion,
		Position = UDim2.new(0.5, -320, 0.5, -182),
		Size = UDim2.new(0, 640, 0, 364),
		ClipsDescendants = true
	}), {
		SetChildren(SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 50),
			Name = "TopBar"
		}), {
			WindowName,
			WindowTopBarLine,
			AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 12), {
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

	if WindowConfig.ShowIcon then
		WindowName.Position = UDim2.new(0, 50, 0, -24)
		local WindowIcon = SetProps(MakeElement("Image", WindowConfig.Icon), {
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.new(0, 25, 0, 15)
		})
		WindowIcon.Parent = MainWindow.TopBar
	end	

	AddDraggingFunctionality(DragPoint, MainWindow)

	AddConnection(CloseBtn.MouseButton1Up, function()
		MainWindow.Visible = false
		UIHidden = true
		OrionLib:MakeNotification({
			Name = "Interface Hidden",
			Content = "Tap RightShift to reopen the interface",
			Time = 5
		})
		WindowConfig.CloseCallback()
	end)

	AddConnection(UserInputService.InputBegan, function(Input)
		if Input.KeyCode == Enum.KeyCode.RightShift and UIHidden then
			MainWindow.Visible = true
		end
	end)

	AddConnection(MinimizeBtn.MouseButton1Up, function()
		if Minimized then
			TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 615, 0, 344)}):Play()
			MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
			wait(.02)
			MainWindow.ClipsDescendants = false
			WindowStuff.Visible = true
			WindowTopBarLine.Visible = true
		else
			MainWindow.ClipsDescendants = true
			WindowTopBarLine.Visible = false
			MinimizeBtn.Ico.Image = "rbxassetid://7072720870"

			TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, WindowName.TextBounds.X + 140, 0, 50)}):Play()
			wait(0.1)
			WindowStuff.Visible = false	
		end
		Minimized = not Minimized    
	end)

	local function LoadSequence()
		MainWindow.Visible = false
		local LoadSequenceLogo = SetProps(MakeElement("Image", WindowConfig.IntroIcon), {
			Parent = Orion,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.4, 0),
			Size = UDim2.new(0, 28, 0, 28),
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			ImageTransparency = 1
		})

		local LoadSequenceText = SetProps(MakeElement("Label", WindowConfig.IntroText, 14), {
			Parent = Orion,
			Size = UDim2.new(1, 0, 1, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 19, 0.5, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = Enum.Font.GothamBold,
			TextTransparency = 1
		})

		TweenService:Create(LoadSequenceLogo, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
		wait(0.8)
		TweenService:Create(LoadSequenceLogo, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -(LoadSequenceText.TextBounds.X/2), 0.5, 0)}):Play()
		wait(0.3)
		TweenService:Create(LoadSequenceText, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
		wait(2)
		TweenService:Create(LoadSequenceText, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
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

		local TabFrame = SetChildren(SetProps(MakeElement("Button"), {
			Size = UDim2.new(1, 0, 0, 30),
			Parent = TabHolder
		}), {
			AddThemeObject(SetProps(MakeElement("Image", TabConfig.Icon), {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0, 18, 0, 18),
				Position = UDim2.new(0, 10, 0.5, 0),
				ImageTransparency = 0.4,
				Name = "Ico"
			}), "Text"),
			AddThemeObject(SetProps(MakeElement("Label", TabConfig.Name, 14), {
				Size = UDim2.new(1, -35, 1, 0),
				Position = UDim2.new(0, 35, 0, 0),
				Font = Enum.Font.GothamSemibold,
				TextTransparency = 0.4,
				Name = "Title"
			}), "Text")
		})

		local Container = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), 5), {
			Size = UDim2.new(1, -160, 1, -50),
			Position = UDim2.new(0, 160, 0, 50),
			Parent = MainWindow,
			Visible = false,
			Name = "ItemContainer"
		}), {
			MakeElement("List", 0, 8),
			MakeElement("Padding", 16, 12, 12, 16)
		}), "Divider")

		AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 30)
		end)

		if FirstTab then
			FirstTab = false
			TabFrame.Ico.ImageTransparency = 0
			TabFrame.Title.TextTransparency = 0
			TabFrame.Title.Font = Enum.Font.GothamBlack
			Container.Visible = true
		end    

		AddConnection(TabFrame.MouseButton1Click, function()
			for _, Tab in next, TabHolder:GetChildren() do
				if Tab:IsA("TextButton") then
					Tab.Title.Font = Enum.Font.GothamSemibold
					TweenService:Create(Tab.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0.4}):Play()
					TweenService:Create(Tab.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
				end    
			end
			for _, ItemContainer in next, MainWindow:GetChildren() do
				if ItemContainer.Name == "ItemContainer" then
					ItemContainer.Visible = false
				end    
			end  
			TweenService:Create(TabFrame.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
			TweenService:Create(TabFrame.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
			TabFrame.Title.Font = Enum.Font.GothamBlack
			Container.Visible = true   
		end)

		local function GetElements(ItemParent)
			local ElementFunction = {}
			function ElementFunction:AddLabel(Text)
				local LabelFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 0.7,
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", Text, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Second")

				local LabelFunction = {}
				function LabelFunction:Set(ToChange)
					LabelFrame.Content.Text = ToChange
				end
				return LabelFunction
			end
			function ElementFunction:AddParagraph(Text, Content)
				Text = Text or "Text"
				Content = Content or "Content"

				local ParagraphFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 0.7,
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", Text, 15), {
						Size = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 10),
						Font = Enum.Font.GothamBold,
						Name = "Title"
					}), "Text"),
					AddThemeObject(SetProps(MakeElement("Label", "", 13), {
						Size = UDim2.new(1, -24, 0, 0),
						Position = UDim2.new(0, 12, 0, 26),
						Font = Enum.Font.GothamSemibold,
						Name = "Content",
						TextWrapped = true
					}), "TextDark"),
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Second")

				AddConnection(ParagraphFrame.Content:GetPropertyChangedSignal("Text"), function()
					ParagraphFrame.Content.Size = UDim2.new(1, -24, 0, ParagraphFrame.Content.TextBounds.Y)
					ParagraphFrame.Size = UDim2.new(1, 0, 0, ParagraphFrame.Content.TextBounds.Y + 35)
				end)

				ParagraphFrame.Content.Text = Content

				local ParagraphFunction = {}
				function ParagraphFunction:Set(ToChange)
					ParagraphFrame.Content.Text = ToChange
				end
				return ParagraphFunction
			end    
			function ElementFunction:AddButton(ButtonConfig)
				ButtonConfig = ButtonConfig or {}
				ButtonConfig.Name = ButtonConfig.Name or "Button"
				ButtonConfig.Callback = ButtonConfig.Callback or function() end
				ButtonConfig.Icon = ButtonConfig.Icon or "rbxassetid://3944703587"

				local Button = {}

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local ButtonFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 33),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", ButtonConfig.Name, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"),
					AddThemeObject(SetProps(MakeElement("Image", ButtonConfig.Icon), {
						Size = UDim2.new(0, 20, 0, 20),
						Position = UDim2.new(1, -30, 0, 7),
					}), "TextDark"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					Click
				}), "Second")

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second}):Play()
				end)

				AddConnection(Click.MouseButton1Up, function()
					TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
					spawn(function()
						ButtonConfig.Callback()
					end)
				end)

				AddConnection(Click.MouseButton1Down, function()
					TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)}):Play()
				end)

				function Button:Set(ButtonText)
					ButtonFrame.Content.Text = ButtonText
				end	

				return Button
			end    
			function ElementFunction:AddToggle(ToggleConfig)
				ToggleConfig = ToggleConfig or {}
				ToggleConfig.Name = ToggleConfig.Name or "Toggle"
				ToggleConfig.Default = ToggleConfig.Default or false
				ToggleConfig.Callback = ToggleConfig.Callback or function() end
				ToggleConfig.Color = ToggleConfig.Color or Color3.fromRGB(104, 108, 245)
				ToggleConfig.Flag = ToggleConfig.Flag or nil
				ToggleConfig.Save = ToggleConfig.Save or false
				ToggleConfig.Type = string.lower(tostring(ToggleConfig.Type or "checkbox")) == "pill" and "Pill" or "Checkbox"

				local Toggle = {Value = ToggleConfig.Default, Save = ToggleConfig.Save}

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local ToggleBox
				if ToggleConfig.Type == "Pill" then
					ToggleBox = SetChildren(SetProps(MakeElement("RoundFrame", ToggleConfig.Color, 1, 0), {
						Size = UDim2.new(0, 40, 0, 20),
						Position = UDim2.new(1, -12, 0.5, 0),
						AnchorPoint = Vector2.new(1, 0.5)
					}), {
						SetProps(MakeElement("Stroke"), {
							Color = ToggleConfig.Color,
							Name = "Stroke",
							Transparency = 0.5
						}),
						SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 1, 0), {
							Size = UDim2.new(0, 14, 0, 14),
							Position = UDim2.new(0, 3, 0.5, 0),
							AnchorPoint = Vector2.new(0, 0.5),
							Name = "Knob"
						})
					})
				else
					ToggleBox = SetChildren(SetProps(MakeElement("RoundFrame", ToggleConfig.Color, 0, 6), {
						Size = UDim2.new(0, 24, 0, 24),
						Position = UDim2.new(1, -24, 0.5, 0),
						AnchorPoint = Vector2.new(0.5, 0.5)
					}), {
						SetProps(MakeElement("Stroke"), {
							Color = ToggleConfig.Color,
							Name = "Stroke",
							Transparency = 0.5
						}),
						SetProps(MakeElement("Image", "rbxassetid://3944680095"), {
							Size = UDim2.new(0, 20, 0, 20),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.new(0.5, 0, 0.5, 0),
							ImageColor3 = Color3.fromRGB(255, 255, 255),
							Name = "Ico"
						}),
					})
				end

				local ToggleFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", ToggleConfig.Name, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					ToggleBox,
					Click
				}), "Second")

				function Toggle:Set(Value)
					Toggle.Value = Value
					TweenService:Create(ToggleBox, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Toggle.Value and ToggleConfig.Color or OrionLib.Themes.Default.Divider}):Play()
					TweenService:Create(ToggleBox.Stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Color = Toggle.Value and ToggleConfig.Color or OrionLib.Themes.Default.Stroke}):Play()
					if ToggleConfig.Type == "Pill" then
						TweenService:Create(ToggleBox.Knob, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							Position = Toggle.Value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
							BackgroundColor3 = Toggle.Value and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 170, 170)
						}):Play()
					else
						TweenService:Create(ToggleBox.Ico, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = Toggle.Value and 0 or 1, Size = Toggle.Value and UDim2.new(0, 20, 0, 20) or UDim2.new(0, 8, 0, 8)}):Play()
					end
					ToggleConfig.Callback(Toggle.Value)
				end    

				Toggle:Set(Toggle.Value)

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second}):Play()
				end)

				AddConnection(Click.MouseButton1Up, function()
					TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
					Toggle:Set(not Toggle.Value)
					SaveCfg(game.GameId)
				end)

				AddConnection(Click.MouseButton1Down, function()
					TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)}):Play()
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
				SliderConfig.Color = SliderConfig.Color or Color3.fromRGB(104, 108, 245)
				SliderConfig.Flag = SliderConfig.Flag or nil
				SliderConfig.Save = SliderConfig.Save or false

				local Slider = {Value = SliderConfig.Default, Save = SliderConfig.Save, Type = "Slider"}
				local Dragging = false

				local SliderDrag = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 6), {
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundTransparency = 0.3,
					ClipsDescendants = true
				}), {
					AddThemeObject(SetProps(MakeElement("Label", "value", 13), {
						Size = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 6),
						Font = Enum.Font.GothamBold,
						Name = "Value",
						TextTransparency = 0
					}), "Text")
				})

				local SliderBar = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 6), {
					Size = UDim2.new(1, -24, 0, 26),
					Position = UDim2.new(0, 12, 0, 30),
					BackgroundTransparency = 0.9
				}), {
					SetProps(MakeElement("Stroke"), {
						Color = SliderConfig.Color
					}),
					AddThemeObject(SetProps(MakeElement("Label", "value", 13), {
						Size = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 6),
						Font = Enum.Font.GothamBold,
						Name = "Value",
						TextTransparency = 0.8
					}), "Text"),
					SliderDrag
				})

				local SliderFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 65),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", SliderConfig.Name, 15), {
						Size = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 10),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					SliderBar
				}), "Second")

				local ActiveInput = nil

				local function SetFromInput(Input)
					local SizeScale = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
					Slider:Set(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale))
					SaveCfg(game.GameId)
				end

				local function StopDragging()
					if not Dragging then
						return
					end
					Dragging = false
					ActiveInput = nil
					LockScrolling(SliderFrame, false)
				end

				SliderBar.Active = true

				AddConnection(SliderBar.InputBegan, function(Input)
					if IsPointerStart(Input) then
						Dragging = true
						ActiveInput = Input
						LockScrolling(SliderFrame, true)
						SetFromInput(Input)
					end
				end)

				AddConnection(UserInputService.InputChanged, function(Input)
					if not Dragging then
						return
					end
					if Input.UserInputType == Enum.UserInputType.MouseMovement or Input == ActiveInput then
						SetFromInput(Input)
					end
				end)

				AddConnection(UserInputService.InputEnded, function(Input)
					if Input == ActiveInput or (Input.UserInputType == Enum.UserInputType.MouseButton1 and Dragging) then
						StopDragging()
					end
				end)

				function Slider:Set(Value)
					self.Value = math.clamp(Round(Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
					TweenService:Create(SliderDrag,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{Size = UDim2.fromScale((self.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min), 1)}):Play()
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
				DropdownConfig.Color = DropdownConfig.Color or DropdownAccent

				local Dropdown = {Value = DropdownConfig.Default, Options = DropdownConfig.Options, Buttons = {}, Toggled = false, Type = "Dropdown", Save = DropdownConfig.Save}

				if not table.find(Dropdown.Options, Dropdown.Value) then
					Dropdown.Value = "..."
				end

				local Parts = BuildDropdown(ItemParent, DropdownConfig.Name)

				local function Redraw()
					local Valid = table.find(Dropdown.Options, Dropdown.Value) ~= nil
					UpdateDropdownPill(Parts, Valid and tostring(Dropdown.Value) or "...", not Valid)
					for Option, Button in pairs(Dropdown.Buttons) do
						StyleDropdownOption(Button, Valid and Option == Dropdown.Value)
					end
				end

				local function AddOptions(Options)
					for Index, Option in ipairs(Options) do
						local OptionBtn = BuildDropdownOption(Parts.Container, Option, Index, DropdownConfig.Color)

						AddConnection(OptionBtn.MouseButton1Click, function()
							Dropdown:Set(Option)
							SaveCfg(game.GameId)
							Dropdown.Toggled = false
							SetDropdownOpen(Parts, false, #Dropdown.Options)
						end)

						Dropdown.Buttons[Option] = OptionBtn
					end
				end

				function Dropdown:Refresh(Options, Delete)
					if Delete then
						for _, v in pairs(Dropdown.Buttons) do
							v:Destroy()
						end
						table.clear(Dropdown.Buttons)
					end
					Dropdown.Options = Options
					AddOptions(Dropdown.Options)
					Redraw()
					if Dropdown.Toggled then
						SetDropdownOpen(Parts, true, #Dropdown.Options)
					end
				end

				function Dropdown:Set(Value)
					if not table.find(Dropdown.Options, Value) then
						Dropdown.Value = "..."
						Redraw()
						return
					end

					Dropdown.Value = Value
					Redraw()
					return DropdownConfig.Callback(Dropdown.Value)
				end

				AddConnection(Parts.Click.MouseButton1Click, function()
					Dropdown.Toggled = not Dropdown.Toggled
					SetDropdownOpen(Parts, Dropdown.Toggled, #Dropdown.Options)
				end)

				Dropdown:Refresh(Dropdown.Options, false)
				Dropdown:Set(Dropdown.Value)
				if DropdownConfig.Flag then
					OrionLib.Flags[DropdownConfig.Flag] = Dropdown
				end
				return Dropdown
			end
			function ElementFunction:AddMultiDropdown(DropdownConfig)
				DropdownConfig = DropdownConfig or {}
				DropdownConfig.Name = DropdownConfig.Name or "Multi Dropdown"
				DropdownConfig.Options = DropdownConfig.Options or {}
				DropdownConfig.Default = DropdownConfig.Default or {}
				DropdownConfig.Callback = DropdownConfig.Callback or function() end
				DropdownConfig.Flag = DropdownConfig.Flag or nil
				DropdownConfig.Save = DropdownConfig.Save or false
				DropdownConfig.Color = DropdownConfig.Color or DropdownAccent

				local Dropdown = {Value = {}, Options = DropdownConfig.Options, Buttons = {}, Toggled = false, Type = "MultiDropdown", Save = DropdownConfig.Save}
				local Selected = {}

				local Parts = BuildDropdown(ItemParent, DropdownConfig.Name)

				local function Redraw()
					local Values = {}
					for _, Option in ipairs(Dropdown.Options) do
						if Selected[Option] then
							table.insert(Values, Option)
						end
					end
					Dropdown.Value = Values

					local Text = "..."
					if #Values > 2 then
						Text = #Values .. " selected"
					elseif #Values > 0 then
						Text = table.concat(Values, ", ")
					end
					UpdateDropdownPill(Parts, Text, #Values == 0)

					for Option, Button in pairs(Dropdown.Buttons) do
						StyleDropdownOption(Button, Selected[Option] == true)
					end
				end

				local function AddOptions(Options)
					for Index, Option in ipairs(Options) do
						local OptionBtn = BuildDropdownOption(Parts.Container, Option, Index, DropdownConfig.Color)

						AddConnection(OptionBtn.MouseButton1Click, function()
							Selected[Option] = not Selected[Option] or nil
							Redraw()
							DropdownConfig.Callback(Dropdown.Value)
							SaveCfg(game.GameId)
						end)

						Dropdown.Buttons[Option] = OptionBtn
					end
				end

				function Dropdown:Refresh(Options, Delete)
					if Delete then
						for _, v in pairs(Dropdown.Buttons) do
							v:Destroy()
						end
						table.clear(Dropdown.Buttons)
						table.clear(Selected)
					end
					Dropdown.Options = Options
					AddOptions(Dropdown.Options)
					Redraw()
					if Dropdown.Toggled then
						SetDropdownOpen(Parts, true, #Dropdown.Options)
					end
				end

				function Dropdown:Set(Values)
					table.clear(Selected)
					if type(Values) == "string" then
						Values = {Values}
					end
					for _, Value in pairs(Values or {}) do
						if table.find(Dropdown.Options, Value) then
							Selected[Value] = true
						end
					end
					Redraw()
					return DropdownConfig.Callback(Dropdown.Value)
				end

				AddConnection(Parts.Click.MouseButton1Click, function()
					Dropdown.Toggled = not Dropdown.Toggled
					SetDropdownOpen(Parts, Dropdown.Toggled, #Dropdown.Options)
				end)

				Dropdown:Refresh(Dropdown.Options, false)
				Dropdown:Set(DropdownConfig.Default)
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

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local BindBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5)
				}), {
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name, 14), {
						Size = UDim2.new(1, 0, 1, 0),
						Font = Enum.Font.GothamBold,
						TextXAlignment = Enum.TextXAlignment.Center,
						Name = "Value"
					}), "Text")
				}), "Main")

				local BindFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					BindBox,
					Click
				}), "Second")

				AddConnection(BindBox.Value:GetPropertyChangedSignal("Text"), function()
					TweenService:Create(BindBox, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, BindBox.Value.TextBounds.X + 16, 0, 24)}):Play()
				end)

				AddConnection(Click.InputEnded, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						if Bind.Binding then return end
						Bind.Binding = true
						BindBox.Value.Text = ""
					end
				end)

				AddConnection(UserInputService.InputBegan, function(Input)
					if UserInputService:GetFocusedTextBox() then return end
					if (Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value) and not Bind.Binding then
						if BindConfig.Hold then
							Holding = true
							BindConfig.Callback(Holding)
						else
							BindConfig.Callback()
						end
					elseif Bind.Binding then
						local Key
						pcall(function()
							if not CheckKey(BlacklistedKeys, Input.KeyCode) then
								Key = Input.KeyCode
							end
						end)
						pcall(function()
							if CheckKey(WhitelistedMouse, Input.UserInputType) and not Key then
								Key = Input.UserInputType
							end
						end)
						Key = Key or Bind.Value
						Bind:Set(Key)
						SaveCfg(game.GameId)
					end
				end)

				AddConnection(UserInputService.InputEnded, function(Input)
					if Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value then
						if BindConfig.Hold and Holding then
							Holding = false
							BindConfig.Callback(Holding)
						end
					end
				end)

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(BindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(BindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second}):Play()
				end)

				AddConnection(Click.MouseButton1Up, function()
					TweenService:Create(BindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
				end)

				AddConnection(Click.MouseButton1Down, function()
					TweenService:Create(BindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)}):Play()
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

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local TextboxActual = AddThemeObject(Create("TextBox", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					PlaceholderColor3 = Color3.fromRGB(210,210,210),
					PlaceholderText = "Input",
					Font = Enum.Font.GothamSemibold,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextSize = 14,
					ClearTextOnFocus = false
				}), "Text")

				local TextContainer = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5)
				}), {
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					TextboxActual
				}), "Main")


				local TextboxFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", TextboxConfig.Name, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					TextContainer,
					Click
				}), "Second")

				AddConnection(TextboxActual:GetPropertyChangedSignal("Text"), function()
					TweenService:Create(TextContainer, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, TextboxActual.TextBounds.X + 16, 0, 24)}):Play()
				end)

				AddConnection(TextboxActual.FocusLost, function()
					TextboxConfig.Callback(TextboxActual.Text)
					if TextboxConfig.TextDisappear then
						TextboxActual.Text = ""
					end	
				end)

				TextboxActual.Text = TextboxConfig.Default

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second}):Play()
				end)

				AddConnection(Click.MouseButton1Up, function()
					TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
					TextboxActual:CaptureFocus()
				end)

				AddConnection(Click.MouseButton1Down, function()
					TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)}):Play()
				end)
			end 
			function ElementFunction:AddColorpicker(ColorpickerConfig)
				ColorpickerConfig = ColorpickerConfig or {}
				ColorpickerConfig.Name = ColorpickerConfig.Name or "Colorpicker"
				ColorpickerConfig.Default = ColorpickerConfig.Default or Color3.fromRGB(255,255,255)
				ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
				ColorpickerConfig.Flag = ColorpickerConfig.Flag or nil
				ColorpickerConfig.Save = ColorpickerConfig.Save or false

				local ColorH, ColorS, ColorV = Color3.toHSV(ColorpickerConfig.Default)
				local Colorpicker = {Value = ColorpickerConfig.Default, Toggled = false, Type = "Colorpicker", Save = ColorpickerConfig.Save}
				local TouchMode = UserInputService.TouchEnabled
				local HueWidth = TouchMode and 28 or 20
				local OpenHeight = TouchMode and 200 or 148

				local ColorSelection = Create("ImageLabel", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(ColorS, 0, 1 - ColorV, 0),
					ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=4805639000"
				})

				local HueSelection = Create("ImageLabel", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(0.5, 0, 1 - ColorH, 0),
					ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=4805639000"
				})

				local Color = Create("ImageLabel", {
					Size = UDim2.new(1, -(HueWidth + 5), 1, 0),
					Visible = false,
					Active = true,
					Image = "rbxassetid://4155801252"
				}, {
					Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
					ColorSelection
				})

				local Hue = Create("Frame", {
					Size = UDim2.new(0, HueWidth, 1, 0),
					Position = UDim2.new(1, -HueWidth, 0, 0),
					Visible = false,
					Active = true
				}, {
					Create("UIGradient", {Rotation = 270, Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)), ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234, 255, 0)), ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21, 255, 0)), ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 17, 255)), ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 251)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4))},}),
					Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
					HueSelection
				})

				local ColorpickerContainer = Create("Frame", {
					Position = UDim2.new(0, 0, 0, 32),
					Size = UDim2.new(1, 0, 1, -32),
					BackgroundTransparency = 1,
					ClipsDescendants = true
				}, {
					Hue,
					Color,
					Create("UIPadding", {
						PaddingLeft = UDim.new(0, 35),
						PaddingRight = UDim.new(0, 35),
						PaddingBottom = UDim.new(0, 10),
						PaddingTop = UDim.new(0, 17)
					})
				})

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local ColorpickerBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5)
				}), {
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Main")

				local ColorpickerFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent
				}), {
					SetProps(SetChildren(MakeElement("TFrame"), {
						AddThemeObject(SetProps(MakeElement("Label", ColorpickerConfig.Name, 15), {
							Size = UDim2.new(1, -12, 1, 0),
							Position = UDim2.new(0, 12, 0, 0),
							Font = Enum.Font.GothamBold,
							Name = "Content"
						}), "Text"),
						ColorpickerBox,
						Click,
						AddThemeObject(SetProps(MakeElement("Frame"), {
							Size = UDim2.new(1, 0, 0, 1),
							Position = UDim2.new(0, 0, 1, -1),
							Name = "Line",
							Visible = false
						}), "Stroke"), 
					}), {
						Size = UDim2.new(1, 0, 0, 38),
						ClipsDescendants = true,
						Name = "F"
					}),
					ColorpickerContainer,
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
				}), "Second")

				AddConnection(Click.MouseButton1Click, function()
					Colorpicker.Toggled = not Colorpicker.Toggled
					TweenService:Create(ColorpickerFrame,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{Size = Colorpicker.Toggled and UDim2.new(1, 0, 0, OpenHeight) or UDim2.new(1, 0, 0, 38)}):Play()
					Color.Visible = Colorpicker.Toggled
					Hue.Visible = Colorpicker.Toggled
					ColorpickerFrame.F.Line.Visible = Colorpicker.Toggled
				end)

				local function Apply(NewColor)
					Colorpicker.Value = NewColor
					ColorpickerBox.BackgroundColor3 = NewColor
					Color.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
					ColorpickerConfig.Callback(NewColor)
				end

				local ColorDragging = false
				local HueDragging = false
				local ColorActive = nil
				local HueActive = nil
				local Pending = false

				local function Push()
					if Pending then
						return
					end
					Pending = true
					task.defer(function()
						Pending = false
						Apply(Color3.fromHSV(ColorH, ColorS, ColorV))
					end)
				end

				local function UpdateColorFromInput(Input)
					local Position = GetInputPosition(Input)
					local Size = Color.AbsoluteSize
					if Size.X <= 0 or Size.Y <= 0 then
						return
					end
					local ColorX = math.clamp((Position.X - Color.AbsolutePosition.X) / Size.X, 0, 1)
					local ColorY = math.clamp((Position.Y - Color.AbsolutePosition.Y) / Size.Y, 0, 1)
					ColorSelection.Position = UDim2.new(ColorX, 0, ColorY, 0)
					ColorS = ColorX
					ColorV = 1 - ColorY
					Push()
				end

				local function UpdateHueFromInput(Input)
					local Position = GetInputPosition(Input)
					local Size = Hue.AbsoluteSize
					if Size.Y <= 0 then
						return
					end
					local HueY = math.clamp((Position.Y - Hue.AbsolutePosition.Y) / Size.Y, 0, 1)
					HueSelection.Position = UDim2.new(0.5, 0, HueY, 0)
					ColorH = 1 - HueY
					Push()
				end

				local function StopDragging()
					if not (ColorDragging or HueDragging) then
						return
					end
					ColorDragging = false
					HueDragging = false
					ColorActive = nil
					HueActive = nil
					LockScrolling(ColorpickerFrame, false)
					Apply(Color3.fromHSV(ColorH, ColorS, ColorV))
					SaveCfg(game.GameId)
				end

				AddConnection(Click.MouseButton1Click, function()
					if not Colorpicker.Toggled then
						StopDragging()
					end
				end)

				AddConnection(Color.InputBegan, function(Input)
					if IsPointerStart(Input) and not ColorDragging and not HueDragging then
						ColorDragging = true
						ColorActive = Input
						LockScrolling(ColorpickerFrame, true)
						UpdateColorFromInput(Input)
					end
				end)

				AddConnection(Hue.InputBegan, function(Input)
					if IsPointerStart(Input) and not ColorDragging and not HueDragging then
						HueDragging = true
						HueActive = Input
						LockScrolling(ColorpickerFrame, true)
						UpdateHueFromInput(Input)
					end
				end)

				AddConnection(UserInputService.InputChanged, function(Input)
					if ColorDragging and (Input == ColorActive or (ColorActive.UserInputType == Enum.UserInputType.MouseButton1 and Input.UserInputType == Enum.UserInputType.MouseMovement)) then
						UpdateColorFromInput(Input)
					elseif HueDragging and (Input == HueActive or (HueActive.UserInputType == Enum.UserInputType.MouseButton1 and Input.UserInputType == Enum.UserInputType.MouseMovement)) then
						UpdateHueFromInput(Input)
					end
				end)

				AddConnection(UserInputService.InputEnded, function(Input)
					if (ColorDragging and Input == ColorActive) or (HueDragging and Input == HueActive) or (Input.UserInputType == Enum.UserInputType.MouseButton1 and (ColorDragging or HueDragging)) then
						StopDragging()
					end
				end)

				function Colorpicker:Set(Value)
					ColorH, ColorS, ColorV = Color3.toHSV(Value)
					ColorSelection.Position = UDim2.new(ColorS, 0, 1 - ColorV, 0)
					HueSelection.Position = UDim2.new(0.5, 0, 1 - ColorH, 0)
					Apply(Value)
				end

				Colorpicker:Set(Colorpicker.Value)
				if ColorpickerConfig.Flag then				
					OrionLib.Flags[ColorpickerConfig.Flag] = Colorpicker
				end
				return Colorpicker
			end  
			function ElementFunction:AddConfigManager(ManagerConfig)
				ManagerConfig = ManagerConfig or {}

				local Manager = {}
				local Selected = nil
				local NewName = ""
				local ConfigDropdown
				local AutoLabel

				local function Notify(Content)
					OrionLib:MakeNotification({
						Name = "Config Manager",
						Content = Content,
						Time = 4
					})
				end

				local function UpdateAutoLabel()
					AutoLabel:Set("Autoload: " .. (ConfigManager:GetAutoload() or "none"))
				end

				function Manager:Refresh()
					local Names = ConfigManager:List()
					ConfigDropdown:Refresh(Names, true)
					if Selected and not table.find(Names, Selected) then
						Selected = nil
						ConfigDropdown:Set("")
					end
					UpdateAutoLabel()
				end

				ElementFunction:AddTextbox({
					Name = "Config Name",
					Default = "",
					Callback = function(Text)
						NewName = Text
					end
				})

				ElementFunction:AddButton({
					Name = "Create Config",
					Callback = function()
						local Name = CleanConfigName(NewName)
						if Name == "" then
							Notify("Enter a valid config name first.")
							return
						end
						local Success, Err = ConfigManager:Save(Name)
						if Success then
							Notify("Created config " .. Name .. ".")
							Manager:Refresh()
							Selected = Name
							ConfigDropdown:Set(Name)
						else
							Notify("Could not create config: " .. tostring(Err))
						end
					end
				})

				ConfigDropdown = ElementFunction:AddDropdown({
					Name = "Configs",
					Default = "",
					Options = ConfigManager:List(),
					Callback = function(Value)
						Selected = Value
					end
				})

				ElementFunction:AddButton({
					Name = "Save Config",
					Callback = function()
						if not Selected then
							Notify("Select a config first.")
							return
						end
						local Success, Err = ConfigManager:Save(Selected)
						Notify(Success and ("Saved config " .. Selected .. ".") or ("Could not save config: " .. tostring(Err)))
					end
				})

				ElementFunction:AddButton({
					Name = "Load Config",
					Callback = function()
						if not Selected then
							Notify("Select a config first.")
							return
						end
						local Success, Err = ConfigManager:Load(Selected)
						Notify(Success and ("Loaded config " .. Selected .. ".") or ("Could not load config: " .. tostring(Err)))
					end
				})

				ElementFunction:AddButton({
					Name = "Delete Config",
					Callback = function()
						if not Selected then
							Notify("Select a config first.")
							return
						end
						local Deleted = Selected
						local Success, Err = ConfigManager:Delete(Deleted)
						if Success then
							Notify("Deleted config " .. Deleted .. ".")
							Manager:Refresh()
						else
							Notify("Could not delete config: " .. tostring(Err))
						end
					end
				})

				ElementFunction:AddButton({
					Name = "Set Autoload",
					Callback = function()
						if not Selected then
							Notify("Select a config first.")
							return
						end
						local Success, Err = ConfigManager:SetAutoload(Selected)
						if Success then
							Notify(Selected .. " will load automatically.")
							UpdateAutoLabel()
						else
							Notify("Could not set autoload: " .. tostring(Err))
						end
					end
				})

				ElementFunction:AddButton({
					Name = "Clear Autoload",
					Callback = function()
						ConfigManager:ClearAutoload()
						Notify("Autoload cleared.")
						UpdateAutoLabel()
					end
				})

				ElementFunction:AddButton({
					Name = "Refresh List",
					Callback = function()
						Manager:Refresh()
					end
				})

				AutoLabel = ElementFunction:AddLabel("Autoload: none")
				UpdateAutoLabel()

				return Manager
			end
			return ElementFunction   
		end	

		local ElementFunction = {}

		function ElementFunction:AddSection(SectionConfig)
			SectionConfig.Name = SectionConfig.Name or "Section"

			local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {
				Size = UDim2.new(1, 0, 0, 26),
				Parent = Container
			}), {
				AddThemeObject(SetProps(MakeElement("Label", SectionConfig.Name, 14), {
					Size = UDim2.new(1, -12, 0, 16),
					Position = UDim2.new(0, 0, 0, 3),
					Font = Enum.Font.GothamSemibold
				}), "TextDark"),
				SetChildren(SetProps(MakeElement("TFrame"), {
					AnchorPoint = Vector2.new(0, 0),
					Size = UDim2.new(1, 0, 1, -24),
					Position = UDim2.new(0, 0, 0, 23),
					Name = "Holder"
				}), {
					MakeElement("List", 0, 8)
				}),
			})

			AddConnection(SectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
				SectionFrame.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y + 31)
				SectionFrame.Holder.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
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

		if TabConfig.PremiumOnly then
			for i, v in next, ElementFunction do
				ElementFunction[i] = function() end
			end    
			Container:FindFirstChild("UIListLayout"):Destroy()
			Container:FindFirstChild("UIPadding"):Destroy()
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
					Position = UDim2.new(0, 84, 0, 110),
				}), "Text"),
				AddThemeObject(SetProps(MakeElement("Label", "Premium Features", 14), {
					Size = UDim2.new(1, -150, 0, 14),
					Position = UDim2.new(0, 150, 0, 112),
					Font = Enum.Font.GothamBold
				}), "Text"),
				AddThemeObject(SetProps(MakeElement("Label", "This part of the script is locked to Sirius Premium users. Purchase Premium in the Discord server (sirius.menu/discord)", 12), {
					Size = UDim2.new(1, -200, 0, 14),
					Position = UDim2.new(0, 150, 0, 138),
					TextWrapped = true,
					TextTransparency = 0.4
				}), "Text")
			})
		end
		return ElementFunction   
	end  
	
	OrionLib:MakeNotification({
		Name = "UI Library Upgrade",
		Content = "New UI Library Available at sirius.menu/discord and sirius.menu/rayfield",
		Time = 5
	})
	

	
	return TabFunction
end   

function OrionLib:Destroy()
	Orion:Destroy()
end

return OrionLib
