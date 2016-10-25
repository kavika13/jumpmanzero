#include <SDL2/SDL.h>
#include "input.hpp"

namespace Jumpman {

enum class ActionSet {
  kMenuControls,
  kGameControls,
};

Input::Input()
  : name_to_set_map_ {
      { "MenuControls",
        static_cast<ControllerActionSetHandle>(ActionSet::kMenuControls) },
      { "GameControls",
        static_cast<ControllerActionSetHandle>(ActionSet::kGameControls) },
    }
  , digital_set_to_state_map_ {
      { "menu_up", DigitalControllerActionState() },
      { "menu_down", DigitalControllerActionState() },
      { "menu_left", DigitalControllerActionState() },
      { "menu_right", DigitalControllerActionState() },
      { "menu_select", DigitalControllerActionState() },
      { "menu_cancel", DigitalControllerActionState() },
      { "move_up", DigitalControllerActionState() },
      { "move_down", DigitalControllerActionState() },
      { "move_left", DigitalControllerActionState() },
      { "move_right", DigitalControllerActionState() },
      { "jump", DigitalControllerActionState() },
      { "attack", DigitalControllerActionState() },
      { "toggle_menu", DigitalControllerActionState() },
    }
  , analog_set_to_state_map_ {
      { "menu_move", AnalogControllerActionState() },
    } {
}

void Input::Update() {
  SDL_Event event;

  auto on_pressed = [](auto& state) {
    state.was_just_pressed = !state.is_pressed;
    state.is_pressed = true;
    state.is_released = state.was_just_released = false;
  };
  auto on_released = [](auto& state) {
    state.was_just_released = !state.is_released;
    state.is_released = true;
    state.is_pressed = state.was_just_pressed = false;
  };

  for (auto& pair: digital_set_to_state_map_) {
    pair.second.was_just_pressed = false;
    pair.second.was_just_released = false;
  }

  // TODO: Bind keys dynamically from configuration

  while (SDL_PollEvent(&event)) {
    switch (static_cast<ActionSet>(current_action_)) {
      case ActionSet::kMenuControls: {
        switch (event.type) {
          case SDL_MOUSEMOTION: {
            auto& state = analog_set_to_state_map_["menu_move"];
            state.mode = ControllerSourceMode::kAbsoluteMouse;
            state.x = event.motion.x;
            state.y = event.motion.y;
            break;
          }
          case SDL_MOUSEBUTTONDOWN:
            on_pressed(digital_set_to_state_map_["menu_select"]);
            break;
          case SDL_MOUSEBUTTONUP:
            on_released(digital_set_to_state_map_["menu_select"]);
            break;
          case SDL_KEYDOWN: {
            switch (event.key.keysym.sym) {
              case SDLK_UP:
                on_pressed(digital_set_to_state_map_["menu_up"]);
                break;
              case SDLK_DOWN:
                on_pressed(digital_set_to_state_map_["menu_down"]);
                break;
              case SDLK_RIGHT:
                on_pressed(digital_set_to_state_map_["menu_right"]);
                break;
              case SDLK_LEFT:
                on_pressed(digital_set_to_state_map_["menu_left"]);
                break;
              case SDLK_RETURN:
              case SDLK_SPACE:
              case SDLK_KP_ENTER:
              case SDLK_z:
              case SDLK_x:
                on_pressed(digital_set_to_state_map_["menu_select"]);
                break;
              case SDLK_ESCAPE:
                on_pressed(digital_set_to_state_map_["menu_cancel"]);
                on_pressed(digital_set_to_state_map_["toggle_menu"]);
                break;
            }
            break;
          }
          case SDL_KEYUP: {
            switch (event.key.keysym.sym) {
              case SDLK_UP:
                on_released(digital_set_to_state_map_["menu_up"]);
                break;
              case SDLK_DOWN:
                on_released(digital_set_to_state_map_["menu_down"]);
                break;
              case SDLK_RIGHT:
                on_released(digital_set_to_state_map_["menu_right"]);
                break;
              case SDLK_LEFT:
                on_released(digital_set_to_state_map_["menu_left"]);
                break;
              case SDLK_RETURN:
              case SDLK_SPACE:
              case SDLK_KP_ENTER:
              case SDLK_z:
              case SDLK_x:
                on_released(digital_set_to_state_map_["menu_select"]);
                break;
              case SDLK_ESCAPE:
                on_released(digital_set_to_state_map_["menu_cancel"]);
                on_released(digital_set_to_state_map_["toggle_menu"]);
                break;
            }
            break;
          }
        }
        break;
      }
      case ActionSet::kGameControls: {
        switch (event.type) {
          case SDL_KEYDOWN: {
            switch (event.key.keysym.sym) {
              case SDLK_UP:
                on_pressed(digital_set_to_state_map_["move_up"]);
                break;
              case SDLK_DOWN:
                on_pressed(digital_set_to_state_map_["move_down"]);
                break;
              case SDLK_RIGHT:
                on_pressed(digital_set_to_state_map_["move_right"]);
                break;
              case SDLK_LEFT:
                on_pressed(digital_set_to_state_map_["move_left"]);
                break;
              case SDLK_RETURN:
              case SDLK_SPACE:
              case SDLK_KP_ENTER:
                on_pressed(digital_set_to_state_map_["jump"]);
                break;
              case SDLK_z:
              case SDLK_x:
                on_pressed(digital_set_to_state_map_["attack"]);
                break;
              case SDLK_ESCAPE:
                on_pressed(digital_set_to_state_map_["toggle_menu"]);
                break;
            }
            break;
          }
          case SDL_KEYUP: {
            switch (event.key.keysym.sym) {
              case SDLK_UP:
                on_released(digital_set_to_state_map_["move_up"]);
                break;
              case SDLK_DOWN:
                on_released(digital_set_to_state_map_["move_down"]);
                break;
              case SDLK_RIGHT:
                on_released(digital_set_to_state_map_["move_right"]);
                break;
              case SDLK_LEFT:
                on_released(digital_set_to_state_map_["move_left"]);
                break;
              case SDLK_RETURN:
              case SDLK_SPACE:
              case SDLK_KP_ENTER:
                on_released(digital_set_to_state_map_["jump"]);
                break;
              case SDLK_z:
              case SDLK_x:
                on_released(digital_set_to_state_map_["attack"]);
                break;
              case SDLK_ESCAPE:
                on_released(digital_set_to_state_map_["toggle_menu"]);
                break;
            }
            break;
          }
          break;
        }
      }
    }
  }
}

void Input::ActivateActionSet(const std::string& set_name) {
  auto iter = name_to_set_map_.find(set_name);

  if (iter == name_to_set_map_.end()) {
    throw std::runtime_error("Invalid set name: " + set_name);
  }

  current_action_ = iter->second;
}

DigitalControllerActionState Input::GetDigitalActionState(
    const std::string& action_name) {
  auto iter = digital_set_to_state_map_.find(action_name);

  if (iter == digital_set_to_state_map_.end()) {
    throw std::runtime_error("Invalid action name: " + action_name);
  }

  return iter->second;
}

AnalogControllerActionState Input::GetAnalogActionState(
    const std::string& action_name) {
  auto iter = analog_set_to_state_map_.find(action_name);

  if (iter == analog_set_to_state_map_.end()) {
    throw std::runtime_error("Invalid action name: " + action_name);
  }

  return iter->second;
}

};  // namespace Jumpman
