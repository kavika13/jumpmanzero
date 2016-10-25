#ifndef ENGINE_INPUT_HPP_
#define ENGINE_INPUT_HPP_

#include <string>
#include <unordered_map>

namespace Jumpman {

struct DigitalControllerActionState {
  bool is_pressed;
  bool was_just_pressed;
  bool is_released;
  bool was_just_released;
};

enum class ControllerSourceMode {
	kAbsoluteMouse
};

struct AnalogControllerActionState {
  ControllerSourceMode mode;
  float x;
  float y;
};

class Input {
 public:
  typedef uint64_t ControllerHandle;

  Input();

  void Update();

  void ActivateActionSet(const std::string& set_name);
  DigitalControllerActionState GetDigitalActionState(
    const std::string& action_name);
  AnalogControllerActionState GetAnalogActionState(
    const std::string& action_name);

 private:
  typedef uint64_t ControllerActionSetHandle;

  ControllerActionSetHandle current_action_;
  std::unordered_map<std::string, ControllerActionSetHandle> name_to_set_map_;
  std::unordered_map<std::string, DigitalControllerActionState>
    digital_set_to_state_map_;
  std::unordered_map<std::string, AnalogControllerActionState>
    analog_set_to_state_map_;
};

};  // namespace Jumpman

#endif  // ENGINE_INPUT_HPP_
