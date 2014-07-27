-- Script information
script_name = "Wobble text"
script_description = "Converts a text to a shape and adds wobbling."
script_author = "Youka"
script_version = "1.2"
script_modified = "27th July 2014"

-- Load Yutils library
local Yutils = include("Yutils.lua")

-- UI configuration template
local config_template = {
	{
		class = "label",
		x = 0, y = 0, width = 1, height = 1,
		label = "Fontname: "
	},
	{
		class = "dropdown", name = "fontname",
		x = 1, y = 0, width = 3, height = 1,
		hint = "Font family" -- items = {}, value = ""
	},
	{
		class = "checkbox", name = "bold",
		x = 4, y = 0, width = 1, height = 1,
		hint = "Text should be bold?", label = "Bold?", value = false
	},
	{
		class = "checkbox", name = "italic",
		x = 5, y = 0, width = 1, height = 1,
		hint = "Text should be italic?", label = "Italic?", value = false
	},
	{
		class = "label",
		x = 0, y = 1, width = 1, height = 1,
		label = "Fontsize: "
	},
	{
		class = "intedit", name = "fontsize",
		x = 1, y = 1, width = 3, height = 1,
		hint = "Font size", value = 30, min = 1, max = 1000
	},
	{
		class = "checkbox", name = "underline",
		x = 4, y = 1, width = 1, height = 1,
		hint = "Text should be underlined?", label = "Underline?", value = false
	},
	{
		class = "checkbox", name = "strikeout",
		x = 5, y = 1, width = 1, height = 1,
		hint = "Text should be outstriked?", label = "Strikeout?", value = false
	},
	{
		class = "label",
		x = 0, y = 2, width = 1, height = 1,
		label = "Scale X%: "
	},
	{
		class = "floatedit", name = "scale_x",
		x = 1, y = 2, width = 1, height = 1,
		hint = "Horizontal scaling in percent", value = 100, min = 0.01, max = 10000, step = 0.01
	},
	{
		class = "label",
		x = 2, y = 2, width = 1, height = 1,
		label = "Scale Y%: "
	},
	{
		class = "floatedit", name = "scale_y",
		x = 3, y = 2, width = 1, height = 1,
		hint = "Vertical scaling in percent", value = 100, min = 0.01, max = 10000, step = 0.01
	},
	{
		class = "label",
		x = 4, y = 2, width = 1, height = 1,
		label = "Spacing: "
	},
	{
		class = "floatedit", name = "spacing",
		x = 5, y = 2, width = 1, height = 1,
		hint = "Intercharacter spacing", value = 0, min = -100, max = 100, step = 0.01
	},
	{
		class = "label",
		x = 0, y = 3, width = 1, height = 1,
		label = "Text:"
	},
	{
		class = "textbox", name = "text",
		x = 0, y = 4, width = 6, height = 2,
		hint = "Text to convert", text = ""
	},
	{
		class = "label",
		x = 1, y = 6, width = 1, height = 1,
		label = "X"
	},
	{
		class = "label",
		x = 2, y = 6, width = 1, height = 1,
		label = "Y"
	},
	{
		class = "label",
		x = 0, y = 7, width = 1, height = 1,
		label = "Wobble frequency: "
	},
	{
		class = "floatedit", name = "wobble_frequency_x",
		x = 1, y = 7, width = 1, height = 1,
		hint = "Horizontal wobbling frequency in percent", value = 0, min = 0, max = 10, step = 0.00001
	},
	{
		class = "floatedit", name = "wobble_frequency_y",
		x = 2, y = 7, width = 1, height = 1,
		hint = "Vertical wobbling frequency in percent", value = 0, min = 0, max = 10, step = 0.00001
	},
	{
		class = "label",
		x = 0, y = 8, width = 1, height = 1,
		label = "Wobble strength: "
	},
	{
		class = "floatedit", name = "wobble_strength_x",
		x = 1, y = 8, width = 1, height = 1,
		hint = "Horizontal wobbling strength in pixels", value = 0, min = 0, max = 100, step = 0.01
	},
	{
		class = "floatedit", name = "wobble_strength_y",
		x = 2, y = 8, width = 1, height = 1,
		hint = "Vertical wobbling strength in pixels", value = 0, min = 0, max = 100, step = 0.01
	},
}
do
	-- Fill font families in configuration
	local items, items_n = {}, 0
	for _, family in ipairs(Yutils.decode.list_fonts()) do
		items_n = items_n + 1
		items[items_n] = family.name
	end
	config_template[2].items = items
	config_template[2].value = items[1]
end

-- Macro execution
local function load_macro()
	-- Show UI
	local ok, config = aegisub.dialog.display(config_template, {"Calculate"})
	-- OK from UI
	if ok then
		-- Save UI configuration to template
		config_template[2].value = config.fontname
		config_template[3].value = config.bold
		config_template[4].value = config.italic
		config_template[6].value = config.fontsize
		config_template[7].value = config.underline
		config_template[8].value = config.strikeout
		config_template[10].value = config.scale_x
		config_template[12].value = config.scale_y
		config_template[14].value = config.spacing
		config_template[16].text = config.text
		config_template[20].value = config.wobble_frequency_x
		config_template[21].value = config.wobble_frequency_y
		config_template[23].value = config.wobble_strength_x
		config_template[24].value = config.wobble_strength_y
		-- Calculate shape from configuration settings
		local text_shape = Yutils.decode.create_font(config.fontname, config.bold, config.italic, config.underline, config.strikeout, config.fontsize, config.scale_x / 100, config.scale_y / 100, config.spacing).text_to_shape(config.text)
		if (config.wobble_frequency_x > 0 and config.wobble_strength_x > 0) or (config.wobble_frequency_y > 0 and config.wobble_strength_y > 0) then
			text_shape = Yutils.shape.filter(
									Yutils.shape.split(
										Yutils.shape.flatten(
											text_shape
										),
										1.5
									),
									function(x,y)
										return x + math.sin(y * config.wobble_frequency_x * math.pi * 2) * config.wobble_strength_x,
												y + math.sin(x * config.wobble_frequency_y * math.pi * 2) * config.wobble_strength_y
									end
								)
		end
		-- Show calculated shape
		aegisub.log(text_shape)
	end
end

-- Register macro to Aegisub
aegisub.register_macro(script_name,script_description,load_macro)