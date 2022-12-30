require_relative '../layout'
require_relative '../../system/image'

class Hammer

  attr_accessor :x, :y, :down

  def initialize
    @hammer_image_up = Image.new
    @hammer_image_down = Image.new
    @x = 0
    @y = 0
    @down = false
  end

  def setup(renderer, input)
    @hammer_image_up.setup('asset/character/pikopiko_hammer_up.png', renderer)
    @hammer_image_up.width = Layout.size(:hammer_image)[0]
    @hammer_image_up.height = Layout.size(:hammer_image)[1]

    @hammer_image_down.setup('asset/character/pikopiko_hammer_down.png', renderer)
    @hammer_image_down.width = Layout.size(:hammer_image)[0]
    @hammer_image_down.height = Layout.size(:hammer_image)[1]

    self
  end

  def cleanup
    @hammer_image_up.cleanup
    @hammer_image_down.cleanup
  end

  def set_position(pointer_x, pointer_y)
    @x = pointer_x + Layout.size(:hammer_image_offset)[0]
    @y = pointer_y + Layout.size(:hammer_image_offset)[1]
  end

  def render(renderer)
    hammer_image = @down ? @hammer_image_down : @hammer_image_up
    hammer_image.x = @x
    hammer_image.y = @y
    hammer_image.render(renderer)
  end

end
