--[[
Ring Meters by londonali1010 (2009)
Modified by La-Manoue (2016)
Automation template by popi (2017)
Modified by dirn (2020)

This script draws percentage meters as rings. It is fully customisable all options are described in the script.

IMPORTANT: if you are using the 'cpu' function, it will cause a segmentation fault if it tries to draw a ring straight away. 
    The if statement near the end of the script uses a delay to make sure that this doesn't happen. 
    It calculates the length of the delay by the number of updates since Conky started. 
    Generally, a value of 5s is long enough, so if you update Conky every 1s, use update_num > 5 in that if statement (the default). 
    If you only update Conky every 2s, you should change it to update_num > 3 conversely if you update Conky every 0.5s, 
    you should use update_num > 10. ALSO, if you change your Conky, is it best to use "killall conky conky" to update it, 
    otherwise the update_num will not be reset and you will get an error.

To call this script in Conky, use the following (assuming that you save this script to ~/.config/conky/hybrid/lua/hybrid-rings.lua):
	lua_load = '~/.config/conky/hybrid/lua/hybrid-rings.lua',
    lua_draw_hook_pre = 'conky_main'
]]

g_main_colour = "0xa8a8a8"

normal = "0x3458eb"
warn = "0xff7200"
crit = "0xff000d"
update_num_min = 3
home_dir = os.getenv("HOME")

require 'cairo'
require 'cairo_xlib'

-- global helper functions
function rgb_to_r_g_b(colour, alpha)
    return ((colour / 0x10000) % 0x100) / 255., ((colour / 0x100) % 0x100) / 255., (colour % 0x100) / 255., alpha
end

function to_boolean(p_str)
    if p_str == "true" or p_str == "True" then
        return true
    elseif p_str == "false" or p_str == "False" then
        return false
    else
        return false
    end
end

-- Function to detect number of CPU cores
function get_cpu_count()
    local handle = io.popen("nproc")
    local result = handle:read("*a")
    handle:close()
    -- Remove trailing newline
    result = result:gsub("[\n\r]", "")
    return tonumber(result) or 12 -- Fallback to 12 if detection fails
end

-- Generate CPU rings dynamically based on actual CPU count
function generate_cpu_settings()
    local cpu_count = get_cpu_count()
    local cpu_settings = {}
    
    -- Calculate layout parameters
    local cores_per_row = 6 -- Ripristinato a 6 core per riga
    local rows_needed = math.ceil(cpu_count / cores_per_row)
    
    -- Ensure consistent spacing between rows
    local base_y = 180 -- Increased from 150
    local row_spacing = 320 -- Increased from 260
    
    -- Calculate starting index for text_id based on existing settings
    local text_id_start = 19 -- Starting text_id for CPU cores
    
    for i = 1, cpu_count do
        local row = math.ceil(i / cores_per_row)
        local position_in_row = (i - 1) % cores_per_row + 1
        
        -- Calculate visual position
        local quadrant = math.ceil(position_in_row / 3) -- 1 or 2
        local pos_in_quadrant = (position_in_row - 1) % 3 + 1 -- 1, 2, or 3
        
        -- Adjust y position based on row
        local x, y = 140, base_y + (row - 1) * row_spacing
        local start_angle, end_angle
        local radius, thickness
        local bg_alpha
        
        -- Set angles based on quadrant
        if quadrant == 1 then
            start_angle = 0
            end_angle = 90
        else
            start_angle = 180
            end_angle = 270
        end
        
        -- Determine radius and thickness based on position in quadrant
        if pos_in_quadrant == 1 then
            radius = 120 -- Increased from 86
            thickness = 24 -- Increased from 17
            bg_alpha = 0.5
        elseif pos_in_quadrant == 2 then
            radius = 90 -- Increased from 65
            thickness = 22 -- Increased from 16
            bg_alpha = 0.4
        else
            radius = 60 -- Increased from 45
            thickness = 20 -- Increased from 14
            bg_alpha = 0.3
        end
        
        table.insert(cpu_settings, {
            name = 'cpu',
            arg = 'cpu' .. i,
            max = 100,
            bg_colour = 0xa8a8a8,
            bg_alpha = bg_alpha,
            fg_colour = 0x3458eb,
            fg_alpha = 1.0,
            x = x, y = y,
            radius = radius,
            thickness = thickness,
            start_angle = start_angle,
            end_angle = end_angle,
            text_id = text_id_start + i - 1
        })
    end
    
    return cpu_settings
