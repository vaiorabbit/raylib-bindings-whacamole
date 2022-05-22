require 'sdl2'
require_relative '../../system/draw'
require_relative '../../system/game_state'
require_relative '../../system/input'
require_relative '../../system/screenshot'
require_relative '../objects/hammer'
require_relative '../objects/mole'
require_relative '../layout'
require_relative '../whacamole'

####################################################################################################

class MainState < GameState
  def initialize(state_id)
    super
  end

  def setup(services)
    super
    mapping = InputMapping.new(:main)
    mapping.register_key(:pause_game, SDL::SDLK_ESCAPE)
    mapping.register_mouse(:hammer_attack, SDL::BUTTON_LEFT, repeat_enabled: false)
    input.register_mapping(mapping)

    @screenshot = services.get(:ScreenShot)

    @hammer = services.get(:Hammer)
    @hammer.x = Layout.size(:hammer_image)[0]
    @hammer.y = Layout.size(:hammer_image)[1]

    @mole = services.get(:Mole)
    @whacamole = services.get(:WhacAMole)
    @cursor_circle = services.get(:CursorCircle)
    @grass = services.get(:Grass)
    @background = services.get(:Background)
    @effects = services.get(:HitEffects)
  end

  def cleanup
    @whacamole = nil
    @hammer = nil
    @mole = nil
    @cursor_circle = nil
    @grass = nil
    @background = nil
    @effects = nil
    @screenshot = nil
    super
  end

  def enter(_prev_state_id)
    input.set_mapping(:main)
    @hammer.set_position(input.mouse_pos_x, input.mouse_pos_y)
    @hammer.down = false
    @effects.hide
  end

  def leave(_next_state_id)
    @screenshot.capture
    input.unset_mapping
  end

  def update(dt)
    @whacamole.update(dt)

    @hammer.set_position(input.mouse_pos_x, input.mouse_pos_y)
    @hammer.down = (input.mouse_down? :hammer_attack)

    if input.mouse_trigger? :hammer_attack
      @whacamole.moles_status.each do |status|
        if status.hit_detection_active? && status.overlap_with_circle?(input.mouse_pos_x, input.mouse_pos_y, @cursor_circle.radius)
          @whacamole.add_score(1)
          status.go_down
          @effects.play(input.mouse_pos_x, input.mouse_pos_y)
        end
      end
    end

    @effects.update(dt)

    if @whacamole.game_over
      return :finish
    elsif input.trigger? :pause_game
      return :pause
    else
      return state_id
    end
  end

  def render
    @background.render_background(renderer)
    @background.render_ui(renderer, @whacamole.score, @whacamole.time_left)

    @whacamole.moles_status.each do |status|
      if status.visible?
        @mole.x, @mole.y = status.position_x, status.position_y
        @mole.width = @mole.original_width * status.animation_scale_x
        @mole.height = @mole.original_height * status.animation_scale_y
        @mole.x += 0.5 * @mole.original_width * (1.0 - status.animation_scale_x)
        @mole.y += 0.8 * @mole.original_height * (1.0 - status.animation_scale_y)
        @mole.render(renderer)
      end
    end
    @grass.render_per_hole(renderer)

    @hammer.render(renderer)
    Circle.render(renderer, @cursor_circle, input.mouse_pos_x, input.mouse_pos_y) unless @hammer.down

    @effects.render(renderer)
  end
end
