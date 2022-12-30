require 'sdl2'

module Color
  def self.from_u8(r = 0, g = 0, b = 0, a = 255)
    instance = SDL::Color.new
    instance[:r] = r
    instance[:g] = g
    instance[:b] = b
    instance[:a] = a
    return instance
  end
end
