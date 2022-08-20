require 'sdl2'
require_relative '../../system/game_state'
require_relative '../../system/input'
require_relative '../layout'

class ResultState < GameState
  def setup(services)
    super
    mapping = InputMapping.new(:result)
    mapping.register_key(:exit_game, SDL::SDLK_ESCAPE)
    mapping.register_key(:start_game, SDL::SDLK_SPACE)
    mapping.register_button(:exit_game, SDL::CONTROLLER_BUTTON_BACK, gamepad_id: 0)
    mapping.register_button(:start_game, SDL::CONTROLLER_BUTTON_START, gamepad_id: 0)
    mapping.register_mouse(:start_game, SDL::BUTTON_LEFT, repeat_enabled: false)
    input.register_mapping(mapping)

    @grass = services.get(:Grass)
    @background = services.get(:Background)
    @whacamole = services.get(:WhacAMole)

    @gameover_bgm = SDL.Mix_LoadMUS_RW(SDL.RWFromFile('asset/sound/GameOver.mp3', 'rb'), 1)
  end

  def cleanup
    SDL.Mix_FreeMusic(@gameover_bgm)
    @gameover_bgm = nil
    @grass = nil
    @background = nil
    @whacamole = nil
    super
  end

  def enter(_prev_state_id)
    @show_text = true
    @flip_current = 0.0
    @flip_end = 1.0
    @time_current = 0.0
    @time_end = 2.0
    input.set_mapping(:result)
    SDL.Mix_PlayMusic(@gameover_bgm, 0)
  end

  def leave(_next_state_id)
    input.unset_mapping
    SDL.Mix_HaltMusic()
  end

  def update(dt)
    @time_current += dt
    @flip_current += dt

    if @flip_current >= @flip_end
      @flip_current = 0.0
      @show_text = !@show_text
    end

    if input.trigger? :start_game
      return :ready
    else
      return state_id, ((input.trigger? :exit_game) ? GameStateManager::STATE_REQUEST_EXIT : nil)
    end
  end

  def render
    @background.render_background(renderer)
    @grass.render_per_hole(renderer)

    score = @whacamole.score
    moles = @whacamole.total_moles_count
    hit_rate = (score.to_f / moles) * 100
    Text.set(Layout.position(:result_header)[0], Layout.position(:result_header)[1], "RESULT", Text::RED)
    Text.set(Layout.position(:result_score)[0], Layout.position(:result_score)[1], "YOUR SCORE : #{score.to_s.rjust(3)}", Text::WHITE)
    Text.set(Layout.position(:result_moles)[0], Layout.position(:result_moles)[1], "MOLES      : #{moles.to_s.rjust(3)}", Text::WHITE)
    Text.set(Layout.position(:result_rate)[0], Layout.position(:result_rate)[1], "HIT RATE   : #{('%2.3f' % hit_rate).rjust(7)}%", Text::WHITE)

    Text.set(32, 440, "Click or press SPACE to play again\n       Press ESC to exit", Text::RED) if @show_text
  end
end
