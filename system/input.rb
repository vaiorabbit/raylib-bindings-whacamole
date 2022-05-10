require 'sdl2'

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
  AXIS_LEFTX = SDL::CONTROLLER_AXIS_LEFTX
  AXIS_LEFTY = SDL::CONTROLLER_AXIS_LEFTY
  AXIS_RIGHTX = SDL::CONTROLLER_AXIS_RIGHTX
  AXIS_RIGHTY = SDL::CONTROLLER_AXIS_RIGHTY
  AXIS_TRIGGERLEFT = SDL::CONTROLLER_AXIS_TRIGGERLEFT
  AXIS_TRIGGERRIGHT = SDL::CONTROLLER_AXIS_TRIGGERRIGHT
  AXIS_MAX = SDL::CONTROLLER_AXIS_MAX

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
  attr_accessor :sdl_key_map,    :name_key_map
  attr_accessor :sdl_mouse_map,  :name_mouse_map
  attr_accessor :sdl_button_map, :name_button_map
  attr_accessor :sdl_axis_map,   :name_axis_map

  def initialize(name)
    @name = name

    @sdl_key_map = {}
    @name_key_map = {}

    @sdl_mouse_map = {}
    @name_mouse_map = {}

    @sdl_button_map = {}
    @name_button_map = {}

    @sdl_axis_map = {}
    @name_axis_map = {}
  end

  def register_key(name, sdlkey, repeat_enabled: false, repeat_start: 0, repeat_interval: 0)
    raise RuntimeError "SDL key #{sdlkey} is already registered" if @sdl_key_map.key? sdlkey
    raise RuntimeError "Name symbol #{name} is already used at somewhere else" if @name_key_map.key? name

    @sdl_key_map[sdlkey] = KeyStatus.new(repeat_enabled, repeat_start, repeat_interval)
    @name_key_map[name] = @sdl_key_map[sdlkey]
  end

  def unregister_key(name)
    @sdl_key_map.delete_if { |_, value| value == @name_key_map[name] }
    @name_key_map.delete(name)
  end

  def register_mouse(name, sdl_mousebutton, repeat_enabled: false, repeat_start: 0, repeat_interval: 0)
    raise RuntimeError "SDL mouse button #{sdl_mousebutton} is already registered" if @sdl_mouse_map.key? sdl_mousebutton
    raise RuntimeError "Name symbol #{name} is already used at somewhere else" if @name_mouse_map.key? name

    @sdl_mouse_map[sdl_mousebutton] = KeyStatus.new(repeat_enabled, repeat_start, repeat_interval)
    @name_mouse_map[name] = @sdl_mouse_map[sdl_mousebutton]
  end

  def unregister_mouse(name)
    @sdl_mouse_map.delete_if { |_, value| value == @name_mouse_map[name] }
    @name_mouse_map.delete(name)
  end

  def register_button(name, sdl_button, repeat_enabled: false, repeat_start: 0, repeat_interval: 0, gamepad_id: 0)
    @sdl_button_map[gamepad_id] ||= {}
    @name_button_map[gamepad_id] ||= {}

    @sdl_button_map[gamepad_id][sdl_button] = KeyStatus.new(repeat_enabled, repeat_start, repeat_interval)
    @name_button_map[gamepad_id][name] = @sdl_button_map[gamepad_id][sdl_button]
  end

  def unregister_button(name, gamepad_id: 0)
    @sdl_button_map[gamepad_id].delete_if { |_, value| value == @name_button_map[gamepad_id][name] }
    @name_button_map[gamepad_id].delete(name)
  end

  def register_axis(name, sdl_axis, handle_as_button: false, button_direction: :both, button_threshold: 10_000, repeat_enabled: false, repeat_start: 0, repeat_interval: 0, gamepad_id: 0)
    @sdl_axis_map[gamepad_id] ||= {}
    @name_axis_map[gamepad_id] ||= {}

    @sdl_axis_map[gamepad_id][sdl_axis] ||= {}

    @sdl_axis_map[gamepad_id][sdl_axis][button_direction] =
      AxisStatus.new(handle_as_button, button_direction, button_threshold, repeat_enabled:, repeat_start:, repeat_interval:)
    @name_axis_map[gamepad_id][name] = @sdl_axis_map[gamepad_id][sdl_axis][button_direction]
  end

  def unregister_axis(name, gamepad_id: 0)
    @sdl_axis_map[gamepad_id].delete(@name_axis_map[gamepad_id][name])
    @name_axis_map[gamepad_id].delete(name)
  end

  def clear_flags
    @sdl_key_map.each_value { |map| map.clear_flags }
    @sdl_mouse_map.each_value { |map| map.clear_flags }
    @sdl_button_map.each_value do |gamepad_to_button_map|
      gamepad_to_button_map.each_value { |map| map.clear_flags }
    end
    @sdl_axis_map.each_value do |gamepad_to_axis_map|
      gamepad_to_axis_map.each_value do |axis_to_direction_map|
        axis_to_direction_map.each_value {|map| map.clear_flags }
      end
    end
  end

