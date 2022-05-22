require_relative '../layout'
require_relative '../../system/image'

class Grass
  def initialize
    @grass_image = Image.new
  end

  def grass_width = @grass_image.width
  def grass_height = @grass_image.height

  def setup(renderer, whacamole)
    @whacamole = whacamole
    @grass_image.setup('asset/field/kusa_simple4.png', renderer)
    @grass_image.width = Layout.size(:grass_image)[0]
    @grass_image.height = Layout.size(:grass_image)[1]
    self
  end

  def cleanup
    @grass_image.cleanup
    @whacamole = nil
  end

  def update(dt)
  end

  def render_at(renderer, x, y)
    @grass_image.x = x
    @grass_image.y = y
    @grass_image.render(renderer)
  end

  def render_per_hole(renderer)
    @whacamole.moles_status.each do |status|
      render_at(renderer, status.position_x, status.position_y + Layout.size(:grass_image_offset)[1])
    end
  end
end
