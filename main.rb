require 'sdl2'
require_relative 'system/application'
require_relative 'system/draw'
require_relative 'system/services'

require_relative 'game/layout'
require_relative 'game/objects/background'
require_relative 'game/objects/grass'
require_relative 'game/objects/hammer'
require_relative 'game/objects/hit_effect'
require_relative 'game/objects/mole'
require_relative 'game/states/title_state'
require_relative 'game/states/ready_state'
require_relative 'game/states/main_state'
require_relative 'game/states/pause_state'
require_relative 'game/states/finish_state'
require_relative 'game/states/result_state'

def load_sdl2_lib
  case RbConfig::CONFIG['host_os']
  when /mswin|msys|mingw|cygwin/
    SDL.load_lib(Dir.pwd + '/SDL2.dll')
  when /darwin/
    SDL.load_lib('/opt/homebrew/lib/libSDL2.dylib', output_error = false, image_libpath: '/opt/homebrew/lib/libSDL2_image.dylib', mixer_libpath: '/opt/homebrew/lib/libSDL2_mixer.dylib', ttf_libpath: '/opt/homebrew/lib/libSDL2_ttf.dylib')
  when /linux/
    SDL.load_lib('libSDL2.so') # not tested
  else
    raise 'Unsupported platform.'
  end
end

if __FILE__ == $PROGRAM_NAME
  load_sdl2_lib
  app = Application.new(title: "Whac-a-Mole! : Ruby SDL2 bindings demo",
                        screen_width: Layout.size(:screen)[0], screen_height: Layout.size(:screen)[1],
                        clear_r: 140, clear_g: 200, clear_b: 90, clear_a: 255)

  # Register instances of game states
  app.register_game_state(TitleState.new(:title), initial_state: true)
  app.register_game_state(ReadyState.new(:ready))
  app.register_game_state(MainState.new(:main))
  app.register_game_state(PauseState.new(:pause))
  app.register_game_state(FinishState.new(:finish))
  app.register_game_state(ResultState.new(:result))

  # Register game-specific services
  setup_func = Proc.new do |services|
    # Give your game-specific objects ID and register to "services (instance of system/service")
    # [NOTE] Services called
    # - ":Renderer (pointer to SDL_Renderer)" and
    # - ":Input (instance of system/input)"
    # are provided by the system and always available by default.
    services.register(:Hammer, Hammer.new.setup(services.get(:Renderer), services.get(:Input)))
    services.register(:CursorCircle, Circle::Cache.new(radius: 15.0, r: 255, g: 32, b: 32, a: 128))

    mole = Mole.new.setup(services.get(:Renderer), services.get(:Input))
    services.register(:Mole, mole)

    row, col = 3, 3
    whacamole = WhacAMole.new(row: row, col: col)
    row.times do |y|
      col.times do |x|
        id = col * y + x
        status = whacamole.moles_status[id]
        pos_x = Layout.position(:mole_first)[0] + (Layout.size(:mole_image)[0] + Layout.size(:mole_gap)[0]) * x
        pos_y = Layout.position(:mole_first)[1] + (Layout.size(:mole_image)[1] + Layout.size(:mole_gap)[1]) * y
        status.position_x = pos_x
        status.position_y = pos_y
        status.set_hit_rect(pos_x, pos_y, pos_x + mole.width, pos_y + mole.height)
      end
    end
    services.register(:WhacAMole, whacamole)

    services.register(:Grass, Grass.new.setup(services.get(:Renderer), whacamole))
    services.register(:Background, Background.new.setup(services.get(:Renderer)))
    services.register(:HitEffects, HitEffects.new.setup(services.get(:Renderer)))
  end

  app.setup(setup_func)
  app.main
  app.cleanup
end
