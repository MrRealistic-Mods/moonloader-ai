script_name("Paintjob Loader")
script_authors("Grinch_")
script_description("Loads custom vehicle paintjobs")
script_dependencies("imgui","MoonAdditions")
script_version("1.4")

--Keys
local keys =
{
	menu_key1 = 0xA2, -- Left Control
	menu_key2 = 0x50, -- P
}

-- Script Dependencies
local imgui       = require 'imgui'
local mad 		  = require 'MoonAdditions'
local gsx = import 'gsx-data.lua'

local resX, resY = getScreenResolution()

local config_file = nil
local config_path = getGameDirectory() .. "\\moonloader\\lib\\paintjob-loader\\config.json"


function LoadConfig()
	if doesFileExist(config_path) then
		local file = io.open(config_path, "r")
		config_file = decodeJson(file:read("*a"))
		file:close()
	end
end

LoadConfig()

function Get(s,default)
    if config_file == nil then return default end

    local t = config_file
    
    for key in s:gmatch('[^.]+') do
      if t[key] == nil then return default end
      t = t[key]
    end

    if t == nil then
        return default
    else
        return t
    end
end

local tmain =
{
	apply_material_filter= imgui.ImBool(Get("apply_material_filter",true)),
	cache_images  = {},
	color_rgb     = imgui.ImFloat3(0,0,0),
	current_paintjob = imgui.ImInt(-1),
	default_color = -1,
	dir      = getGameDirectory() .. "\\moonloader\\lib\\paintjob-loader\\",
	filter   = imgui.ImGuiTextFilter(),
	images   = {},
	texture  = nil,
	title    = string.format("%s v%s by %s",script.this.name, script.this.version, script.this.authors[1]),
	window   = 
	{
		show = imgui.ImBool(false),
		size     =
        {
            X    = Get("window.size.X",resX/4),
            Y    = Get("window.size.Y",resY/1.2),
        },
	}
}


local components =
{
	selected = imgui.ImInt(0),
	names =
	{
		"Default",
		"Wheel Right Front",
		"Wheel Left Back",
		"Wheel Left Front",
		"Wheel Right Back",
		"Chassis Inside",
		"Chassis Inside",
		"Exhaust",
		"Chassis",
		"Nitro",
		"Door Left Back",
		"Rear Bumper",
		"Bonnet",
		"Front Bumper",
		"Door Left Front",
		"Door Right Front",
		"Door Right Rear",
		"Windscreen",
		"Boot",
	},
	list =
	{
		"Default",
		"wheel_rf_dummy",
		"wheel_lb_dummy",
		"wheel_lf_dummy",
		"wheel_rb_dummy",
		"chassis_dummy",
		"chassis_vlo",
		"exhaust_ok",
		"chassis",
		"ug_nitro",
		"door_lr_dummy",
		"bump_rear_dummy",
		"bonnet_dummy",
		"bump_front_dummy",
		"door_lf_dummy",
		"door_rf_dummy",
		"door_rr_dummy",
		"windscreen_dummy",
		"boot_dummy",
	},

}

function InformationTooltip(text)
    if text ~= nil then
        imgui.SameLine()
        imgui.TextColored(imgui.ImVec4(128,128,128,0.3),'(?)')
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.SetTooltip(text)
            imgui.EndTooltip()
        end
    end
end