end

-- Function to generate text settings for CPU cores
function generate_cpu_text_settings()
    local cpu_count = get_cpu_count()
    local text_settings = {
        -- cpu core (Adjust coordinates if needed after ring adjustments)
        { text = 'C01', show = false, x = 30, y = 40, ind_id = 1 },
        { text = 'C02', show = false, x = 30, y = 56, ind_id = 2 },
        { text = 'C03', show = false, x = 230, y = 194, ind_id = 3 },
        { text = 'C04', show = false, x = 30, y = 230, ind_id = 4 },
        { text = 'C05', show = false, x = 30, y = 246, ind_id = 5 },
        { text = 'C06', show = false, x = 230, y = 524, ind_id = 6 },

        -- ram (Adjust coordinates)
        { text = 'RAM', show = true, x = 40, y = 1100, ind_id = 7 }, -- Adjusted x, y

        -- cpu temp (Adjust coordinates)
        { text = 'CPU', show = true, x = 250, y = 250, ind_id = 8 }, -- Adjusted x,y
        { text = 'SWP', show = true, x = 240, y = 1250, ind_id = 9 }, -- Adjusted x,y

        -- disk storage (Adjust coordinates)
        { text = '', show = false, x = 180, y = 940 },
        { text = '', show = true, x = 120, y = 1100 }, -- Adjusted x, y
        { text = '/usr', show = false, x = 150, y = 1185, ind_id = 11 }, -- Adjusted x, y
        { text = '/home', show = false, x = 154, y = 1240 }, -- Adjusted x, y

        -- clock (Adjust coordinates)
        { text = 'HH', show = true, x = 136, y = 1174 }, -- Adjusted x, y
        { text = 'MM', show = true, x = 152, y = 1174 }, -- Adjusted x, y
        { text = 'SS', show = false, x = 162, y = 1174 }, -- Adjusted x, y
    }
    
    -- Create CPU thread text settings dynamically (Adjust coordinates)
    local cores_per_row = 6
    local base_y = 130 -- Adjusted from 100
    local row_spacing = 320 -- Adjusted from 260
    local entry_spacing = 22 -- Adjusted from 18
    
    for i = 1, cpu_count do
        local row = math.ceil(i / cores_per_row)
        local position_in_row = (i - 1) % cores_per_row + 1
        
        -- Calculate position
        local y_offset = (row - 1) * row_spacing
        local pos_in_group = (position_in_row - 1) % 3
        local x = 140 -- Adjusted from 130
        local y = base_y + y_offset + (pos_in_group * entry_spacing)
        
        -- Adjust y position for the second group in each row
        if position_in_row > 3 then
            y = y + 150 -- Adjusted from 120
        end
        
        table.insert(text_settings, {
            text = tostring(i),
            show = true,
            x = x,
            y = y
        })
    end
    
    return text_settings
end

-- blue     | 0x3458eb
-- red      | 0xff1d2b
-- green    | 0x1dff22
-- pink     | 0xff1d9f
-- orange   | 0xff8523
-- skyblue  | 0x008cff
-- darkgray | 0x323232

