require 'raylib'
require_relative 'game_state'
require_relative 'image'
require_relative 'input'
require_relative 'services'
require_relative 'text'
require_relative 'timer'

shared_lib_path = Gem::Specification.find_by_name('raylib-bindings').full_gem_path + '/lib/'

case RUBY_PLATFORM
when /mswin|msys|mingw|cygwin/
  Raylib.load_lib(shared_lib_path + 'libraylib.dll', raygui_libpath: shared_lib_path + 'raygui.dll', physac_libpath: shared_lib_path + 'physac.dll')
when /darwin/
  Raylib.load_lib(shared_lib_path + 'libraylib.dylib', raygui_libpath: shared_lib_path + 'raygui.dylib', physac_libpath: shared_lib_path + 'physac.dylib')
else
  raise RuntimeError, "Unknown OS: #{RUBY_PLATFORM}"
end

class Application
  attr_reader :title, :screen_width, :screen_height, :screen_x, :screen_y, :end_main

  def initialize(title: '', screen_width: 800, screen_height: 600, screen_x: 32, screen_y: 32,
                 clear_r: 192, clear_g: 192, clear_b: 255, clear_a: 255)
    @title = title
    @screen_width = screen_width
    @screen_height = screen_height
    @screen_x = screen_x
    @screen_y = screen_y
    @clear_r = clear_r
    @clear_g = clear_g
    @clear_b = clear_b
    @clear_a = clear_a
    @end_main = false

    @window = nil

    @input = Input.new
    @state_manager = GameStateManager.new

    @services = Services.new
  end

  def register_game_state(state, initial_state: false)
    @state_manager.register(state)
    @state_manager.initial_state_id = state.state_id if initial_state
  end

  def setup(setup_func = nil)
    Raylib.InitWindow(@screen_width, @screen_height, @title)
    Raylib.InitAudioDevice()

    Text.setup()

    @input.setup
    @input.screen_width = @screen_width
    @input.screen_height = @screen_height

    @services.setup
    @services.register_external(:Input, @input)

    setup_func&.call(@services)

    @state_manager.setup(@services)
    @state_manager.start
  end

  def cleanup(cleanup_func = nil)
    cleanup_func&.call
    @state_manager.cleanup
    @services.cleanup
    @input.cleanup

    Text.cleanup()

    Raylib.CloseAudioDevice()
    Raylib.CloseWindow()
  end

  def main
    game_timer = Timer.new
    game_timer.setup
    game_timer.start

    dt = 0.0

    until @end_main
      Sound::Bgm.update(dt)
      @input.handle_event
      @input.update

      @state_manager.update(dt)

      Raylib.BeginDrawing()
        Raylib.ClearBackground(Raylib::Color.from_u8(@clear_r, @clear_g, @clear_b, @clear_a))
        @state_manager.render
        Text.render
      Raylib.EndDrawing()

      dt = game_timer.elapsed
      game_timer.start

      @end_main = true if (@state_manager.state_request & GameStateManager::STATE_REQUEST_EXIT) != 0
    end
  end
end
