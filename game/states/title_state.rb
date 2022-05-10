require 'sdl2'
require_relative '../../system/game_state'
require_relative '../../system/input'

class TitleState < GameState
  def setup(services)
    super
    mapping = InputMapping.new(:title)
    mapping.register_key(:exit_game, SDL::SDLK_ESCAPE)
    mapping.register_key(:start_game, SDL::SDLK_SPACE)
    mapping.register_button(:exit_game, SDL::CONTROLLER_BUTTON_BACK, gamepad_id: 0)
    mapping.register_button(:start_game, SDL::CONTROLLER_BUTTON_START, gamepad_id: 0)
    mapping.register_mouse(:start_game, SDL::BUTTON_LEFT, repeat_enabled: false)
    input.register_mapping(mapping)

    @grass = services.get(:Grass)
    @background = services.get(:Background)
  end

  def cleanup
    @grass = nil
    @background = nil
    super
  end

  def enter(_prev_state_id)
    input.set_mapping(:title)
  end

  def leave(_next_state_id)
    input.unset_mapping
  end

  def update(dt)
    if input.trigger? :start_game
      return :ready
    else
      return state_id, ((input.trigger? :exit_game) ? GameStateManager::STATE_REQUEST_EXIT : nil)
    end
  end

  def render
    @background.render_background(renderer)
    @grass.render_per_hole(renderer)

    Text.set(32, 180, "           Whac-a-Mole!\n     Ruby SDL2-Bindings demo", Text::BLUE)
    Text.set(32, 300, "  Click or press SPACE to start\n         Press ESC to exit", Text::RED)
    Text.set(32, 440, "         2022 vaiorabbit", Text::WHITE)
  end
end
