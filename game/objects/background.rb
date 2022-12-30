require 'sdl2'
require_relative '../layout'
require_relative '../../system/image'

class Background
  def initialize
    @background_image = Image.new
  end

  def width = @background_image.width
  def height = @background_image.height

  def setup(renderer)
    @background_image.setup('asset/field/background.png')
    @background_image.width = Layout.size(:background_image)[0]
    @background_image.height = Layout.size(:background_image)[1]
    self
  end

  def cleanup
    @background_image.cleanup
  end

  def update(dt)
  end

  def render_background()
    @background_image.render()
  end

  def render_ui(score, time_left)
    Text.set(Layout.position(:score_header)[0], Layout.position(:score_header)[1], "SCORE", Raylib::RED)
    Text.set(Layout.position(:score_current)[0], Layout.position(:score_current)[1], score.to_s.rjust(5), Raylib::WHITE)

    Raylib.DrawRectangle(
      Layout.position(:score_header)[0] - Layout.size(:font)[0] / 2,
      Layout.position(:score_header)[1] - Layout.size(:font)[1] / 2,
      Layout.size(:font)[0] * "SCORE".chars.length + Layout.size(:font)[0],
      Layout.size(:font)[1] * 3,
      Raylib::Color.from_u8(0, 0, 0, 96)
    )

    Text.set(Layout.position(:time_header)[0], Layout.position(:time_header)[1], "TIME", Raylib::RED)
    Text.set(Layout.position(:time_current)[0], Layout.position(:time_current)[1], "#{('%2.3f' % time_left).rjust(6)}", Raylib::WHITE)

    Raylib.DrawRectangle(
      Layout.position(:time_current)[0] - Layout.size(:font)[0] / 2,
      Layout.position(:time_header)[1] - Layout.size(:font)[1] / 2,
      Layout.size(:font)[0] * 6 + Layout.size(:font)[0],
      Layout.size(:font)[1] * 3,
      Raylib::Color.from_u8(0, 0, 0, 96)
    )
  end

end
