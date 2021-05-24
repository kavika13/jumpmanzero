local Module = {};

local g_is_exit_requested = false;
local g_is_debug_level_mode = false;
local g_has_not_started_menu_music = true;

local g_level_module = nil;
local g_level_title = nil;
local g_level_set_current_levels = nil;
local g_level_set_current_level_index = 0;
local g_queued_level_load = nil;

local g_remaining_life_count;  -- TODO: This variable probably shouldn't live here. Should be in game_logic.lua instead

local function get_new_sandbox_env()
    return {
        -- TODO: Verify all these are safe to include in the sandbox. See http://lua-users.org/wiki/SandBoxes
        --       This now includes things for 5.2, but the safety of all the included functions have not been vetted.
        -- TODO: Add back functions to support shimming of Lua 5.1 scripts without modification.
        _VERSION = _VERSION,
        assert = assert,
        coroutine = {
            create = coroutine.create,
            isyieldable = coroutine.isyieldable,  -- TODO: Is this safe to include?
            resume = coroutine.resume,
            running = coroutine.running,
            status = coroutine.status,
            wrap = coroutine.wrap,
            yield = coroutine.yield,
        },
        error = error,
        io = {
            flush = io.flush,
            read = io.read,
            stderr = io.stderr,
            stdout = io.stdout,
            type = io.type,
            write = io.write,
        },
        ipairs = ipairs,
        loadfile = loadfile,  -- TODO: Probably unsafe. Need to figure out alternative
        math = {
            abs = math.abs,
            acos = math.acos,
            asin = math.asin,
            atan = math.atan,
            atan2 = math.atan,  -- Here for 5.1 backwards compat
            ceil = math.ceil,
            cos = math.cos,
            -- cosh  -- TODO: Add Lua 5.1 shim for this
            deg = math.deg,
            exp = math.exp,
            floor = math.floor,
            fmod = math.fmod,
            -- frexp  -- TODO: Add Lua 5.1 shim for this
            huge = math.huge,
            -- ldexp  -- TODO: Add Lua 5.1 shim for this
            log = math.log,
            -- log10  -- TODO: Add Lua 5.1 shim for this
            max = math.max,
            maxinteger = math.maxinteger,
            min = math.min,
            mininteger = math.mininteger,
            modf = math.modf,
            pi = math.pi,
            -- pow  -- TODO: Add Lua 5.1 shim for this
            rad = math.rad,
            random = math.random,
            -- Unsafe so commenting out: randomseed = math.randomseed,
            sin = math.sin,
            -- sinh  -- TODO: Add Lua 5.1 shim for this
            sqrt = math.sqrt,
            tan = math.tan,
            -- tanh  -- TODO: Add Lua 5.1 shim for this
            tointeger = math.tointeger,  -- TODO: Is this safe to include?
            type = math.type,  -- TODO: Is this safe to include?
            ult = math.ult,  -- TODO: Is this safe to include?
        },
        next = next,
        os = {
            clock = os.clock,
            difftime = os.difftime,
            time = os.time,
        },
        pairs = pairs,
        pcall = pcall,
        print = print,
        require = require,  -- TODO: Probably unsafe. Need to figure out alternative
        select = select,
        string = {
            byte = string.byte,
            char = string.char,
            -- Unsafe so commenting out: dump = string.dump,
            find = string.find,
            format = string.format,
            gmatch = string.gmatch,
            gsub = string.gsub,
            len = string.len,
            lower = string.lower,
            match = string.match,
            pack = string.pack,  -- TODO: Is this safe to include?
            packsize = string.packsize,  -- TODO: Is this safe to include?
            rep = string.rep,
            reverse = string.reverse,
            sub = string.sub,
            unpack = string.unpack,  -- TODO: Is this safe to include?
            upper = string.upper,
        },
        table = {
            concat = table.concat,  -- TODO: Is this safe to include?
            insert = table.insert,
            maxn = table.maxn,
            move = table.move,  -- TODO: Is this safe to include?
            pack = table.pack,  -- TODO: Is this safe to include?
            remove = table.remove,
            sort = table.sort,
            unpack = table.unpack,
        },
        tonumber = tonumber,
        tostring = tostring,
        type = type,
        unpack = unpack or table.unpack,  -- Here for 5.1 backwards compat
        utf8 = {
            char = utf8.char,  -- TODO: Is this safe to include?
            charpattern = utf8.charpattern,  -- TODO: Is this safe to include?
            codepoint = utf8.codepoint,  -- TODO: Is this safe to include?
            codes = utf8.codes,  -- TODO: Is this safe to include?
            len = utf8.len,  -- TODO: Is this safe to include?
            offset = utf8.offset,  -- TODO: Is this safe to include?
        },
        xpcall = xpcall,

        -- Lua API from engine
        -- TODO: Easier way to copy these over?
        -- unload_all_resources = unload_all_resources,
        -- begin_loading_3d_data = begin_loading_3d_data,
        -- end_and_commit_loading_3d_data = end_and_commit_loading_3d_data,
        play_music_track_1 = play_music_track_1,
        stop_music_track_1 = stop_music_track_1,
        play_music_track_2 = play_music_track_2,
        load_sound = load_sound,
        load_texture = load_texture,
        load_mesh = load_mesh,
        set_mesh_to_mesh = set_mesh_to_mesh,
        set_identity_mesh_matrix = set_identity_mesh_matrix,
        undo_camera_perspective_on_mesh_matrix = undo_camera_perspective_on_mesh_matrix,
        translate_mesh_matrix = translate_mesh_matrix,
        scale_mesh_matrix = scale_mesh_matrix,
        rotate_x_mesh_matrix = rotate_x_mesh_matrix,
        rotate_y_mesh_matrix = rotate_y_mesh_matrix,
        rotate_z_mesh_matrix = rotate_z_mesh_matrix,
        scroll_texture_on_mesh = scroll_texture_on_mesh,
        skip_next_mesh_interpolation = skip_next_mesh_interpolation,
        set_mesh_texture = set_mesh_texture,
        set_mesh_is_visible = set_mesh_is_visible,
        transform_create = transform_create,
        transform_delete = transform_delete,
        transform_get_parent = transform_get_parent,
        transform_set_parent = transform_set_parent,
        transform_clear_parent = transform_clear_parent,
        transform_get_parent_is_camera = transform_get_parent_is_camera,
        transform_set_parent_is_camera = transform_set_parent_is_camera,
        object_get_transform = object_get_transform,
        object_set_transform = object_set_transform,
        object_clear_transform = object_clear_transform,
        transform_set_to_identity = transform_set_to_identity,
        transform_set_translation = transform_set_translation,
        transform_clear_translation = transform_clear_translation,
        transform_set_rotation_x = transform_set_rotation_x,
        transform_set_rotation_y = transform_set_rotation_y,
        transform_set_rotation_z = transform_set_rotation_z,
        transform_concat_rotation_x = transform_concat_rotation_x,
        transform_concat_rotation_y = transform_concat_rotation_y,
        transform_concat_rotation_z = transform_concat_rotation_z,
        transform_clear_rotation = transform_clear_rotation,
        transform_set_scale = transform_set_scale,
        transform_clear_scale = transform_clear_scale,
        get_loaded_texture_count = get_loaded_texture_count,
        get_is_sound_enabled = get_is_sound_enabled,
        get_is_music_enabled = get_is_music_enabled,
        get_last_key_pressed = get_last_key_pressed,
        get_current_fps = get_current_fps,
        create_mesh = create_mesh,
        new_mesh = new_mesh,
        move_transparent_mesh_to_front = move_transparent_mesh_to_front,
        move_transparent_mesh_to_back = move_transparent_mesh_to_back,
        set_fog = set_fog,
        get_config_option_string = get_config_option_string,
        set_config_option = set_config_option,
        save_config_options = save_config_options,
        play_sound_effect = play_sound_effect,
        delete_mesh = delete_mesh,
        set_perspective = set_perspective,
        skip_next_camera_interpolation = skip_next_camera_interpolation,
    };
