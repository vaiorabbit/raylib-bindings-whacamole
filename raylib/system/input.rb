require 'raylib'

class KeyStatus
  attr_accessor :down, :prev_down, :trigger, :release, :repeat, :repeat_count
  attr_reader :repeat_enabled, :repeat_start, :repeat_interval

  def initialize(repeat_enabled = false, repeat_start = 0, repeat_interval = 0)
    @repeat_enabled = repeat_enabled
    @repeat_start = repeat_start
    @repeat_interval = repeat_interval

    clear_flags
  end

  def clear_flags
    @down = 0
    @prev_down = 0
    @trigger = 0
    @release = 0
    @repeat = 0
    @repeat_count = 0
  end

  def update
    @trigger = ~@prev_down & @down
    @release = @prev_down & ~@down

    @prev_down = @down

    return unless @repeat_enabled

    if @down.zero?
      @repeat = 0
      return
    end

    if @trigger.zero?
      @repeat_count -= 1
      @repeat = 0
      if @repeat_count <= 0
        @repeat_count = @repeat_interval
        @repeat = 1
      end
    else
      @repeat_count = @repeat_start
    end
  end
end

class AxisStatus
  BUTTON_DIRECTION = {
    both: 0,
    positive: 1,
    negative: -1
  }.freeze

  attr_reader :handle_as_button, :button_direction, :button_threshold
  attr_accessor :value

  def initialize(handle_as_button = false, button_direction = :both, button_threshold = 3000, repeat_enabled: false, repeat_start: 0, repeat_interval: 0)
    @value = 0
    @handle_as_button = handle_as_button
    @button_direction = button_direction
    @button_threshold = button_threshold
    @key_status = handle_as_button ? KeyStatus.new(repeat_enabled, repeat_start, repeat_interval) : nil
  end

  def down = @key_status.down
  def trigger = @key_status.trigger
  def repeat = @key_status.repeat
  def release = @key_status.release

  def clear_flags
    @key_status&.clear_flags
  end

  def update
    return unless @handle_as_button

    @key_status.down = case @button_direction
                       when :positive
                         @value >= @button_threshold ? 1 : 0
                       when :negative
                         @value <= -@button_threshold ? 1 : 0
                       else
                         @key_status.down
                       end
    @key_status.update
  end
end

class GamePad
  # Axis symbols
  AXIS_LEFTX = Raylib::GAMEPAD_AXIS_LEFT_X
  AXIS_LEFTY = Raylib::GAMEPAD_AXIS_LEFT_Y
  AXIS_RIGHTX = Raylib::GAMEPAD_AXIS_RIGHT_X
  AXIS_RIGHTY = Raylib::GAMEPAD_AXIS_RIGHT_Y
  AXIS_TRIGGERLEFT = Raylib::GAMEPAD_AXIS_LEFT_TRIGGER
  AXIS_TRIGGERRIGHT = Raylib::GAMEPAD_AXIS_RIGHT_TRIGGER
  AXIS_MAX = 6

  attr_reader :game_controller, :gamepad_id

  def initialize(game_controller, gamepad_id)
    @game_controller = game_controller
    @gamepad_id = gamepad_id
    @axis_values = Array.new(AXIS_MAX) { 0 }
  end

  def clear_values
    @axis_values.fill(0)
  end

  def set_axis_value(axis_symbol, value)
    @axis_values[axis_symbol] = value
  end

  def get_axis_value(axis_symbol)
    @axis_values[axis_symbol]
  end
end

####################################################################################################