function imgui.OnDrawFrame()
	if  tmain.window.show.v and isCharInAnyCar(PLAYER_PED) then

		local car = getCarCharIsUsing(PLAYER_PED)
		local model = getCarModel(car)

		imgui.SetNextWindowSize(imgui.ImVec2(tmain.window.size.X,tmain.window.size.Y), imgui.Cond.FirstUseEver)

		imgui.Begin(tmain.title, tmain.window.show,imgui.WindowFlags.NoCollapse)

		imgui.PushStyleVar(imgui.StyleVar.ItemSpacing,imgui.ImVec2(-0.1,0.5))

		if imgui.Button("Reset color",imgui.ImVec2(GetSize(2,true))) then

			ForEachCarComponent(function(mat,comp,car)
				if comp.name == components.list[components.selected.v+1] or components.selected.v == 0 then
					mat:reset_color()
				end
			end)
			tmain.default_color = nil
			printHelpString("Color reset")
		end
		imgui.SameLine()
		if imgui.Button("Reset texture",imgui.ImVec2(GetSize(2,true))) then
			ForEachCarComponent(function(mat,comp,car)
				if comp.name == components.list[components.selected.v+1] or components.selected.v == 0 then
					mat:reset_texture()
				end
			end)
			tmain.texture = nil
			printHelpString("Texture reset")
		end
		imgui.PopStyleVar(1)

		imgui.Dummy(imgui.ImVec2(0,10))
		imgui.Checkbox("Apply material filter",tmain.apply_material_filter)
		imgui.Spacing()
		imgui.Combo("Select Component",components.selected,components.names)
		if imgui.ColorEdit3("Color",tmain.color_rgb) then
			ApplyColor()
		end

		local paintjobs_count =  getNumAvailablePaintjobs(car)
                
		tmain.current_paintjob.v = getCurrentVehiclePaintjob(car)

		if paintjobs_count > 0 then
			if imgui.InputInt("Paintjob",tmain.current_paintjob) then
				if tmain.current_paintjob.v >= -1 and tmain.current_paintjob.v <= paintjobs_count then
					giveVehiclePaintjob(car,tmain.current_paintjob.v)
				end
			end
		end

		DrawImages(tmain.images,75,100,tmain.filter)

		tmain.window.size.X  = imgui.GetWindowWidth()
		tmain.window.size.Y  = imgui.GetWindowHeight()

        imgui.End()
    end
end

function SaveConfig()
    write_table =
	{
		apply_material_filter = tmain.apply_material_filter.v,
		window = 
		{
			size = 
			{
				X = tmain.window.size.X,
				Y = tmain.window.size.Y,
			}
		}
	}

    file = io.open(tmain.dir .. "/config.json",'w')
    if file then
        file:write(encodeJson(write_table))
        io.close(file)
    end
end


function Set(t,path,value)
    local x = 0
    for key in path:gmatch('[^.]+') do
        x = x + 1
    end

    local y = 0
    for key in path:gmatch('[^.]+') do
        y = y + 1
        if x == y then
            t[key] = value
        else
            if t[key] == nil then t[key] = {} end
            t = t[key]
        end
    end
end

function ApplyTexture(filename,load_saved_texture)

    ForEachCarComponent(function(mat,comp,car)
        local r, g, b, old_a = mat:get_color()
        local model = getCarModel(car)


        if load_saved_texture and script.find('gsx-data') then
            filename = gsx.get(car,"cm_texture_" .. comp.name)
        end
		

		if filename ~= nil then
			local fullpath = tmain.dir .. filename .. ".png"
			
			if doesFileExist(fullpath) then
				if tmain.cache_images[filename] == nil then
					tmain.cache_images[filename] = mad.load_png_texture(fullpath)
				end

				tmain.texture = tmain.cache_images[filename]


				if not tmain.apply_material_filter.v or (r == 0x3C and g == 0xFF and b == 0x00) or (r == 0xFF and g == 0x00 and b == 0xAF) then
					if components.selected.v == 0 and not load_saved_texture then
						mat:set_texture(tmain.texture)
						if script.find('gsx-data') then 
                            gsx.set(car,"cm_texture_" .. comp.name,filename)
                        end 
					end
					if comp.name == components.list[components.selected.v+1] or load_saved_texture then
						mat:set_texture(tmain.texture)
						if script.find('gsx-data') then 
                            gsx.set(car,"cm_texture_" .. comp.name,filename)
                        end 
					end
				end
			end
		end
        tmain.default_color = getCarColours(car)
    end)
    
end

function LoadImages(path,table)
	mask = string.format( "%s*.png",path)

	local handle,file = findFirstFile(mask)

	if handle then
		while handle and file do
			local f = path .. file
			index  = file:sub(1,(file:len()-4))
			table[tostring(index)] = imgui.CreateTextureFromFile(f)
			file = findNextFile(handle)
		end
		findClose(handle)
	end
end