-- Base settings table (non-CPU elements)
settings_table = {
    -- cpu core temperature (nascosti)
    {
        name='platform',
        arg='coretemp.0/hwmon/hwmon6 temp 2', -- Core 0 (Using temp2)
        max=110,
        bg_colour=0xa8a8a8,
        bg_alpha=0.0, -- nascosto
        fg_colour=0x3458eb,
        fg_alpha=0.0, -- nascosto
        x=140, y=180, -- Adjusted y
        radius=165, -- Increased from 118
        thickness=10, -- Increased from 6
        start_angle=180,
        end_angle=450,
        text_id=1
    },
    {
        name='platform',
        arg='coretemp.0/hwmon/hwmon6 temp 6', -- Core 4 (? Using temp6)
        max=110,
        bg_colour=0xa8a8a8,
        bg_alpha=0.0, -- nascosto
        fg_colour=0x3458eb,
        fg_alpha=0.0, -- nascosto
        x=140, y=180, -- Adjusted y
        radius=150, -- Increased from 110
        thickness=10, -- Increased from 6
        start_angle=180,
        end_angle=450,
        text_id=2
    },
    {
        name='platform',
        arg='coretemp.0/hwmon/hwmon6 temp 10', -- Core 8 (? Using temp10)
        max=110,
        bg_colour=0xa8a8a8,
        bg_alpha=0.0, -- nascosto
        fg_colour=0x3458eb,
        fg_alpha=0.0, -- nascosto
        x=140, y=180, -- Adjusted y
        radius=180, -- Increased from 130
        thickness=10, -- Increased from 6
        start_angle=0,
        end_angle=270,
        text_id=3
    },

    -- ram usage
    {
        name='memperc',
        arg='',
        max=100,
        bg_colour=0xa8a8a8,
        bg_alpha=0.5,
        fg_colour=0x3458eb,
        fg_alpha=1.0,
        x=140, y=1150, -- Adjusted y
        radius=165, -- Increased from 118
        thickness=10, -- Increased from 6
        start_angle=180,
        end_angle=450,
        text_id=7
    },

    -- cpu temp (solo package temp)
    {
        name='platform',
        arg='coretemp.0/hwmon/hwmon6 temp 1', -- Package Temp (Using temp1)
        max=100,
        bg_colour=0xa8a8a8,
        bg_alpha=0.5,
        fg_colour=0x3458eb,
        fg_alpha=1.0,
        x=140, y=180, -- Adjusted y
        radius=163, -- Increased from 117
        thickness=10, -- Increased from 6
        start_angle=0,
        end_angle=270,
        text_id=8
    },
    
    -- ram usage (SWAP)
    {
        name='swapperc',
        arg='',
        max=100,
        bg_colour=0xa8a8a8,
        bg_alpha=0.5,
        fg_colour=0x3458eb,
        fg_alpha=1.0,
        x=140, y=1150, -- Adjusted y
        radius=180, -- Increased from 130
        thickness=10, -- Increased from 6
        start_angle=0,
        end_angle=270,
        text_id=9
    },

    -- storage usage
    {
        name='fs_used_perc',
        arg='/',
        max=100,
        bg_colour=0xa8a8a8,
        bg_alpha=0.5,
        fg_colour=0x3458eb,
        fg_alpha=1.0,
        x=140, y=1150, -- Adjusted y
        radius=135, -- Increased from 98
        thickness=18, -- Increased from 13
        start_angle=0,
        end_angle=90,
        text_id=12
    },
    
    -- /usr partition usage
    {
        name='fs_used_perc',
        arg='/usr',
        max=100,
        bg_colour=0xa8a8a8,
        bg_alpha=0.0,
        fg_colour=0x3458eb,
        fg_alpha=0.0,
        x=140, y=1150, -- Adjusted y
        radius=110, -- Increased from 78
        thickness=18, -- Increased from 13
        start_angle=0,
        end_angle=90,
        text_id=11
    },

    -- clock
    {
        name='time',
        arg='%H',
        max=12,
        bg_colour=0xa8a8a8,
        bg_alpha=0.1,
        fg_colour=0x3458eb,
        fg_alpha=1.0,
        x=140, y=1150, -- Adjusted y
        radius=105, -- Increased from 75
        thickness=12, -- Increased from 9
        start_angle=0,
        end_angle=360,
        text_id=16
    },
    {
        name='time',
        arg='%M',
        max=59,
        bg_colour=0xa8a8a8,
        bg_alpha=0.2,
        fg_colour=0x3458eb,
        fg_alpha=1.0,
        x=140, y=1150, -- Adjusted y
        radius=90, -- Increased from 65
        thickness=11, -- Increased from 8
        start_angle=0,
        end_angle=360,
        text_id=17
    },
    {
        name='time',
        arg='%S',
        max=59,
        bg_colour=0xa8a8a8,
        bg_alpha=0.3,
        fg_colour=0x3458eb,
        fg_alpha=1.0,
        x=140, y=1150, -- Adjusted y
        radius=78, -- Increased from 56
        thickness=10, -- Increased from 7
        start_angle=0,
        end_angle=360,
        text_id=18
    },
}