end

####################################################################################################

class Input
  attr_reader :mouse_pos_x, :mouse_pos_y, :mouse_rel_x, :mouse_rel_y

  def initialize
    @current_mapping = nil
    @mappings = Hash.new

    @mouse_pos_x = 0
    @mouse_pos_y = 0
    @mouse_rel_x = 0
    @mouse_rel_y = 0

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
    # [NOTE] To handle SDL::CONTROLLERBUTTON* and SDL::CONTROLLERMOTION events properly, run SDL.GameControllerAddMapping
    # curl -O https://raw.githubusercontent.com/gabomdq/SDL_GameControllerDB/master/gamecontrollerdb.txt
    return unless File.exist?('system/gamecontrollerdb.txt')

    SDL.GameControllerAddMapping(File.read('system/gamecontrollerdb.txt'))
  end

  def cleanup
    @active_gamepads.each_value do |gamepad|
      SDL.GameControllerClose(gamepad.game_controller)
    end
  end

  def prepare_event
    @mouse_rel_x = 0
    @mouse_rel_y = 0
  end

  def handle_event(event)
    case event[:common][:type]

    when SDL::KEYDOWN
      keysym = event[:key][:keysym][:sym]
      repeat = event[:key][:repeat] != 0
      if @current_mapping&.sdl_key_map&.key?(keysym) && !repeat
        button = @current_mapping.sdl_key_map[keysym]
        button.prev_down = button.down
        button.down = 1
      end
    when SDL::KEYUP
      keysym = event[:key][:keysym][:sym]
      repeat = event[:key][:repeat] != 0
      if @current_mapping&.sdl_key_map&.key?(keysym) && !repeat
        button = @current_mapping.sdl_key_map[keysym]
        button.prev_down = button.down
        button.down = 0
      end

    when SDL::MOUSEBUTTONDOWN
      mouse_button = event[:button][:button]
      mouse_state = event[:button][:state]
      if @current_mapping&.sdl_mouse_map&.key?(mouse_button)
        button = @current_mapping.sdl_mouse_map[mouse_button]
        button.prev_down = button.down
        button.down = 1
      end
    when SDL::MOUSEBUTTONUP
      mouse_button = event[:button][:button]
      mouse_state = event[:button][:state]
      if @current_mapping&.sdl_mouse_map&.key?(mouse_button)
        button = @current_mapping.sdl_mouse_map[mouse_button]
        button.prev_down = button.down
        button.down = 0
      end
    when SDL::MOUSEMOTION
      @mouse_pos_x = event[:motion][:x]
      @mouse_pos_y = event[:motion][:y]
      @mouse_rel_x = event[:motion][:xrel]
      @mouse_rel_y = event[:motion][:yrel]

    when SDL::CONTROLLERDEVICEADDED
      gamepad_id = event[:cdevice][:which]
      unless @active_gamepads.key? gamepad_id
        @active_gamepads[gamepad_id] = GamePad.new(SDL.GameControllerOpen(gamepad_id), gamepad_id)
      end
    when SDL::CONTROLLERDEVICEREMOVED
      gamepad_id = event[:cdevice][:which]
      unless @active_gamepads.key? gamepad_id
        SDL.GameControllerClose(gamepad_id)
        @active_gamepads.delete(gamepad_id)
      end

    when SDL::CONTROLLERAXISMOTION
      gamepad_id = event[:caxis][:which]
      gamepad = @active_gamepads[gamepad_id]
      gamepad.set_axis_value(event[:caxis][:axis], event[:caxis][:value])
    when SDL::CONTROLLERBUTTONDOWN
      gamepad_id = event[:cbutton][:which]
      sdl_button = event[:cbutton][:button]
      if @current_mapping&.sdl_button_map[gamepad_id].key?(sdl_button)
        button = @current_mapping.sdl_button_map[gamepad_id][sdl_button]
        button.prev_down = button.down
        button.down = 1
      end
    when SDL::CONTROLLERBUTTONUP
      gamepad_id = event[:cbutton][:which]
      sdl_button = event[:cbutton][:button]
      if @current_mapping&.sdl_button_map[gamepad_id].key?(sdl_button)
        button = @current_mapping.sdl_button_map[gamepad_id][sdl_button]
        button.prev_down = button.down
        button.down = 0
      end
    end
  end

  def update
    return if @current_mapping.nil?

    @current_mapping.sdl_key_map.each_value(&:update)
    @current_mapping.sdl_mouse_map.each_value(&:update)
    @current_mapping.sdl_button_map.each_value do |controller|
      controller.each_value(&:update)
    end

    @current_mapping.sdl_axis_map.each do |gamepad_id, controller|
      next unless @active_gamepads.key? gamepad_id

      controller.each do |sdl_axis, buttons|
        buttons.each_value do |button|
          button.value = @active_gamepads[gamepad_id].get_axis_value(sdl_axis)
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
