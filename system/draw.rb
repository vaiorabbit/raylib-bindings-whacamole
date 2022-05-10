require 'sdl2'

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

      @vertices_memory = FFI::MemoryPointer.new(SDL::Vertex, @division + 1)
      vertices = []
      (@division + 1).times do |i|
        vertices << SDL::Vertex.new(@vertices_memory + SDL::Vertex.size * i)
      end

      angle = (2 * Math::PI / @division)

      vertices[0][:position][:x] = @radius
      vertices[0][:position][:y] = @radius
      vertices[0][:color][:r] = @r
      vertices[0][:color][:g] = @g
      vertices[0][:color][:b] = @b
      vertices[0][:color][:a] = @a
      vtx0 = vertices[0]
      @division.times do |i|
        vtx = vertices[i + 1]
        vtx[:position][:x] = vtx0[:position][:x] + @radius * Math.cos(angle * i)
        vtx[:position][:y] = vtx0[:position][:y] + @radius * Math.sin(angle * i)
        vtx[:color][:r] = r
        vtx[:color][:g] = g
        vtx[:color][:b] = b
        vtx[:color][:a] = a
      end

      @indices_memory = FFI::MemoryPointer.new(:int, 3 * @division)
      @division.times do |i|
        @indices_memory.put_array_of_int(3 * i * FFI::NativeType::INT32.size, [0, i + 1, (i + 2) == @division + 1 ? 1 : (i + 2) % (@division + 1)])
      end

      @vertices_count = @division + 1
      @indices_count = @division * 3
    end

    def setup(_)
    end

    def cleanup
    end
  end

  def self.render(renderer, cache, center_x, center_y)
    viewport_original = SDL::Rect.new
    viewport_temporal = SDL::Rect.new

    SDL.RenderGetViewport(renderer, viewport_original)

    viewport_temporal[:x] = center_x - cache.radius
    viewport_temporal[:y] = center_y - cache.radius
    viewport_temporal[:w] = cache.radius * 2
    viewport_temporal[:h] = cache.radius * 2

    SDL.RenderSetViewport(renderer, viewport_temporal)

    SDL.RenderGeometry(renderer, nil, cache.vertices_memory, cache.vertices_count, cache.indices_memory, cache.indices_count)

    SDL.RenderSetViewport(renderer, viewport_original)
  end

end
