require 'sdl2'

class Image
  FLIP_NONE = 0b00
  FLIP_HORIZONTAL = 0b01
  FLIP_VERTICAL = 0b10

  attr_reader :texture

  def self.load_as_surface(path)
    rwops = SDL.RWFromFile(path, 'rb')
    img = SDL.IMG_Load_RW(rwops, 1)
    image = SDL::Surface.new(img)
    SDL.SetColorKey(image, SDL::TRUE, image[:pixels].read(:uint))
    image
  end

  def initialize
    @rect = SDL::Rect.new
    @rect[:x] = 0
    @rect[:y] = 0
    @rect[:w] = 0
    @rect[:h] = 0

    @original_w = 0
    @original_h = 0

    @texture = nil
  end

  def setup(path, renderer)
    image = Image.load_as_surface(path)
    @texture = SDL.CreateTextureFromSurface(renderer, image)
    @original_w = image[:w]
    @original_h = image[:h]
    @rect[:w] = @original_w
    @rect[:h] = @original_h

    SDL.FreeSurface(image)
  end

  def cleanup
    SDL.DestroyTexture(@texture)
    @texture = nil
    @original_w = 0
    @original_h = 0
    @rect[:x] = 0
    @rect[:y] = 0
    @rect[:w] = 0
    @rect[:h] = 0
  end

  def x = @rect[:x]

  def x=(x)
    @rect[:x] = x
  end

  def y = @rect[:y]

  def y=(y)
    @rect[:y] = y
  end

  def width = @rect[:w]

  def width=(w)
    @rect[:w] = w
  end

  def height = @rect[:h]

  def height=(h)
    @rect[:h] = h
  end

  def original_width = @original_w

  def original_height = @original_h

  def reset_rect
    # w = FFI::MemoryPointer.new(:int32)
    # h = FFI::MemoryPointer.new(:int32)
    # SDL.QueryTexture(@texture, nil, nil, w, h)

    # @rect[:w] = w.read_int
    # @rect[:h] = h.read_int

    @rect[:w] = @original_w
    @rect[:h] = @original_h
  end

  def render(renderer, flip = FLIP_NONE)
    SDL.RenderCopyEx(renderer, @texture, nil, @rect, 0, nil, flip)
  end
end
