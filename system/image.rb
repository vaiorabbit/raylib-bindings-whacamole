require 'raylib'

class Image
  attr_reader :texture, :rect_src

  def initialize
    @rect_src = Raylib::Rectangle.new
    @rect_src[:x] = 0
    @rect_src[:y] = 0
    @rect_src[:width] = 0
    @rect_src[:height] = 0

    @rect_dst = Raylib::Rectangle.new
    @rect_dst[:x] = 0
    @rect_dst[:y] = 0
    @rect_dst[:width] = 0
    @rect_dst[:height] = 0

    @origin = Raylib::Vector2.create(0, 0)

    @original_w = 0
    @original_h = 0

    @texture = nil
  end

  def setup(path)
    @texture = Raylib.LoadTexture(path)
    @rect_src[:x] = 0
    @rect_src[:y] = 0
    @rect_src[:width] = @texture[:width]
    @rect_src[:height] = @texture[:height]

    @original_w = @texture[:width]
    @original_h = @texture[:height]
    @rect_dst[:width] = @original_w
    @rect_dst[:height] = @original_h
  end

  def cleanup
    Raylib.UnloadTexture(@texture)
    @texture = nil
    @original_w = 0
    @original_h = 0
    @rect_dst[:x] = 0
    @rect_dst[:y] = 0
    @rect_dst[:width] = 0
    @rect_dst[:height] = 0
    @rect_src[:x] = 0
    @rect_src[:y] = 0
    @rect_src[:width] = 0
    @rect_src[:height] = 0
  end

  def x = @rect_dst[:x]

  def x=(x)
    @rect_dst[:x] = x
  end

  def y = @rect_dst[:y]

  def y=(y)
    @rect_dst[:y] = y
  end

  def width = @rect_dst[:width]

  def width=(w)
    @rect_dst[:width] = w
  end

  def height = @rect_dst[:height]

  def height=(h)
    @rect_dst[:height] = h
  end

  def original_width = @original_w

  def original_height = @original_h

  def reset_rect
    @rect_dst[:width] = @original_w
    @rect_dst[:height] = @original_h
  end

  def render
    Raylib.DrawTexturePro(@texture, @rect_src, @rect_dst, @origin, 0.0,  Raylib::WHITE)
  end
end