function DrawImages(table,const_image_height,const_image_width,filter)

    -- Calculate image count in a row
    local images_in_row = math.floor(imgui.GetWindowContentRegionWidth()/const_image_width)

    const_image_width = (imgui.GetWindowContentRegionWidth() - imgui.StyleVar.ItemSpacing*(images_in_row-0.4*images_in_row))/images_in_row

    local image_count   = 1

	filter:Draw("Filter")
	imgui.Spacing()
	imgui.Separator()
	imgui.Spacing()

	if imgui.BeginChild("Images") then 
		for model,image in pairs(table) do
	
			if filter:PassFilter(model) then
				if imgui.ImageButton(image,imgui.ImVec2(const_image_width,const_image_height),imgui.ImVec2(0,0),imgui.ImVec2(1,1),1,imgui.ImVec4(1,1,1,1),imgui.ImVec4(1,1,1,1)) then
					ApplyTexture(model)
				end
				
				if imgui.IsItemHovered() then
					imgui.BeginTooltip()
					imgui.SetTooltip(model)
					imgui.EndTooltip()
				end
	
				if image_count % images_in_row ~= 0 then
					imgui.SameLine(0.0,4.0)
				end
				image_count = image_count + 1
			end
		end
		imgui.EndChild()
	end   
end


function ApplyColor(load_saved_color)

    ForEachCarComponent(function(mat,comp,car)

        local r, g, b, old_a = mat:get_color()
        local model = getCarModel(car)

        -- -1.0 used as nil
        if load_saved_color and script.find('gsx-data') then
            tmain.color_rgb.v[1] = gsx.get(car,"cm_color_red_" .. comp.name) or -1
            tmain.color_rgb.v[2] = gsx.get(car,"cm_color_green_" .. comp.name) or -1
            tmain.color_rgb.v[3] = gsx.get(car,"cm_color_blue_" .. comp.name) or -1
        end

        if (tmain.color_rgb.v[1] ~= -1.0 and tmain.color_rgb.v[2] ~= -1.0 and tmain.color_rgb.v[3] ~= -1.0)
        and (not tmain.apply_material_filter.v or (r == 0x3C and g == 0xFF and b == 0x00) or (r == 0xFF and g == 0x00 and b == 0xAF)) then
            
            if components.selected.v == 0 then
                
                mat:set_color(tmain.color_rgb.v[1]*255, tmain.color_rgb.v[2]*255, tmain.color_rgb.v[3]*255, 255.0)

				if script.find('gsx-data') then
                    gsx.set(car,"cm_color_red_" .. comp.name,tmain.color_rgb.v[1])
                    gsx.set(car,"cm_color_green_" .. comp.name,tmain.color_rgb.v[2])
                    gsx.set(car,"cm_color_blue_" .. comp.name,tmain.color_rgb.v[3])
                end
            end

            if comp.name == components.list[components.selected.v+1] or load_saved_color then
                
                mat:set_color(tmain.color_rgb.v[1]*255, tmain.color_rgb.v[2]*255, tmain.color_rgb.v[3]*255, 255.0)

                if script.find('gsx-data') then
                    gsx.set(car,"cm_color_red_" .. comp.name,tmain.color_rgb.v[1])
                    gsx.set(car,"cm_color_green_" .. comp.name,tmain.color_rgb.v[2])
                    gsx.set(car,"cm_color_blue_" .. comp.name,tmain.color_rgb.v[3])
                end
            end

        end
        tmain.default_color = getCarColours(car)
    end)  
end

function ForEachCarComponent(func,skip)
    if isCharInAnyCar(PLAYER_PED) then
        car = getCarCharIsUsing(PLAYER_PED)
        for _, comp in ipairs(mad.get_all_vehicle_components(car)) do
            for _, obj in ipairs(comp:get_objects()) do
                for _, mat in ipairs(obj:get_materials()) do
                    func(mat,comp,car)
                    if skip == true then
                        goto _skip
                    end
                end
            end
            ::_skip::
        end
        markCarAsNoLongerNeeded(car)
    else
        printHelpString("Player ~r~not ~w~in car")
    end
end

