require_relative '../layout'
require_relative '../../system/image'

class Mole

  attr_accessor :x, :y
  attr_reader :original_width, :original_height

  def initialize
    @mole_image = Image.new
    @x = 0
    @y = 0
    @original_width = 0
    @original_height = 0
  end

  def width
    @mole_image.width
  end

  def width=(w)
    @mole_image.width = w
  end

  def height
    @mole_image.height
  end

  def height=(h)
    @mole_image.height = h
  end

  def setup(input)
    @mole_image.setup('asset/character/animal_mogura_kouji2.png')
    @original_width = Layout.size(:mole_image)[0]
    @original_height = Layout.size(:mole_image)[1]
    @mole_image.width = @original_width
    @mole_image.height = @original_height
    self
  end

  def cleanup
    @mole_image.cleanup
  end

  def update(dt, input)
  end

  def render()
    @mole_image.x = @x
    @mole_image.y = @y
    @mole_image.render()
  end

end
