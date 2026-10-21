local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ali-lov3/BetterOrion/refs/heads/main/Source.lua"))()

local Window = OrionLib:MakeWindow({
	Name = "Example",
	HidePremium = false,
	SaveConfig = true,
	ConfigFolder = "Example",
	IntroEnabled = false
})

local ExampleTab = Window:MakeTab({
	Name = "Example",
	Icon = "home",
	PremiumOnly = false
})

local ExampleSection = ExampleTab:AddSection({
	Name = "Example"
})

ExampleSection:AddSlider({
	Name = "Example Slider",
	Min = 0,
	Max = 100,
	Default = 50,
	Color = Color3.fromRGB(9, 149, 98),
	Increment = 1,
	ValueName = "",
	Flag = "ExampleSlider",
	Save = true,
	Callback = function(Value)
		print("Example Slider:", Value)
	end
})

ExampleSection:AddSlider({
	Name = "Example Slider 2",
	Min = 0,
	Max = 10,
	Default = 5,
	Color = Color3.fromRGB(9, 99, 195),
	Increment = 0.5,
	ValueName = "",
	Flag = "ExampleSlider2",
	Save = true,
	Callback = function(Value)
		print("Example Slider 2:", Value)
	end
})

ExampleSection:AddColorpicker({
	Name = "Example Colorpicker",
	Default = Color3.fromRGB(255, 0, 0),
	Flag = "ExampleColorpicker",
	Save = true,
	Callback = function(Value)
		print("Example Colorpicker:", Value)
	end
})

ExampleSection:AddColorpicker({
	Name = "Example Colorpicker 2",
	Default = Color3.fromRGB(0, 170, 255),
	Flag = "ExampleColorpicker2",
	Save = true,
	Callback = function(Value)
		print("Example Colorpicker 2:", Value)
	end
})

ExampleSection:AddToggle({
	Name = "Example Toggle",
	Default = false,
	Flag = "ExampleToggle",
	Save = true,
	Callback = function(Value)
		print("Example Toggle:", Value)
	end
})

ExampleSection:AddButton({
	Name = "Example Button",
	Callback = function()
		OrionLib:MakeNotification({
			Name = "Example",
			Content = "Example",
			Time = 5
		})
	end
})

ExampleSection:AddDropdown({
	Name = "Example Dropdown",
	Default = "Two",
	Options = {"One", "Two", "Three", "Four", "Five", "Six", "Seven"},
	Flag = "ExampleDropdown",
	Save = true,
	Callback = function(Value)
		print("Example Dropdown:", Value)
	end
})

ExampleSection:AddMultiDropdown({
	Name = "Example Multi Dropdown",
	Default = {"One", "Two"},
	Options = {"One", "Two", "Three", "Four"},
	Flag = "ExampleMultiDropdown",
	Save = true,
	Callback = function(Values)
		print(table.concat(Values, ", "))
	end
})

local ConfigTab = Window:MakeTab({
	Name = "Config",
	Icon = "settings",
	PremiumOnly = false
})

local ConfigSection = ConfigTab:AddSection({
	Name = "Config Manager"
})

ConfigSection:AddConfigManager({})

OrionLib:Init()
