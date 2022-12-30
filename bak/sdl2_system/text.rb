require 'sdl2'
require_relative 'bitmap_font'
require_relative 'util'

module Text

  COLOR_NAME = %i(
    lightgray
    gray
    darkgray
    yellow
    gold
    orange
    pink
    red
    maroon
    green
    lime
    darkgreen
    skyblue
    blue
    darkblue
    purple
    violet
    darkpurple
    beige
    brown
    darkbrown
    white
    black
    magenta
  ).freeze

  # Define enums like Text::LIGHTGRAY, etc.
  COLOR_NAME.each do |sym|
    self.const_set(sym.to_s.upcase, sym) # == e.g.) LIGHTGRAY = :lightgray
  end

  COLOR_MAP = {
    :lightgray  => Color.from_u8(200, 200, 200, 255),
    :gray       => Color.from_u8(130, 130, 130, 255),
    :darkgray   => Color.from_u8(80, 80, 80, 255),
    :yellow     => Color.from_u8(253, 249, 0, 255),
    :gold       => Color.from_u8(255, 203, 0, 255),
    :orange     => Color.from_u8(255, 161, 0, 255),
    :pink       => Color.from_u8(255, 109, 194, 255),
    :red        => Color.from_u8(230, 41, 55, 255),
    :maroon     => Color.from_u8(190, 33, 55, 255),
    :green      => Color.from_u8(0, 228, 48, 255),
    :lime       => Color.from_u8(0, 158, 47, 255),
    :darkgreen  => Color.from_u8(0, 117, 44, 255),
    :skyblue    => Color.from_u8(102, 191, 255, 255),
    :blue       => Color.from_u8(0, 121, 241, 255),
    :darkblue   => Color.from_u8(0, 82, 172, 255),
    :purple     => Color.from_u8(200, 122, 255, 255),
    :violet     => Color.from_u8(135, 60, 190, 255),
    :darkpurple => Color.from_u8(112, 31, 126, 255),
    :beige      => Color.from_u8(211, 176, 131, 255),
    :brown      => Color.from_u8(127, 106, 79, 255),
    :darkbrown  => Color.from_u8(76, 63, 47, 255),
    :white      => Color.from_u8(255, 255, 255, 255),
    :black      => Color.from_u8(0, 0, 0, 255),
    :magenta    => Color.from_u8(255, 0, 255, 255),
  }

  def self.setup(renderer)
    @@bitmap_fonts = {}
    COLOR_NAME.each {|sym| @@bitmap_fonts[sym] = BitmapFont.new}

    bmp_fontsheet_rwops = SDL::RWFromFile('system/VP16Font.bmp', 'rb')

    background_rgb = COLOR_MAP[:white]

    @@bitmap_fonts.each do |color_sym, bitmap_font|
      bitmap_font.setup(renderer, bmp_fontsheet_rwops, COLOR_MAP[color_sym], background_rgb)
      SDL.RWseek(bmp_fontsheet_rwops, 0, SDL::RW_SEEK_SET)
    end

    SDL.RWclose(bmp_fontsheet_rwops)
  end

  def self.cleanup
    @@bitmap_fonts.each_value(&:cleanup)
  end

  def self.set(x, y, text, color = Text::WHITE, scale = 1.0)
    @@bitmap_fonts[color].set_text(x, y, text, scale)
  end

  def self.render(renderer)
    @@bitmap_fonts.each_value do |bitmap_font|
      bitmap_font.render(renderer)
    end
  end

end
