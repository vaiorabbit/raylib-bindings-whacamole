require 'sdl2'

module Sound
  class Bgm
    def initialize(music_path)
      @path = music_path
    end

    def setup
      @bgm = SDL.Mix_LoadMUS_RW(SDL.RWFromFile(@path, 'rb'), 1) # 1 == freesrc
      self
    end

    def cleanup
      SDL.Mix_FreeMusic(@bgm)
      @bgm = nil
    end

    def play(do_loop: true)
      SDL.Mix_PlayMusic(@bgm, do_loop ? -1 : 0)
    end

    ##################################################

    def self.fadeout(ms: 500)
      SDL.Mix_FadeOutMusic(ms)
    end

    def self.halt
      SDL.Mix_HaltMusic()
    end
  end

  class Sefx
    def initialize(wav_path)
      @path = wav_path
    end

    def setup
      @sefx = SDL.Mix_LoadWAV_RW(SDL.RWFromFile(@path, 'rb'), 1) # 1 == freesrc
      self
    end

    def cleanup
      SDL.Mix_FreeChunk(@sefx)
      @sefx = nil
    end

    def play(do_loop: false)
      SDL.Mix_PlayChannelTimed(-1, @sefx, do_loop ? -1 : 0, -1)
    end
  end
end
