require 'sdl2'

class ScreenShot

  attr_reader :texture, :width, :height

  def initialize(width:, height:)
    @rect = SDL::Rect.new
    @rect[:x] = 0
    @rect[:y] = 0
    @rect[:w] = width
    @rect[:h] = height

    @texture = nil
  end

  def setup(renderer)
    @renderer = renderer
  end

  def cleanup
    release_texture
    @renderer = nil
  end

  def release_texture
    SDL.DestroyTexture(@texture) unless @texture.nil?
    @texture = nil
  end

  def capture
    release_texture

    surface = SDL.CreateRGBSurfaceWithFormat(0, @rect[:w], @rect[:h], 32, SDL::PIXELFORMAT_ARGB8888)
    surface = SDL::Surface.new(surface)
    SDL.RenderReadPixels(@renderer, nil, SDL::PIXELFORMAT_ARGB8888, surface[:pixels], surface[:pitch])
    @texture = SDL.CreateTextureFromSurface(@renderer, surface)
    SDL.FreeSurface(surface)
  end

  def render(r: 255, g: 255, b: 255)
    SDL.SetTextureColorMod(@texture, r, g, b)
    SDL.RenderCopyEx(@renderer, @texture, nil, @rect, 0, nil, SDL::FLIP_NONE)
  end

end