class InputMapping
  attr_reader :name
  attr_accessor :raylib_key_map,    :name_key_map
  attr_accessor :raylib_mouse_map,  :name_mouse_map
  attr_accessor :raylib_button_map, :name_button_map
  attr_accessor :raylib_axis_map,   :name_axis_map

  def initialize(name)
    @name = name

    @raylib_key_map = {}
    @name_key_map = {}

    @raylib_mouse_map = {}
    @name_mouse_map = {}

    @raylib_button_map = {}
    @name_button_map = {}

    @raylib_axis_map = {}
    @name_axis_map = {}
  end

  def register_key(name, raylibkey, repeat_enabled: false, repeat_start: 0, repeat_interval: 0)
    raise RuntimeError "Raylib key #{raylibkey} is already registered" if @raylib_key_map.key? raylibkey
    raise RuntimeError "Name symbol #{name} is already used at somewhere else" if @name_key_map.key? name

    @raylib_key_map[raylibkey] = KeyStatus.new(repeat_enabled, repeat_start, repeat_interval)
    @name_key_map[name] = @raylib_key_map[raylibkey]
  end

  def unregister_key(name)
    @raylib_key_map.delete_if { |_, value| value == @name_key_map[name] }
    @name_key_map.delete(name)
  end

  def register_mouse(name, raylib_mousebutton, repeat_enabled: false, repeat_start: 0, repeat_interval: 0)
    raise RuntimeError "Raylib mouse button #{raylib_mousebutton} is already registered" if @raylib_mouse_map.key? raylib_mousebutton
    raise RuntimeError "Name symbol #{name} is already used at somewhere else" if @name_mouse_map.key? name

    @raylib_mouse_map[raylib_mousebutton] = KeyStatus.new(repeat_enabled, repeat_start, repeat_interval)
    @name_mouse_map[name] = @raylib_mouse_map[raylib_mousebutton]
  end

  def unregister_mouse(name)
    @raylib_mouse_map.delete_if { |_, value| value == @name_mouse_map[name] }
    @name_mouse_map.delete(name)
  end

  def register_button(name, raylib_button, repeat_enabled: false, repeat_start: 0, repeat_interval: 0, gamepad_id: 0)
    @raylib_button_map[gamepad_id] ||= {}
    @name_button_map[gamepad_id] ||= {}

    @raylib_button_map[gamepad_id][raylib_button] = KeyStatus.new(repeat_enabled, repeat_start, repeat_interval)
    @name_button_map[gamepad_id][name] = @raylib_button_map[gamepad_id][raylib_button]
  end

  def unregister_button(name, gamepad_id: 0)
    @raylib_button_map[gamepad_id].delete_if { |_, value| value == @name_button_map[gamepad_id][name] }
    @name_button_map[gamepad_id].delete(name)
  end

  def register_axis(name, raylib_axis, handle_as_button: false, button_direction: :both, button_threshold: 10_000, repeat_enabled: false, repeat_start: 0, repeat_interval: 0, gamepad_id: 0)
    @raylib_axis_map[gamepad_id] ||= {}
    @name_axis_map[gamepad_id] ||= {}

    @raylib_axis_map[gamepad_id][raylib_axis] ||= {}

    @raylib_axis_map[gamepad_id][raylib_axis][button_direction] =
      AxisStatus.new(handle_as_button, button_direction, button_threshold, repeat_enabled:, repeat_start:, repeat_interval:)
    @name_axis_map[gamepad_id][name] = @raylib_axis_map[gamepad_id][raylib_axis][button_direction]
  end

  def unregister_axis(name, gamepad_id: 0)
    @raylib_axis_map[gamepad_id].delete(@name_axis_map[gamepad_id][name])
    @name_axis_map[gamepad_id].delete(name)
  end

  def clear_flags
    @raylib_key_map.each_value { |map| map.clear_flags }
    @raylib_mouse_map.each_value { |map| map.clear_flags }
    @raylib_button_map.each_value do |gamepad_to_button_map|
      gamepad_to_button_map.each_value { |map| map.clear_flags }
    end
    @raylib_axis_map.each_value do |gamepad_to_axis_map|
      gamepad_to_axis_map.each_value do |axis_to_direction_map|
        axis_to_direction_map.each_value {|map| map.clear_flags }
      end
    end
  end

end

####################################################################################################