function GetTextureName(name)
    if name == nil then
        return ""
    else
        return "Texture: " ..name
    end
end

function GetSize(count,no_spacing)
  
    x = x or 20
    y = y or 30
    count = count or 1
    if count == 1 then no_spacing = true end

    if no_spacing == true then 
        x = imgui.GetWindowContentRegionWidth()/count
    else
        x = imgui.GetWindowContentRegionWidth()/count - imgui.StyleVar.ItemSpacing/(count+1)
    end

    y = (imgui.GetWindowHeight()/25)
    if y < 30 then y = 30 end

    return x,y
end

function ApplyStyle()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    style.WindowRounding = 1.0
	style.WindowTitleAlign = imgui.ImVec2(0.5, 0.84)
	style.ChildWindowRounding = 1.0
	style.FrameRounding = 1.0
	style.ItemSpacing = imgui.ImVec2(8.0, 4.0)
	style.ItemInnerSpacing = imgui.ImVec2(4.0, 4.0)
	style.ScrollbarSize = 12.0
	style.ScrollbarRounding = 1.0
	style.GrabMinSize = 8.0
	style.GrabRounding = 1.0
	style.WindowPadding = imgui.ImVec2(8.0, 8.0)
	style.FramePadding = imgui.ImVec2(4.0, 3.0)

	colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
	colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
	colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.ComboBg]                = colors[clr.PopupBg]
	colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.FrameBg]                = ImVec4(0.16, 0.29, 0.48, 0.54)
	colors[clr.FrameBgHovered]         = ImVec4(0.26, 0.59, 0.98, 0.40)
	colors[clr.FrameBgActive]          = ImVec4(0.26, 0.59, 0.98, 0.67)
	colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
	colors[clr.TitleBgActive]          = ImVec4(0.16, 0.29, 0.48, 1.00)
	colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
	colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
	colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
	colors[clr.CheckMark]              = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.SliderGrab]             = ImVec4(0.24, 0.52, 0.88, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.Button]                 = ImVec4(0.26, 0.59, 0.98, 0.40)
	colors[clr.ButtonHovered]          = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.ButtonActive]           = ImVec4(0.06, 0.53, 0.98, 1.00)
	colors[clr.Header]                 = ImVec4(0.26, 0.59, 0.98, 0.31)
	colors[clr.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
	colors[clr.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.Separator]              = colors[clr.Border]
	colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
	colors[clr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
	colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
	colors[clr.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
	colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
	colors[clr.CloseButtonHovered]     = ImVec4(0.259, 0.588, 0.980, 0.80)
	colors[clr.CloseButtonActive]      = ImVec4(0.259, 0.588, 0.980, 1.00)
	colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
	colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
	colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end


function OnEnterVehicle()

    while true do
        if isCharInAnyCar(PLAYER_PED) then
            local car        = getCarCharIsUsing(PLAYER_PED)
			local model      = getCarModel(car)

            -- Auto load tuning data
			ApplyTexture(nil,true)
			ApplyColor(true)
			
			while isCharInAnyCar(PLAYER_PED) do
				wait(0)
			end
        end
        wait(0)
    end
end


function main()

	ApplyStyle()
	LoadImages(tmain.dir,tmain.images)
	lua_thread.create(OnEnterVehicle)

	while true do
		if isKeyDown(keys.menu_key1) and isKeyDown(keys.menu_key2) and isCharInAnyCar(PLAYER_PED) then
			while isKeyDown(keys.menu_key1) and isKeyDown(keys.menu_key2) do
				wait(0)
			end
			tmain.window.show.v = not tmain.window.show.v
		end

		if tmain.default_color ~= -1 and isCharInAnyCar(PLAYER_PED) then
			local car = getCarCharIsUsing(PLAYER_PED)
			local color_id = getCarColours(car)
			if tmain.default_color ~= color_id then
				ForEachCarComponent(function(mat)
					mat:reset_color()
				end)
			end
		end

        imgui.Process = tmain.window.show.v
        wait(0)
	end
end

function onScriptTerminate(script, quitGame)
    if script == thisScript() then
        SaveConfig()
    end
end
