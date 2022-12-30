require 'raylib'
require_relative '../../system/game_state'
require_relative '../../system/sound'

class ReadyState < GameState
  def setup(services)
    super
    @grass = services.get(:Grass)
    @background = services.get(:Background)
    @whacamole = services.get(:WhacAMole)

    @ready_bgm = Sound::Bgm.new('asset/sound/Ready.mp3').setup
  end

  def cleanup
    @ready_bgm.cleanup
    @ready_bgm = nil
    @grass = nil
    @background = nil
    super
  end

  def enter(_prev_state_id)
    @show_text = true
    @flip_current = 0.0
    @flip_end = 0.125
    @time_current = 0.0
    @time_end = 3.0

    @whacamole.reset
    Sound::Bgm.play(@ready_bgm, do_loop: false)
  end

  def leave(_next_state_id)
    Sound::Bgm.halt
  end

  def update(dt)
    @time_current += dt
    @flip_current += dt

    if @flip_current >= @flip_end
      @flip_current = 0.0
      @show_text = !@show_text
    end

    return :main if @time_current >= @time_end
    state_id
  end

  def render
    @background.render_background()
    @grass.render_per_hole()

    Text.set(Layout.position(:score_header)[0], Layout.position(:score_header)[1], "SCORE", Raylib::RED)
    Text.set(Layout.position(:score_current)[0], Layout.position(:score_current)[1], @whacamole.score.to_s.rjust(5), Raylib::WHITE)

    @background.render_ui(@whacamole.score, @whacamole.time_left)

    Text.set(Layout.position(:ready_header)[0], Layout.position(:ready_header)[1], "READY?", Raylib::RED) if @show_text
  end
end