-- Add dynamically generated CPU settings
local cpu_settings = generate_cpu_settings()
for _, setting in ipairs(cpu_settings) do
    table.insert(settings_table, setting)
end

-- Generate text settings dynamically
text_settings = generate_cpu_text_settings()

-- Text indicator and other visual settings
text_indicator = {
    { x1 = 55, y1 = 115, x2 = 95, y2 = 115, x3 = 108, y3 = 128, alpha = 0.0 },        -- c1 (adjusted)
    { x1 = 55, y1 = 131, x2 = 65, y2 = 131, x3 = 77, y3 = 144, alpha = 0.0 },          -- c2 (adjusted)
    { x1 = 224, y1 = 259, x2 = 236, y2 = 271, x3 = 246, y3 = 271, alpha = 0.0 },    -- c3 (adjusted)
    
    { x1 = 55, y1 = 305, x2 = 95, y2 = 305, x3 = 108, y3 = 318, alpha = 0.0 },     -- c4 (adjusted)
    { x1 = 55, y1 = 321, x2 = 65, y2 = 321, x3 = 77, y3 = 334, alpha = 0.0 },       -- c5 (adjusted)
    { x1 = 224, y1 = 589, x2 = 236, y2 = 601, x3 = 246, y3 = 601, alpha = 0.0 },    -- c6 (adjusted)
    
    { x1 = 50, y1 = 1135, x2 = 70, y2 = 1135, x3 = 100, y3 = 1150, alpha = 0.0 },      -- RAM (adjusted)

    { x1 = 190, y1 = 265, x2 = 200, y2 = 273, x3 = 246, y3 = 273, alpha = 0.9 },    -- cpu (adjusted)
    { x1 = 180, y1 = 1150, x2 = 205, y2 = 1140, x3 = 230, y3 = 1130, alpha = 0.0 },    -- SWAP (adjusted)
    { x1 = 200, y1 = 1160, x2 = 210, y2 = 1170, x3 = 246, y3 = 1170, alpha = 0.0 },  -- /usr (adjusted)
}

line_settings = { -- Adjust coordinates
    -- vertical (adjust y2 based on new overall height)
    { x1 = 30, y1 = 0, x2 = 30, y2 = 1350 }, -- Increased y2
    { x1 = 140, y1 = 0, x2 = 140, y2 = 1350 }, -- Increased y2
    { x1 = 250, y1 = 0, x2 = 250, y2 = 1350 }, -- Increased y2
    { x1 = 275, y1 = 0, x2 = 275, y2 = 1350 }, -- Increased y2

    -- horizontal (adjust y1, y2 based on new spacing)
    { x1 = 0, y1 = 100, x2 = 470, y2 = 100 }, -- Adjusted Y
    { x1 = 0, y1 = 340 + 60, x2 = 270, y2 = 340 + 60 }, -- Adjusted Y
    { x1 = 0, y1 = 350 + 60, x2 = 270, y2 = 350 + 60 }, -- Adjusted Y
    { x1 = 0, y1 = 560 + 120, x2 = 270, y2 = 560 + 120 }, -- Adjusted Y
    { x1 = 0, y1 = 570 + 120, x2 = 270, y2 = 570 + 120 }, -- Adjusted Y
    { x1 = 0, y1 = 780 + 180, x2 = 270, y2 = 780 + 180 }, -- Adjusted Y
    { x1 = 0, y1 = 790 + 180, x2 = 270, y2 = 790 + 180 }, -- Adjusted Y
    { x1 = 0, y1 = 1000 + 240, x2 = 270, y2 = 1000 + 240 }, -- Adjusted Y
    { x1 = 0, y1 = 1010 + 240, x2 = 270, y2 = 1010 + 240 }, -- Adjusted Y
    { x1 = 0, y1 = 1070 + 80, x2 = 270, y2 = 1070 + 80 }, -- Adjusted Y

    -- diagonal (adjust y coordinates)
    { x1 = 0, y1 = 400, x2 = 290, y2 = 690 + 100 }, -- Adjusted Y
    { x1 = 0, y1 = 690 + 100, x2 = 290, y2 = 1000 + 200 }, -- Adjusted Y
}

