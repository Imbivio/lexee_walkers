--[[
	UIKit — tiny declarative UI helpers + shared palette for all client UI.
]]

local UIKit = {}

UIKit.Colors = {
	Panel = Color3.fromRGB(18, 32, 42),
	PanelLight = Color3.fromRGB(28, 48, 62),
	Stroke = Color3.fromRGB(60, 105, 130),
	Text = Color3.fromRGB(235, 242, 245),
	TextDim = Color3.fromRGB(150, 175, 188),
	Accent = Color3.fromRGB(64, 190, 210),
	Coin = Color3.fromRGB(255, 205, 80),
	Good = Color3.fromRGB(90, 210, 130),
	Bad = Color3.fromRGB(235, 90, 90),
}

-- UIKit.new("TextLabel", { Size = ..., [UIKit.Children] = { ... } })
UIKit.Children = {} -- unique key

function UIKit.new(className: string, props: { [any]: any }): Instance
	local instance = Instance.new(className)
	local children = props[UIKit.Children]
	for key, value in pairs(props) do
		if key ~= UIKit.Children then
			(instance :: any)[key] = value
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = instance
		end
	end
	return instance
end

function UIKit.corner(radius: number?): UICorner
	return UIKit.new("UICorner", { CornerRadius = UDim.new(0, radius or 8) }) :: UICorner
end

function UIKit.stroke(color: Color3?, thickness: number?): UIStroke
	return UIKit.new("UIStroke", {
		Color = color or UIKit.Colors.Stroke,
		Thickness = thickness or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}) :: UIStroke
end

function UIKit.padding(px: number): UIPadding
	return UIKit.new("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
	}) :: UIPadding
end

function UIKit.label(props: { [any]: any }): TextLabel
	local base = {
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextColor3 = UIKit.Colors.Text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
	}
	for key, value in pairs(props) do
		base[key] = value
	end
	return UIKit.new("TextLabel", base) :: TextLabel
end

function UIKit.button(props: { [any]: any }, onClick: () -> ()): TextButton
	local base = {
		BackgroundColor3 = UIKit.Colors.Accent,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(10, 25, 32),
		TextSize = 14,
		AutoButtonColor = true,
		[UIKit.Children] = { UIKit.corner(6) },
	}
	for key, value in pairs(props) do
		if key == UIKit.Children then
			for _, child in ipairs(value) do
				table.insert(base[UIKit.Children], child)
			end
		else
			base[key] = value
		end
	end
	local btn = UIKit.new("TextButton", base) :: TextButton
	btn.MouseButton1Click:Connect(onClick)
	return btn
end

-- Draggable-free centered window with a title bar and close button.
-- Returns (window, contentFrame, closeFn).
function UIKit.window(parent: Instance, title: string, size: UDim2)
	local window = UIKit.new("Frame", {
		Name = title,
		Size = size,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = UIKit.Colors.Panel,
		Visible = false,
		[UIKit.Children] = {
			UIKit.corner(12),
			UIKit.stroke(),
		},
	})

	local titleBar = UIKit.new("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = UIKit.Colors.PanelLight,
		[UIKit.Children] = {
			UIKit.corner(12),
			UIKit.label({
				Size = UDim2.new(1, -60, 1, 0),
				Position = UDim2.new(0, 14, 0, 0),
				Text = title,
				Font = Enum.Font.GothamBold,
				TextSize = 18,
			}),
		},
	})
	titleBar.Parent = window

	local closeBtn = UIKit.button({
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -34, 0, 6),
		BackgroundColor3 = UIKit.Colors.Bad,
		Text = "X",
	}, function()
		window.Visible = false
	end)
	closeBtn.Parent = titleBar

	local content = UIKit.new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 1, -40),
		Position = UDim2.new(0, 0, 0, 40),
		BackgroundTransparency = 1,
		[UIKit.Children] = { UIKit.padding(10) },
	})
	content.Parent = window

	window.Parent = parent
	return window, content, function()
		window.Visible = false
	end
end

function UIKit.clear(frame: Instance)
	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

return UIKit