end

local function get_empty_input()
    return {
        move_left_action = { is_pressed = false, just_pressed = false },
        move_right_action = { is_pressed = false, just_pressed = false },
        move_down_action = { is_pressed = false, just_pressed = false },
        move_up_action = { is_pressed = false, just_pressed = false },
        jump_action = { is_pressed = false, just_pressed = false },
        attack_action = { is_pressed = false, just_pressed = false },
        select_action = { is_pressed = false, just_pressed = false },
        debug_action = { is_pressed = false, just_pressed = false },
    };
end

local function load_level(level_filename, before_initialize_level_callback)
    local new_level_module = assert(loadfile(level_filename, 't', get_new_sandbox_env()));
    local new_level_module_call_ok, new_level_module_result = pcall(new_level_module);
    assert(new_level_module_call_ok, new_level_module_result);

    g_level_module = new_level_module_result;

    if before_initialize_level_callback then
        before_initialize_level_callback(g_level_module);
    end

    unload_all_resources();
    set_fog(0, 0, 0, 0, 0);

    begin_loading_3d_data();
    g_level_module.initialize(get_empty_input());
    end_and_commit_loading_3d_data();

    collectgarbage("collect");
end

local function queue_load_level(level_filename, before_initialize_level_callback)
    g_queued_level_load = {
        filename = level_filename,
        before_initialize_level_callback = before_initialize_level_callback,
    };
