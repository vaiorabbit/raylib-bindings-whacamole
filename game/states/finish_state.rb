require 'sdl2'
require_relative '../../system/game_state'
require_relative '../../system/input'
require_relative '../layout'

class FinishState < GameState
  def setup(services)
    super
    @background = services.get(:Background)
    @grass = services.get(:Grass)
    @mole = services.get(:Mole)
    @whacamole = services.get(:WhacAMole)
  end

  def cleanup
    @background = nil
    @grass = nil
    @mole = nil
    @whacamole = nil
    super
  end

  def enter(_prev_state_id)
    @show_text = true
    @flip_current = 0.0
    @flip_end = 0.125
    @time_current = 0.0
    @time_end = 2.0
  end

  def update(dt)
    @whacamole.update(dt)

    @time_current += dt
    @flip_current += dt

    if @flip_current >= @flip_end
      @flip_current = 0.0
      @show_text = !@show_text
    end

    return :result if @time_current >= @time_end
    state_id
  end

  def render
    @background.render_background(renderer)
    @whacamole.moles_status.each do |status|
      if status.visible?
        @mole.x, @mole.y = status.position_x, status.position_y
        @mole.height = @mole.original_height * status.animation_scale_y
        @mole.y += 0.8 * @mole.original_height * (1.0 - status.animation_scale_y)
        @mole.render(renderer)
      end
    end
    @grass.render_per_hole(renderer)

    Text.set(Layout.position(:finish_header)[0], Layout.position(:finish_header)[1], "FINISH!", Text::RED) if @show_text
  end
end
