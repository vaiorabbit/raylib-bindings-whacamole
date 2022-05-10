require 'sdl2'
require_relative 'bitmap_font'
require_relative 'util'

class Text

  COLORS = [
    :lightgray,
    :gray,
    :darkgray,
    :yellow,
    :gold,
    :orange,
    :pink,
    :red,
    :maroon,
    :green,
    :lime,
    :darkgreen,
    :skyblue,
    :blue,
    :darkblue,
    :purple,
    :violet,
    :darkpurple,
    :beige,
    :brown,
    :darkbrown,
    :white,
    :black,
    :magenta,
  ].freeze

  LIGHTGRAY = :lightgray
  GRAY = :gray
  DARKGRAY = :darkgray
  YELLOW = :yellow
  GOLD = :gold
  ORANGE = :orange
  PINK = :pink
  RED = :red
  MAROON = :maroon
  GREEN = :green
  LIME = :lime
  DARKGREEN = :darkgreen
  SKYBLUE = :skyblue
  BLUE = :blue
  DARKBLUE = :darkblue
  PURPLE = :purple
  VIOLET = :violet
  DARKPURPLE = :darkpurple
  BEIGE = :beige
  BROWN = :brown
  DARKBROWN = :darkbrown
  WHITE = :white
  BLACK = :black
  MAGENTA = :magenta

  def self.setup(renderer)
    @@bitmap_fonts = {
      LIGHTGRAY => BitmapFont.new,
      GRAY => BitmapFont.new,
      DARKGRAY => BitmapFont.new,
      YELLOW => BitmapFont.new,
      GOLD => BitmapFont.new,
      ORANGE => BitmapFont.new,
      PINK => BitmapFont.new,
      RED => BitmapFont.new,
      MAROON => BitmapFont.new,
      GREEN => BitmapFont.new,
      LIME => BitmapFont.new,
      DARKGREEN => BitmapFont.new,
      SKYBLUE => BitmapFont.new,
      BLUE => BitmapFont.new,
      DARKBLUE => BitmapFont.new,
      PURPLE => BitmapFont.new,
      VIOLET => BitmapFont.new,
      DARKPURPLE => BitmapFont.new,
      BEIGE => BitmapFont.new,
      BROWN => BitmapFont.new,
      DARKBROWN => BitmapFont.new,
      WHITE => BitmapFont.new,
      BLACK => BitmapFont.new,
      MAGENTA => BitmapFont.new,
    }

    color_map = {
      LIGHTGRAY  => Color.from_u8(200, 200, 200, 255),
      GRAY       => Color.from_u8(130, 130, 130, 255),
      DARKGRAY   => Color.from_u8(80, 80, 80, 255),
      YELLOW     => Color.from_u8(253, 249, 0, 255),
      GOLD       => Color.from_u8(255, 203, 0, 255),
      ORANGE     => Color.from_u8(255, 161, 0, 255),
      PINK       => Color.from_u8(255, 109, 194, 255),
      RED        => Color.from_u8(230, 41, 55, 255),
      MAROON     => Color.from_u8(190, 33, 55, 255),
      GREEN      => Color.from_u8(0, 228, 48, 255),
      LIME       => Color.from_u8(0, 158, 47, 255),
      DARKGREEN  => Color.from_u8(0, 117, 44, 255),
      SKYBLUE    => Color.from_u8(102, 191, 255, 255),
      BLUE       => Color.from_u8(0, 121, 241, 255),
      DARKBLUE   => Color.from_u8(0, 82, 172, 255),
      PURPLE     => Color.from_u8(200, 122, 255, 255),
      VIOLET     => Color.from_u8(135, 60, 190, 255),
      DARKPURPLE => Color.from_u8(112, 31, 126, 255),
      BEIGE      => Color.from_u8(211, 176, 131, 255),
      BROWN      => Color.from_u8(127, 106, 79, 255),
      DARKBROWN  => Color.from_u8(76, 63, 47, 255),
      WHITE      => Color.from_u8(255, 255, 255, 255),
      BLACK      => Color.from_u8(0, 0, 0, 255),
      MAGENTA    => Color.from_u8(255, 0, 255, 255),
    }

    bmp_fontsheet_rwops = SDL::RWFromFile('system/VP16Font.bmp', 'rb')

    background_rgb = color_map[:white]

    @@bitmap_fonts.each do |color_sym, bitmap_font|
      bitmap_font.setup(renderer, bmp_fontsheet_rwops, color_map[color_sym], background_rgb)
      # [TODO] Add macro definitions to sdl2-bindings
      # #define RW_SEEK_SET 0       /**< Seek from the beginning of data */
      # #define RW_SEEK_CUR 1       /**< Seek relative to current read point */
      # #define RW_SEEK_END 2       /**< Seek relative to the end of data */
      SDL.RWseek(bmp_fontsheet_rwops, 0, 0)
    end
  end

  def self.cleanup
    @@bitmap_fonts.each_value do |bitmap_font|
      bitmap_font.cleanup
    end
  end

  def self.set(x, y, text, color = nil, scale = 1.0)
    @@bitmap_fonts[color].set_text(x, y, text, scale)
  end

  def self.render(renderer)
    @@bitmap_fonts.each_value do |bitmap_font|
      bitmap_font.render(renderer)
    end
  end

end