end

-- Functions are interdependent, so must pre-declare them
local load_debug_level;
local load_debug_game_over;

load_debug_level = function(debug_level_filename)
    g_remaining_life_count = 5;  -- TODO: Should be in game_logic.lua instead
    queue_load_level(
        debug_level_filename,
        function(level_module)
            level_module.MenuLogic = {
                get_current_level_title = function() return ""; end,
                load_next_level_from_set = function() load_debug_level(debug_level_filename); end,
                load_game_over = function() load_debug_game_over(debug_level_filename); end,
                -- TODO: These probably shouldn't live in this file, should be in game_logic.lua instead
                get_remaining_life_count = function() return g_remaining_life_count; end,
                set_remaining_life_count = function(new_life_count) g_remaining_life_count = new_life_count; end,
            };
        end);
end

load_debug_game_over = function(debug_level_filename)
    queue_load_level(
        "data/gameover.lua",
        function(level_module)
            level_module.MenuLogic = {
                load_next_level_from_set = function() load_debug_level(debug_level_filename); end,
            };
        end);
end

-- This is a web of interdependencies, so must pre-declare them
local load_main_menu;
local load_options_menu;
local load_credits;
local load_select_game_menu;
local game_start;
local load_next_level_from_set;
local load_game_over;

load_main_menu = function(is_from_game_launch, is_from_level)
    queue_load_level(
        "data/mainmenu.lua",
        function(level_module)
            level_module.MenuLogic = {
                load_select_game_menu = load_select_game_menu,
                load_options_menu = load_options_menu,
                load_credits = load_credits,
            };

            -- TODO: Wrangle menu music in this main.lua script instead of in the menu level scripts themselves?
            if is_from_game_launch then
                level_module.SkipAnimation = false;
                level_module.StartIntroStingMusicTrack = true;
            end

            if is_from_level then
                level_module.StartMainMusicTrack = true;
                g_has_not_started_menu_music = false;
            end
        end);
end

load_select_game_menu = function()
    queue_load_level(
        "data/selectgame.lua",
        function(level_module)
            -- TODO: Wrangle menu music in this main.lua script instead of in the menu level scripts themselves?
            level_module.StartMainMusicTrack = g_has_not_started_menu_music;
            level_module.MenuLogic = {
                game_start = game_start,
            };
            g_has_not_started_menu_music = false;
        end);
end

load_options_menu = function()
    queue_load_level(
        "data/options.lua",
        function(level_module)
            -- TODO: Wrangle menu music in this main.lua script instead of in the menu level scripts themselves?
            level_module.StartMainMusicTrack = g_has_not_started_menu_music;
            level_module.MenuLogic = {
                load_main_menu = function() load_main_menu(false, false); end,
            };
            g_has_not_started_menu_music = false;
        end);
end

load_credits = function()
    queue_load_level(
        "data/ending.lua",
        function(level_module)
            level_module.SkipToCredits = true;
            level_module.MenuLogic = {
                get_current_level_title = function() return ""; end,
                load_next_level_from_set = function() load_main_menu(false, true); end,
                load_game_over = load_game_over,
                -- TODO: These probably shouldn't live in this file, should be in game_logic.lua instead
                get_remaining_life_count = function() return g_remaining_life_count; end,
                set_remaining_life_count = function(new_life_count) g_remaining_life_count = new_life_count; end,
            };
            g_has_not_started_menu_music = false;
        end);
