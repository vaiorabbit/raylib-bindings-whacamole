require 'sdl2'
require_relative '../../system/game_state'
require_relative '../../system/input'

class PauseState < GameState
  def setup(services)
    super
    mapping = InputMapping.new(:pause)
    mapping.register_key(:exit_game, SDL::SDLK_ESCAPE)
    mapping.register_key(:resume_game, SDL::SDLK_SPACE)
    mapping.register_button(:exit_game, SDL::CONTROLLER_BUTTON_BACK, gamepad_id: 0)
    mapping.register_button(:resume_game, SDL::CONTROLLER_BUTTON_START, gamepad_id: 0)
    mapping.register_mouse(:resume_game, SDL::BUTTON_LEFT, repeat_enabled: false)
    input.register_mapping(mapping)
    @screenshot = services.get(:ScreenShot)
  end

  def cleanup
    @screenshot = nil
    super
  end

  def enter(_prev_state_id)
    @show_text = true
    @flip_current = 0.0
    @flip_end = 0.5
    @time_current = 0.0
    @time_end = 2.0

    input.set_mapping(:pause)
    @prev_state_id = _prev_state_id
  end

  def leave(_next_state_id)
    input.unset_mapping
    @screenshot.release_texture
    @prev_state_id = nil
  end

  def update(dt)
    @time_current += dt
    @flip_current += dt

    if @flip_current >= @flip_end
      @flip_current = 0.0
      @show_text = !@show_text
    end

    if input.trigger? :resume_game
      return @prev_state_id
    else
      return state_id, ((input.trigger? :exit_game) ? GameStateManager::STATE_REQUEST_EXIT : nil)
    end
  end

  def render
    # @screenshot.render(r: 192, g: 192, b: 192) # Enable this to cheat the game ;-P
    Text.set(32, 230, "              PAUSE", Text::RED)
    Text.set(32, 250, "  Click or press SPACE to resume\n          ESC to exit", Text::WHITE) if @show_text
  end
end
