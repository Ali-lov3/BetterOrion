local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ali-lov3/BetterOrion/refs/heads/main/Source.lua"))()

local Window = OrionLib:MakeWindow({
	Name = "Example",
	HidePremium = false,
	SaveConfig = true,
	ConfigFolder = "Example",
	IntroEnabled = false
})

local MainTab = Window:MakeTab({
	Name = "Main",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local VisualTab = Window:MakeTab({
	Name = "Visuals",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local MainSection = MainTab:AddSection({
	Name = "Sliders"
})

MainTab:AddSlider({
	Name = "Walk Speed",
	Min = 16,
	Max = 200,
	Default = 16,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 1,
	ValueName = "studs/s",
	Flag = "WalkSpeed",
	Save = true,
	Callback = function(Value)
		local Character = game.Players.LocalPlayer.Character
		local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		if Humanoid then
			Humanoid.WalkSpeed = Value
		end
	end
})

MainTab:AddSlider({
	Name = "Jump Power",
	Min = 50,
	Max = 300,
	Default = 50,
	Color = Color3.fromRGB(9, 149, 98),
	Increment = 5,
	ValueName = "power",
	Flag = "JumpPower",
	Save = true,
	Callback = function(Value)
		local Character = game.Players.LocalPlayer.Character
		local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		if Humanoid then
			Humanoid.UseJumpPower = true
			Humanoid.JumpPower = Value
		end
	end
})

MainTab:AddSlider({
	Name = "Field Of View",
	Min = 40,
	Max = 120,
	Default = 70,
	Color = Color3.fromRGB(9, 99, 195),
	Increment = 1,
	ValueName = "deg",
	Flag = "FieldOfView",
	Save = true,
	Callback = function(Value)
		workspace.CurrentCamera.FieldOfView = Value
	end
})

local ControlsSection = MainTab:AddSection({
	Name = "Controls"
})

ControlsSection:AddToggle({
	Name = "Example Toggle",
	Default = false,
	Flag = "ExampleToggle",
	Save = true,
	Callback = function(Value)
		print("Toggle:", Value)
	end
})

ControlsSection:AddButton({
	Name = "Notify",
	Callback = function()
		OrionLib:MakeNotification({
			Name = "Hello",
			Content = "Example",
			Time = 5
		})
	end
})

ControlsSection:AddDropdown({
	Name = "Example Dropdown",
	Default = "Option 1",
	Options = {"Option 1", "Option 2", "Option 3"},
	Flag = "ExampleDropdown",
	Save = true,
	Callback = function(Value)
		print("Dropdown:", Value)
	end
})

local ColorSection = VisualTab:AddSection({
	Name = "Colorpickers"
})

VisualTab:AddColorpicker({
	Name = "Accent Color",
	Default = Color3.fromRGB(255, 0, 0),
	Flag = "AccentColor",
	Save = true,
	Callback = function(Value)
		print("Accent:", Value)
	end
})

VisualTab:AddColorpicker({
	Name = "Highlight Color",
	Default = Color3.fromRGB(0, 170, 255),
	Flag = "HighlightColor",
	Save = true,
	Callback = function(Value)
		print("Highlight:", Value)
	end
})

local MixSection = VisualTab:AddSection({
	Name = "Mixed"
})

MixSection:AddSlider({
	Name = "Outline Thickness",
	Min = 1,
	Max = 10,
	Default = 2,
	Color = Color3.fromRGB(255, 170, 0),
	Increment = 1,
	ValueName = "px",
	Flag = "OutlineThickness",
	Save = true,
	Callback = function(Value)
		print("Thickness:", Value)
	end
})

MixSection:AddColorpicker({
	Name = "Outline Color",
	Default = Color3.fromRGB(255, 255, 255),
	Flag = "OutlineColor",
	Save = true,
	Callback = function(Value)
		print("Outline:", Value)
	end
})

OrionLib:Init()