class Input
  attr_reader :mouse_pos_x, :mouse_pos_y, :mouse_rel_x, :mouse_rel_y
  attr_accessor :screen_width, :screen_height

  def initialize
    @current_mapping = nil
    @mappings = Hash.new

    @mouse_pos_x = 0
    @mouse_pos_y = 0
    @mouse_rel_x = 0
    @mouse_rel_y = 0

    @screen_width = 0
    @screen_height = 0

    @active_gamepads = {}
  end

  def register_mapping(mapping)
    @mappings[mapping.name] = mapping
  end

  def unregister_mapping(mapping_name)
    @mappings.delete(mapping_name)
  end

  def set_mapping(mapping_name)
    @current_mapping = @mappings[mapping_name]
    @current_mapping.clear_flags
  end

  def unset_mapping
    @current_mapping = nil
  end

  def setup
    # curl -O https://raw.githubusercontent.com/gabomdq/SDL_GameControllerDB/master/gamecontrollerdb.txt
    return unless File.exist?('system/gamecontrollerdb.txt')

    Raylib.SetGamepadMappings(File.read('system/gamecontrollerdb.txt'))
  end

  def cleanup
  end

  def prepare_event
    @mouse_rel_x = 0
    @mouse_rel_y = 0
  end

  def handle_event
    return if @current_mapping.nil?

    @current_mapping.raylib_key_map.each do |key, button|
      key_pressed = Raylib.IsKeyPressed(key)
      key_released = Raylib.IsKeyReleased(key)
      if key_pressed or key_released
        button.prev_down = button.down
        button.down = key_pressed ? 1 : 0
      end
    end

    @current_mapping.raylib_mouse_map.each do |key, button|
      key_pressed = Raylib.IsMouseButtonPressed(key)
      key_released = Raylib.IsMouseButtonReleased(key)
      if key_pressed or key_released
        button.prev_down = button.down
        button.down = key_pressed ? 1 : 0
      end
    end

    mouse_pos = Raylib.GetMousePosition()
    mouse_rel = Raylib.GetMouseDelta()
    @mouse_pos_x = mouse_pos.x
    @mouse_pos_y = mouse_pos.y
    @mouse_rel_x = mouse_rel.x
    @mouse_rel_y = mouse_rel.y

    Raylib::MAX_GAMEPADS.times do |gamepad_id|
      if Raylib.IsGamepadAvailable(gamepad_id)
        unless @active_gamepads.key? gamepad_id
          @active_gamepads[gamepad_id] = GamePad.new(gamepad_id, gamepad_id)
        end
        gamepad = @active_gamepads[gamepad_id]

        gamepad.set_axis_value(Raylib::GAMEPAD_AXIS_LEFT_X, GetGamepadAxisMovement(gamepad_id, Raylib::GAMEPAD_AXIS_LEFT_X))
        gamepad.set_axis_value(Raylib::GAMEPAD_AXIS_LEFT_Y, GetGamepadAxisMovement(gamepad_id, Raylib::GAMEPAD_AXIS_LEFT_Y))
        gamepad.set_axis_value(Raylib::GAMEPAD_AXIS_RIGHT_X, GetGamepadAxisMovement(gamepad_id, Raylib::GAMEPAD_AXIS_RIGHT_X))
        gamepad.set_axis_value(Raylib::GAMEPAD_AXIS_RIGHT_Y, GetGamepadAxisMovement(gamepad_id, Raylib::GAMEPAD_AXIS_RIGHT_Y))
        gamepad.set_axis_value(Raylib::GAMEPAD_AXIS_LEFT_TRIGGER, GetGamepadAxisMovement(gamepad_id, Raylib::GAMEPAD_AXIS_LEFT_TRIGGER))
        gamepad.set_axis_value(Raylib::GAMEPAD_AXIS_RIGHT_TRIGGER, GetGamepadAxisMovement(gamepad_id, Raylib::GAMEPAD_AXIS_RIGHT_TRIGGER))

        if @current_mapping.raylib_button_map.key? gamepad_id
          @current_mapping.raylib_button_map[gamepad_id].each do |key, button|
            key_pressed = Raylib.IsGamepadButtonPressed(gamepad_id, key)
            key_released = Raylib.IsGamepadButtonReleased(gamepad_id, key)
            if key_pressed or key_released
              button.prev_down = button.down
              button.down = key_pressed ? 1 : 0
            end
          end
        end
      else
        if @active_gamepads.key? gamepad_id
          @active_gamepads.delete(gamepad_id)
        end
      end
    end
  end

  def update
    return if @current_mapping.nil?

    @current_mapping.raylib_key_map.each_value(&:update)
    @current_mapping.raylib_mouse_map.each_value(&:update)
    @current_mapping.raylib_button_map.each_value do |controller|
      controller.each_value(&:update)
    end

    @current_mapping.raylib_axis_map.each do |gamepad_id, controller|
      next unless @active_gamepads.key? gamepad_id

      controller.each do |raylib_axis, buttons|
        buttons.each_value do |button|
          button.value = @active_gamepads[gamepad_id].get_axis_value(raylib_axis)
          button.update
        end
      end
    end
  end

  def key_down?(name) = @current_mapping.name_key_map.key?(name) && @current_mapping.name_key_map[name].down != 0
  def key_trigger?(name) = @current_mapping.name_key_map.key?(name) && @current_mapping.name_key_map[name].trigger != 0
  def key_release?(name) = @current_mapping.name_key_map.key?(name) && @current_mapping.name_key_map[name].release != 0
  def key_repeat?(name) = @current_mapping.name_key_map.key?(name) && @current_mapping.name_key_map[name].repeat != 0

  def any_key_down?(*names)
    names.each do |name|
      return true if key_down? name
    end
    false
  end

  def any_key_repeat?(*names)
    names.each do |name|
      return true if key_repeat? name
    end
    false
  end

  def mouse_down?(name) = @current_mapping.name_mouse_map.key?(name) && @current_mapping.name_mouse_map[name].down != 0
  def mouse_trigger?(name) = @current_mapping.name_mouse_map.key?(name) && @current_mapping.name_mouse_map[name].trigger != 0
  def mouse_release?(name) = @current_mapping.name_mouse_map.key?(name) && @current_mapping.name_mouse_map[name].release != 0
  def mouse_repeat?(name) = @current_mapping.name_mouse_map.key?(name) && @current_mapping.name_mouse_map[name].repeat != 0

  def any_mouse_down?(*names)
    names.each do |name|
      return true if mouse_down? name
    end
    false
  end

  def any_mouse_repeat?(*names)
    names.each do |name|
      return true if mouse_repeat? name
    end
    false
  end

  def button_down?(name, gamepad: 0) = @current_mapping.name_button_map.key?(gamepad) && @current_mapping.name_button_map[gamepad].key?(name) && @current_mapping.name_button_map[gamepad][name].down != 0
  def button_trigger?(name, gamepad: 0) = @current_mapping.name_button_map.key?(gamepad) && @current_mapping.name_button_map[gamepad].key?(name) && @current_mapping.name_button_map[gamepad][name].trigger != 0
  def button_release?(name, gamepad: 0) = @current_mapping.name_button_map.key?(gamepad) && @current_mapping.name_button_map[gamepad].key?(name) && @current_mapping.name_button_map[gamepad][name].release != 0
  def button_repeat?(name, gamepad: 0) = @current_mapping.name_button_map.key?(gamepad) && @current_mapping.name_button_map[gamepad].key?(name) && @current_mapping.name_button_map[gamepad][name].repeat != 0

  def any_button_down?(*names, gamepad: 0)
    names.each do |name|
      return true if button_down?(name, gamepad)
    end
    false
  end

  def any_button_repeat?(*names, gamepad: 0)
    names.each do |name|
      return true if button_repeat?(name, gamepad:)
    end
    false
  end

  def axis_down?(name, gamepad: 0) = @current_mapping.name_axis_map.key?(gamepad) && @current_mapping.name_axis_map[gamepad].key?(name) && @current_mapping.name_axis_map[gamepad][name].down != 0
  def axis_trigger?(name, gamepad: 0) = @current_mapping.name_axis_map.key?(gamepad) && @current_mapping.name_axis_map[gamepad].key?(name) && @current_mapping.name_axis_map[gamepad][name].trigger != 0
  def axis_release?(name, gamepad: 0) = @current_mapping.name_axis_map.key?(gamepad) && @current_mapping.name_axis_map[gamepad].key?(name) && @current_mapping.name_axis_map[gamepad][name].release != 0
  def axis_repeat?(name, gamepad: 0) = @current_mapping.name_axis_map.key?(gamepad) && @current_mapping.name_axis_map[gamepad].key?(name) && @current_mapping.name_axis_map[gamepad][name].repeat != 0

  def any_axis_down?(*names, gamepad: 0)
    names.each do |name|
      return true if axis_down?(name, gamepad:)
    end
    false
  end

  def any_axis_repeat?(*names, gamepad: 0)
    names.each do |name|
      return true if axis_repeat?(name, gamepad:)
    end
    false
  end

  def axis_value(name, gamepad: 0)
    if @current_mapping.name_axis_map.key?(gamepad) && @current_mapping.name_axis_map[gamepad].key?(name)
      return @current_mapping.name_axis_map[gamepad][name].value
    end
    0.0
  end

  def down?(name, gamepad: 0)
    return key_down?(name) || mouse_down?(name) || button_down?(name, gamepad:) || axis_down?(name, gamepad:)
  end

  def trigger?(name, gamepad: 0)
    return key_trigger?(name) || mouse_trigger?(name) || button_trigger?(name, gamepad:) || axis_trigger?(name, gamepad:)
  end

  def release?(name, gamepad: 0)
    return key_release?(name) || mouse_release?(name) || button_release?(name, gamepad:) || axis_release?(name, gamepad:)
  end

  def repeat?(name, gamepad: 0)
    return key_repeat?(name) || mouse_repeat?(name) || button_repeat?(name, gamepad:) || axis_repeat?(name, gamepad:)
  end

  def any_down?(*names, gamepad: 0)
    return any_key_down?(*names) || any_mouse_down?(*names) || any_button_down?(*names, gamepad:) || any_axis_down?(*names, gamepad:)
  end

  def any_repeat?(*names, gamepad: 0)
    return any_key_repeat?(*names) || any_mouse_repeat?(*names) || any_button_repeat?(*names, gamepad:) || any_axis_repeat?(*names, gamepad:)
  end
end
