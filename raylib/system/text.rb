require 'raylib'

module Text

  Message = Struct.new(:text, :x, :y, :scale, keyword_init: true)

  def self.setup
    @@texts = {}
    @@font = Raylib.LoadFont('raylib/system/VP16Font_XNA.png')
    @@font_size = @@font[:baseSize].to_f
  end

  def self.cleanup
    Raylib.UnloadFont(@@font)
  end

  def self.set(x, y, text, color = Raylib::WHITE, scale = 1.0)
    @@texts[color] = [] unless @@texts.has_key? color
    @@texts[color] << Message.new(text: text, x: x, y: y, scale: scale)
  end

  def self.render
    @@texts.each do |color, msgs|
      msgs.each do |msg|
        Raylib.DrawTextEx(@@font, msg.text, Vector2.create(msg.x, msg.y), @@font_size, 0, color)
      end
    end
    @@texts.clear
  end

end
