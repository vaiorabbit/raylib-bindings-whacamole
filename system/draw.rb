require 'raylib'

module Circle

  class Cache
    attr_reader :vertices_memory, :indices_memory, :vertices_count, :indices_count
    attr_reader :radius, :division, :r, :g, :b, :a

    def initialize(radius: 50.0, division: 36, r: 255, g: 255, b: 255, a: 255)
      @radius = radius
      @division = division
      @r = r
      @g = g
      @b = b
      @a = a
    end

    def setup(_)
    end

    def cleanup
    end
  end

  def self.render(cache, center_x, center_y)
    Raylib.DrawCircle(center_x, center_y, cache.radius, Raylib::Color.from_u8(cache.r, cache.g, cache.b, cache.a))
  end

end
