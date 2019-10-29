local Module = {};

local g_is_exit_requested = false;
local g_is_debug_level_mode = false;
local g_is_in_menu = false;
local g_has_not_started_menu_music = true;

local g_level_module = nil;
local g_level_title = nil;
local g_level_set_current_levels = nil;
local g_level_set_current_level_index = 0;
local g_queued_level_load = nil;

local g_remaining_life_count;  -- TODO: This variable probably shouldn't live here. Should be in game_logic.lua instead

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
    -- TODO: Sandbox load to protect global scope?
    local new_level_module = assert(loadfile(level_filename));
    g_level_module = new_level_module();

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
local load_select_game_menu;
local game_start;
local load_next_level_from_set;
local load_game_over;

load_main_menu = function(is_from_game_launch, is_from_level)
    queue_load_level(
        "data/mainmenu.lua",
        function(level_module)
            g_is_in_menu = true;
            level_module.MenuLogic = {
                load_select_game_menu = load_select_game_menu,
                load_options_menu = load_options_menu,
            };

            -- TODO: Wrangle menu music in this main.lua script instead of in the menu level scripts themselves?
            if is_from_game_launch then
                level_module.SkipAnimation = false;
                level_module.StartIntroStingMusicTrack = true;
            end

            if is_from_level then
                level_module.StartMainMusicTrack = true;
            end
        end);
end

load_select_game_menu = function()
    queue_load_level(
        "data/selgame.lua",
        function(level_module)
            g_is_in_menu = true;
            -- TODO: Wrangle menu music in this main.lua script instead of in the menu level scripts themselves?
            level_module.StartMainMusicTrack = g_has_not_started_menu_music;
            level_module.MenuLogic = {
                game_start = game_start,
            };
        end);
end

load_options_menu = function()
    -- TODO: Wrangle menu music in this script instead of in the menu level scripts themselves?
    queue_load_level(
        "data/options.lua",
        function(level_module)
            g_is_in_menu = true;
            -- TODO: Wrangle menu music in this main.lua script instead of in the menu level scripts themselves?
            level_module.StartMainMusicTrack = g_has_not_started_menu_music;
            level_module.MenuLogic = {
                load_main_menu = function() load_main_menu(false, false); end,
            };
        end);

    g_has_not_started_menu_music = false;
end

game_start = function(level_set_index)
    local level_set = {  -- TODO: Load this from an external file?
        {
            { title = "Easy Does It", script_filename = "data/script1.lua" },
            { title = "Followers", script_filename = "data/script20.lua" },
            { title = "Disorderly", script_filename = "data/script14.lua" },
            { title = "Hot. Hot. Hot.", script_filename = "data/script8.lua" },
            { title = "Flash Flood", script_filename = "data/script7.lua" },
            { title = "The Hive", script_filename = "data/script12.lua" },
            { title = "Downside Up", script_filename = "data/script17.lua" },
            { title = "Tree Huggers", script_filename = "data/script24.lua" },
            { title = "Final Battle", script_filename = "data/script27.lua" },
            { title = "Congratulations", script_filename = "data/ending.lua" },
        },
        {
            { title = "Solid Ground", script_filename = "data/script15.lua" },
            { title = "No Rush", script_filename = "data/script16.lua" },
            { title = "Clockwork", script_filename = "data/script22.lua" },
            { title = "...Now You Don't", script_filename = "data/script13.lua" },
            { title = "Great White North", script_filename = "data/script5.lua" },
            { title = "La Garra", script_filename = "data/script23.lua" },
            { title = "Gauntlet", script_filename = "data/script19.lua" },
            { title = "Big Game", script_filename = "data/script11.lua" },
            { title = "Final Battle", script_filename = "data/script27.lua" },
            { title = "Congratulations", script_filename = "data/ending.lua" },
        },
        {
            { title = "Flicker", script_filename = "data/script6.lua" },
            { title = "When It Rains...", script_filename = "data/script2.lua" },
            { title = "Fyodor", script_filename = "data/script3.lua" },
            { title = "Infestation", script_filename = "data/script10.lua" },
            { title = "High Strung", script_filename = "data/script9.lua" },
            { title = "A Difficult Assignment", script_filename = "data/script18.lua" },
            { title = "Wonky Frog", script_filename = "data/script21.lua" },
            { title = "Jump the Shark", script_filename = "data/script25.lua" },
            { title = "Final Battle", script_filename = "data/script27.lua" },
            { title = "Congratulations", script_filename = "data/ending.lua" },
        },
    };

    g_remaining_life_count = 7;  -- TODO: Should be in game_logic.lua instead
    g_level_set_current_levels = level_set[level_set_index];
    g_level_set_current_level_index = 0;
    load_next_level_from_set();
    g_is_in_menu = false;
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

    if g_is_in_menu then
        set_perspective(80.0, 80.0, -100.0, 80.0, 80.0, 0.0);
    end
end

function Module.on_exit_requested()
    g_is_exit_requested = true;
end

return Module
