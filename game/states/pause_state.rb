require 'raylib'
require_relative '../../system/game_state'
require_relative '../../system/input'
require_relative '../../system/sound'

class PauseState < GameState
  def setup(services)
    super
    mapping = InputMapping.new(:pause)
    mapping.register_key(:exit_game, Raylib::KEY_ESCAPE)
    mapping.register_key(:resume_game, Raylib::KEY_SPACE)
    mapping.register_button(:exit_game, Raylib::GAMEPAD_BUTTON_MIDDLE_LEFT, gamepad_id: 0)
    mapping.register_button(:resume_game, Raylib::GAMEPAD_BUTTON_MIDDLE_RIGHT, gamepad_id: 0)
    mapping.register_mouse(:resume_game, Raylib::MOUSE_BUTTON_LEFT, repeat_enabled: false)
    input.register_mapping(mapping)

    @pause_se = Sound::Sefx.new('asset/sound/Pause.wav').setup
  end

  def cleanup
    @pause_se.cleanup
    @pause_se = nil
    super
  end

  def enter(_prev_state_id)
    @show_text = true
    @flip_current = 0.0
    @flip_end = 0.5
    @time_current = 0.0
    @time_end = 2.0

    input.set_mapping(:pause)
    @pause_se.play
    @prev_state_id = _prev_state_id
  end

  def leave(_next_state_id)
    input.unset_mapping
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
    Text.set(32, 230, "              PAUSE", Raylib::RED)
    Text.set(32, 250, "  Click or press SPACE to resume\n          ESC to exit", Raylib::WHITE) if @show_text
  end
end