circle_settings = { -- Adjust all y coordinates and radii
    { x = 230, y = 130, radius = 30.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 50, y = 320 + 60, radius = 30.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 230, y = 370 + 60, radius = 30.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 50, y = 540 + 120, radius = 30.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 230, y = 590 + 120, radius = 30.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 50, y = 760 + 180, radius = 30.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 230, y = 810 + 180, radius = 30.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 50, y = 980 + 240, radius = 30.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 230, y = 1030 + 240, radius = 30.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 50, y = 1050 + 80, radius = 30.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 230, y = 1100 + 80, radius = 30.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 230, y = 1280 + 80, radius = 30.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y

    { x = 30, y = 345 + 60, radius = 90.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 250, y = 345 + 60, radius = 90.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 30, y = 565 + 120, radius = 90.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 250, y = 565 + 120, radius = 90.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 30, y = 785 + 180, radius = 90.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 250, y = 785 + 180, radius = 90.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 30, y = 1005 + 240, radius = 90.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 250, y = 1005 + 240, radius = 90.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 30, y = 1075 + 80, radius = 90.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 250, y = 1075 + 80, radius = 90.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 30, y = 1230 + 80, radius = 90.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y
    { x = 250, y = 1230 + 80, radius = 90.0, start_angle = 0.0, end_angle = 360.0 }, -- Inc R, adj Y

    -- CPU section circles (Increased radii, y adjusted in main settings)
    { x = 140, y = 180, radius = 135.0, start_angle = 0.0, end_angle = 360.0 }, -- Increased R, Adj Y
    { x = 140, y = 500, radius = 135.0, start_angle = 0.0, end_angle = 360.0 }, -- Calculated: 180 + 320
    { x = 140, y = 820, radius = 135.0, start_angle = 0.0, end_angle = 360.0 }, -- Calculated: 180 + 2*320
    { x = 140, y = 1140, radius = 135.0, start_angle = 0.0, end_angle = 360.0 }, -- Calculated: 180 + 3*320
    
    -- Clock and system circles (Increased radii, y adjusted in main settings)
    { x = 140, y = 1150, radius = 135.0, start_angle = 0.0, end_angle = 360.0 }, -- Increased R, Adj Y
}

function conky_ring_stats(cr)
    --[[
    IMPORTANT NOTES:
        regarding lua local function, it needs to be in sequence, caller needs to be at the bottom
        otherwise we'll get an error like below example:
            conky: llua_do_call: 
            function conky_main execution failed: /home/dirn/.config/conky/hybrid/lua/hybrid-rings.lua:555: 
            attempt to call a nil value (global 'setup_fs_text')
    ]]


    local function write_circle_char(cr, display_char, tset, degrads, deg, ival)
        local interval = (degrads * (tset.s_angle + (deg * (ival - 1)))) + tset.l_position
        local interval2 = degrads * (tset.s_angle + (deg * (ival - 1)))
        local txs = 0 + tset.text_radius * (math.sin(interval))
        local tys = 0 - tset.text_radius * (math.cos(interval))

        cairo_move_to (cr, txs + tset.x, tys + tset.y);
        cairo_rotate (cr, interval2)
        
        cairo_show_text (cr, display_char)
        cairo_rotate (cr, -interval2)
    end


    local function setup_circle_text(cr, display_text, tset)
        -- display_text = "hello world!"
        -- radi, horiz, verti, tcolor, talpha, start, finish, var1 = 63, 140, 140, 0xffffff, 1, 0, 70, 0

        local ival, has_celsius, sub_text = 1, false, display_text;
        local inum = string.len(display_text)
        range = tset.e_angle
        deg = (tset.e_angle - tset.s_angle) / (inum - 1)
        degrads = 1 * (math.pi / 180)

        if string.match(display_text, "°C") then
            has_celsius = true
            sub_text = string.gsub(display_text, "°C", "")
            inum = string.len(sub_text)
            -- print(sub_text)
        end

        for s_char in string.gmatch(sub_text, "(.)") do
            write_circle_char(cr, s_char, tset, degrads, deg, ival)
            ival = ival + 1
            -- print(ival, inum, s_char)

            -- special handling for °C character
            if ival > inum and has_celsius then
                write_circle_char(cr, "°C", tset, degrads, deg, ival)
            end
        end
    end


    local function setup_fs_text(cr, tset, value)
        local str = string.format( "%s %s", tset.text, value ) .. '%'
        
        -- setup_circle_text(cr, str, tset)
        cairo_move_to (cr, tset.x, tset.y)
        cairo_show_text (cr, str)
    end


    local function setup_cpu_text(cr, tset, value)
        local str = ''
        local thread_num = tonumber(tset.text)

        str = string.format( "%02d", tset.text )
        cairo_move_to (cr, tset.x, tset.y)
        cairo_show_text (cr, str)

        str = string.format( "%s", value ) .. '%'
        cairo_move_to (cr, tset.x + 17, tset.y)
        cairo_show_text (cr, str)
    end


    local function setup_other_text(cr, pt, tset, value)
        local str = ''

        if pt.name == 'platform' then
            str = string.format( "%s %d", tset.text, value ) .. "°C"
        elseif pt.name == 'time' then
            str = string.format( "%02d", value )
        else
            str = string.format( "%s %d", tset.text, value ) .. "%"
        end

        cairo_move_to (cr, tset.x, tset.y)
        cairo_show_text (cr, str)
    end


    local function setup_text(cr, value, pt, tset)
        local font_name = 'NotoSans'
        local font_colour = g_main_colour
        local font_size = 18 -- Increased from 14
        local str = ''
    
        cairo_set_source_rgb(cr,rgb_to_r_g_b(font_colour))
    
        cairo_select_font_face (cr, font_name, CAIRO_FONT_SLANT_BOLD, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size (cr, font_size)

        if pt.name == 'fs_used_perc' then
            setup_fs_text(cr, tset, value)
        elseif pt.name == 'cpu' then
            setup_cpu_text(cr, tset, value)
        else
            setup_other_text(cr, pt, tset, value)
        end
    
        cairo_fill_preserve (cr)
        cairo_stroke (cr)
        cairo_fill (cr)
    end


    local function draw_ring(cr, t, pt)
        local w, h = conky_window.width, conky_window.height
        
        local xc, yc, ring_r, ring_w, sa, ea = pt.x, pt.y, pt.radius, pt.thickness, pt.start_angle, pt.end_angle
        local bgc, bga, fgc, fga = pt.bg_colour, pt.bg_alpha, pt.fg_colour, pt.fg_alpha
    
        local angle_0 = sa * (2 * math.pi / 360) - math.pi / 2
        local angle_f = ea * (2 * math.pi / 360) - math.pi / 2
        local t_arc = t * (angle_f - angle_0)
    
        -- Draw background ring
    
        cairo_arc(cr, xc, yc, ring_r, angle_0, angle_f)
        cairo_set_source_rgba(cr, rgb_to_r_g_b(bgc, bga))
        cairo_set_line_width(cr, ring_w)
        cairo_stroke(cr)
        
        -- Draw indicator ring
    
        cairo_arc(cr, xc, yc, ring_r, angle_0, angle_0 + t_arc)
        cairo_set_source_rgba(cr, rgb_to_r_g_b(fgc, fga))
        cairo_stroke(cr)		
    end


    local function level_watch(level_pct, pt)
        local warn_level = 0
        local crit_level = 0
        
        if pt.name ~= 'time' then
            warn_level = 80
            crit_level = 92

            if level_pct < warn_level then
                pt.fg_colour = normal
            elseif level_pct >= warn_level and level_pct < crit_level then
                pt.fg_colour = warn
            else
                pt.fg_colour = crit
            end
        end
    end


	local function setup_rings(cr, pt)
		local str = ''
		local value = 0

        if pt.name == 'platform' then
            local handle = io.popen('cd /sys/devices/platform/coretemp.0/hwmon/;echo hwmon*')
            local output = handle:read('*a')
            handle:close()
            -- print(output)

            pt.arg = string.gsub( pt.arg, 'hwmon_x', output )
        end

        str = string.format('${%s %s}', pt.name, pt.arg)
        str = conky_parse(str)
        if str == '' then str = '0' end
        
        value = tonumber(str)
        display_value = value

        if pt.name == 'time' and pt.arg == '%H' and value >= 12 then
            value = value - 12
        end

		if value == nil then value = 0 end
        local pct = value / pt.max
        local level_watch_pct = pct * 100

        -- level watch should check percentage, not value
        level_watch(level_watch_pct, pt)
        draw_ring(cr, pct, pt)
        
        local tset = text_settings[pt.text_id]
        if tset == nil then return end

        if tset.show then
            setup_text(cr, display_value, pt, tset)
        end
    end


	local updates=conky_parse('${updates}')
	update_num = tonumber(updates)

	if update_num > update_num_min then
	    for i in pairs(settings_table) do
            setup_rings(cr, settings_table[i])
	    end
    end
end


function draw_elements(line_sketches_toggle)
    local function draw_text_indicator(cr)
        local line_colour, line_thick = g_main_colour, 0.5
        
        for x in pairs(text_settings) do
            -- the usage of continue and ::continue:: is
            -- not backward compatible with lua older version.

            local text_item = text_settings[x]
            
            if text_item ~= nil and text_item.ind_id ~= nil then
                local i_item = text_indicator[text_item.ind_id]
    
                if i_item ~= nil then
                    cairo_set_source_rgba(cr, rgb_to_r_g_b(line_colour, i_item.alpha))
                    cairo_set_line_width(cr, line_thick)
            
                    cairo_move_to (cr, i_item.x1, i_item.y1)
                    cairo_line_to (cr, i_item.x2, i_item.y2)
                    cairo_line_to (cr, i_item.x3, i_item.y3)
                    cairo_stroke (cr)
                end
            end
        end
    end
    
    
    local function draw_lines(cr)
        for x in pairs(line_settings) do
            local l_item = line_settings[x]
            
            cairo_move_to (cr, l_item.x1, l_item.y1)
            cairo_line_to (cr, l_item.x2, l_item.y2)
            cairo_stroke (cr)
        end
    end
    
    
    local function draw_circles(cr)
        -- xc = 250.0
        -- yc = 255.0
        -- radius = 50.0
        -- angle1 = 0.0  * (2 * math.pi / 360) - math.pi / 2
        -- angle2 = 360.0 * (2 * math.pi / 360) - math.pi / 2
    
        for x in pairs(circle_settings) do
            local c_item = circle_settings[x]
            
            local angle_s = c_item.start_angle * (2 * math.pi / 360) - math.pi / 2
            local angle_e = c_item.end_angle * (2 * math.pi / 360) - math.pi / 2
    
            cairo_arc (cr, c_item.x, c_item.y, c_item.radius, angle_s, angle_e)
            cairo_stroke (cr)
        end
    end
    
    
    local function draw_line_sketches(cr, line_sketches_toggle)
        if to_boolean(line_sketches_toggle) == false then 
            return
        end
    
        local line_colour, line_alpha, line_thick = g_main_colour, 0.15, 1.0
    
        cairo_set_source_rgba(cr, rgb_to_r_g_b(line_colour, line_alpha))
        cairo_set_line_width(cr, line_thick)
        
        draw_lines(cr)
        draw_circles(cr)
    end
    
    
    local function draw_logo(cr)
        local w, h = 0, 0
        local imagefile = home_dir .. "/.config/conky/images/fedora_a.png"
        local image = cairo_image_surface_create_from_png (imagefile)
    
        w = cairo_image_surface_get_width (image)
        h = cairo_image_surface_get_height (image)
    
        cairo_translate (cr, 495.0, 32.0)
        -- cairo_rotate (cr, 45* math.pi/180)
        cairo_scale  (cr, 40.0/w, 40.0/h)
        -- cairo_translate (cr, -0.5*w, -0.5*h)
    
        cairo_set_source_surface (cr, image, 0, 0)
        cairo_paint (cr)
        cairo_surface_destroy (image)

        -- Reset translation and scaling
        cairo_identity_matrix(cr) 
    end


    if conky_window == nil then return end

    local cs = cairo_xlib_surface_create(conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        conky_window.width,
        conky_window.height)
    local cr = cairo_create(cs)

    draw_line_sketches(cr, line_sketches_toggle)
    draw_text_indicator(cr)
    conky_ring_stats(cr)
    draw_logo(cr)           -- logo needs to be render last due to cairo_set_source_surface

    cairo_surface_destroy(cs)
    cairo_destroy(cr)
end


function conky_main(line_sketches_toggle)
    draw_elements(line_sketches_toggle)
end