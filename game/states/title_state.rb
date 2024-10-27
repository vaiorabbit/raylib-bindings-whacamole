require 'raylib'
require_relative '../../system/game_state'
require_relative '../../system/input'
require_relative '../../system/sound'

class TitleState < GameState
  def setup(services)
    super
    mapping = InputMapping.new(:title)
    mapping.register_key(:exit_game, Raylib::KEY_ESCAPE)
    mapping.register_key(:start_game, Raylib::KEY_SPACE)
    mapping.register_button(:exit_game, Raylib::GAMEPAD_BUTTON_MIDDLE_LEFT, gamepad_id: 0)
    mapping.register_button(:start_game, Raylib::GAMEPAD_BUTTON_MIDDLE_RIGHT, gamepad_id: 0)
    mapping.register_mouse(:start_game, Raylib::MOUSE_BUTTON_LEFT, repeat_enabled: false)
    input.register_mapping(mapping)

    @grass = services.get(:Grass)
    @background = services.get(:Background)

    @title_bgm = Sound::Bgm.new('asset/sound/Title.ogg').setup
  end

  def cleanup
    @title_bgm.cleanup
    @title_bgm = nil
    @grass = nil
    @background = nil
    super
  end

  def enter(_prev_state_id)
    input.set_mapping(:title)
    Sound::Bgm.play(@title_bgm, do_loop: true)
  end

  def leave(_next_state_id)
    input.unset_mapping
    Sound::Bgm.halt
  end

  def update(dt)
    if input.trigger? :start_game
      return :ready
    else
      return state_id, ((input.trigger? :exit_game) ? GameStateManager::STATE_REQUEST_EXIT : nil)
    end
  end

  def render
    @background.render_background()
    @grass.render_per_hole()

    Text.set(32, 180, "           Whac-a-Mole!\n    Ruby raylib-bindings demo", Raylib::BLUE)
    Text.set(32, 300, "  Click or press SPACE to start\n         Press ESC to exit", Raylib::RED)
    Text.set(32, 440, "       2022-2023 vaiorabbit", Raylib::WHITE)
  end
end