end

game_start = function(level_set_index)
    local level_set = {  -- TODO: Load this from an external file?
        {
            { title = "Easy Does It", script_filename = "data/level1.lua" },
            { title = "Followers", script_filename = "data/level20.lua" },
            { title = "Disorderly", script_filename = "data/level14.lua" },
            { title = "Hot. Hot. Hot.", script_filename = "data/level8.lua" },
            { title = "Flash Flood", script_filename = "data/level7.lua" },
            { title = "The Hive", script_filename = "data/level12.lua" },
            { title = "Downside Up", script_filename = "data/level17.lua" },
            { title = "Tree Huggers", script_filename = "data/level24.lua" },
            { title = "Final Battle", script_filename = "data/level27.lua" },
            { title = "Congratulations", script_filename = "data/ending.lua" },
        },
        {
            { title = "Solid Ground", script_filename = "data/level15.lua" },
            { title = "No Rush", script_filename = "data/level16.lua" },
            { title = "Clockwork", script_filename = "data/level22.lua" },
            { title = "...Now You Don't", script_filename = "data/level13.lua" },
            { title = "Great White North", script_filename = "data/level5.lua" },
            { title = "La Garra", script_filename = "data/level23.lua" },
            { title = "Gauntlet", script_filename = "data/level19.lua" },
            { title = "Big Game", script_filename = "data/level11.lua" },
            { title = "Final Battle", script_filename = "data/level27.lua" },
            { title = "Congratulations", script_filename = "data/ending.lua" },
        },
        {
            { title = "Flicker", script_filename = "data/level6.lua" },
            { title = "When It Rains...", script_filename = "data/level2.lua" },
            { title = "Fyodor", script_filename = "data/level3.lua" },
            { title = "Infestation", script_filename = "data/level10.lua" },
            { title = "High Strung", script_filename = "data/level9.lua" },
            { title = "A Difficult Assignment", script_filename = "data/level18.lua" },
            { title = "Wonky Frog", script_filename = "data/level21.lua" },
            { title = "Jump the Shark", script_filename = "data/level25.lua" },
            { title = "Final Battle", script_filename = "data/level27.lua" },
            { title = "Congratulations", script_filename = "data/ending.lua" },
        },
    };

    g_remaining_life_count = 7;  -- TODO: Should be in game_logic.lua instead
    g_level_set_current_levels = level_set[level_set_index];
    g_level_set_current_level_index = 0;
    load_next_level_from_set();
end

load_next_level_from_set = function()
    g_level_set_current_level_index = g_level_set_current_level_index + 1;
    local current_level = g_level_set_current_levels[g_level_set_current_level_index];

    if current_level then
        g_level_title = current_level.title;
        queue_load_level(
            current_level.script_filename,
            function(level_module)
                level_module.MenuLogic = {
                    get_current_level_title = function() return g_level_title; end,
                    load_next_level_from_set = load_next_level_from_set,
                    load_game_over = load_game_over,
                    -- TODO: These probably shouldn't live in this file, should be in game_logic.lua instead
                    get_remaining_life_count = function() return g_remaining_life_count; end,
                    set_remaining_life_count = function(new_life_count) g_remaining_life_count = new_life_count; end,
                };
            end);
    else
        load_main_menu(false, true);
    end
end

load_game_over = function()
    queue_load_level(
        "data/gameover.lua",
        function(level_module)
            level_module.MenuLogic = {
                load_next_level_from_set = function() load_main_menu(false, true); end,
            };
        end);
end

function Module.initialize(initial_level_name)
    if initial_level_name then
        g_is_debug_level_mode = true;
        local initial_level_filename = "data/" .. initial_level_name .. ".lua";
        load_debug_level(initial_level_filename);
    else
        load_main_menu(true, false);
    end
end

function Module.update(game_input)
    if g_is_exit_requested then
        return;
    end

    -- Level loads are queued so the previous level doesn't accidentally clobber data after the new level is loaded
    if g_queued_level_load then
        load_level(g_queued_level_load.filename, g_queued_level_load.before_initialize_level_callback)
        g_queued_level_load = nil;
        return;
    end

    g_level_module.update(game_input);
end

function Module.on_exit_requested()
    g_is_exit_requested = true;
end

return Module
