require 'raylib'

module Sound

  class Bgm
    attr_reader :stream

    @@in_fade = false
    @@fade_sec = 0
    @@fade_elapsed = 0
    @@volume = 1.0
    @@current_bgm = nil

    def initialize(music_path)
      @path = music_path
    end

    def setup
      @stream = Raylib.LoadMusicStream(@path)
      self
    end

    def cleanup
      Raylib.UnloadMusicStream(@stream)
      @stream = nil
    end

    ##################################################

    def self.reset
      @@in_fade = false
      @@fade_sec = 0
      @@fade_elapsed = 0
      @@volume = 1.0
    end

    def self.play(bgm, do_loop: true)
      self.reset
      @@current_bgm = bgm
      return if bgm.nil?
      @@current_bgm.stream[:looping] = do_loop
      Raylib.StopMusicStream(@@current_bgm.stream)
      Raylib.SetMusicVolume(@@current_bgm.stream, @@volume)
      Raylib.PlayMusicStream(@@current_bgm.stream)
    end

    def self.update(dt)
      return if @@current_bgm.nil? or @@current_bgm.stream.nil?
      if @@in_fade
        @@fade_elapsed += dt
        @@volume = ((@@fade_sec - @@fade_elapsed) / @@fade_sec).clamp(0.0, 1.0)
        Raylib.SetMusicVolume(@@current_bgm.stream, @@volume)
        if @@fade_elapsed >= @@fade_sec
          @@in_fade = false
          Raylib.StopMusicStream(@@current_bgm.stream)
        end
      end
      Raylib.UpdateMusicStream(@@current_bgm.stream)
    end

    def self.pause
      Raylib.PauseMusicStream(@@current_bgm.stream) unless @@current_bgm.nil?
    end

    def self.resume
      Raylib.ResumeMusicStream(@@current_bgm.stream) unless @@current_bgm.nil?
    end

    def self.fadeout(sec: 1.0)
      @@in_fade = true
      @@fade_sec = sec
      @@fade_elapsed = 0
    end

    def self.halt
      Raylib.StopMusicStream(@@current_bgm.stream) unless @@current_bgm.nil?
    end
  end

  class Sefx
    def initialize(wav_path)
      @path = wav_path
    end

    def setup
      @sefx = Raylib.LoadSound(@path)
      self
    end

    def cleanup
      Raylib.UnloadSound(@sefx)
      @sefx = nil
    end

    def play
      Raylib.PlaySound(@sefx)
    end
  end
end
