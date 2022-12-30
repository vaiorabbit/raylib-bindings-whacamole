require 'raylib'
require_relative '../layout'
require_relative '../../system/image'

class HitEffect
  STATES = [:hidden, :playing]

  attr_reader :state, :running, :time_current, :time_end
  attr_reader :scale_x, :scale_y, :alpha

  def initialize
    @hit_image = nil
    @rect = Raylib::Rectangle.new
    @rect.x = 0
    @rect.y = 0
    @rect.width = 0
    @rect.height = 0
    reset
  end

  def setup(image)
    @hit_image = image #.setup('asset/field/kusa_simple4.png', renderer)
  end

  def cleanup
    @hit_image = nil #.cleanup
  end

  def reset()
    @state = :hidden
    @running = false
    @time_current = 0.0
    @time_end = 0.0
    @pos_x = 0.0
    @pos_y = 0.0
    @scale_x = 0.0
    @scale_y = 0.0
    @alpha = 0
  end

  def play(x, y, time_end: 0.125)
    return if @state == :playing

    # TODO make configurable
    @state = :playing
    @running = true
    @time_current = 0.0
    @time_end = time_end
    @pos_x = x
    @pos_y = y
    @scale_x = 1.0
    @scale_y = 1.0
    @alpha = 128
  end

  def hide
    return if @state == :hidden
    reset
  end

  def update(dt)
    return if not @running

    if @time_current > @time_end
      @time_current = @time_end
      @running = false
    end

    case @state
    when :playing
      @scale_x = 1.0 + [0.5, 0.5 * (@time_current / @time_end)].min
      @scale_y = @scale_x
      @alpha = (128 * (1.0 - (@time_current / @time_end))).to_i
      if @running == false
        @state = :hidden
      end
    end

    @time_current += dt
  end

  def render()
    return if not @running
    @rect.width = @hit_image.width * @scale_x
    @rect.height = @hit_image.height * @scale_y
    @rect.x = @pos_x - @rect.width * 0.5
    @rect.y = @pos_y - @rect.height * 0.5
#    SDL.SetTextureAlphaMod(@hit_image.texture, @alpha)
#    SDL.RenderCopyEx(renderer, @hit_image.texture, nil, @rect, 0, nil, SDL::FLIP_NONE)
    Raylib.DrawTexturePro(@hit_image.texture, @hit_image.rect_src, @rect, Raylib::Vector2.create, 0.0, Raylib::Color.from_u8(255, 255, 255, @alpha))
    #@hit_image.render
  end
end

####################################################################################################

class HitEffects
  def initialize(count: 9)
    @effects = []
    count.times do
      @effects << HitEffect.new
    end
    @hit_image = Image.new
  end

  def setup(renderer)
    @hit_image.setup('asset/effect/hit_effect.png')
    @hit_image.width = Layout.size(:hit_image)[0]
    @hit_image.height = Layout.size(:hit_image)[1]
#    SDL.SetTextureBlendMode(@hit_image.texture, SDL::BLENDMODE_BLEND)
    @effects.each do |effect|
      effect.setup(@hit_image)
    end
    self
  end

  def cleanup
    @effects.each(&:cleanup)
    @hit_image.cleanup
  end

  def play(pos_x, pos_y, time_end: 0.125)
    @effects.each do |effect|
      next if effect.running
      effect.play(pos_x, pos_y, time_end:)
    end
  end

  def hide
    @effects.each(&:hide)
  end

  def update(dt)
    @effects.each do |effect|
      effect.update(dt)
    end
  end

  def render()
    @effects.each do |effect|
      effect.render()
    end
  end
end
