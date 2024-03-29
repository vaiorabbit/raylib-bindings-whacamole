# Yet another raylib wrapper for Ruby
#
# * https://github.com/vaiorabbit/raylib-bindings
#
# Demonstrates several key features including:
# * Core      : window management, camera, etc.
# * Gameplay  : fetching player input, collision handling, etc.
# * Rendering : drawing shapes, texts, etc.
#
# To get more information, see:
# * https://www.raylib.com/cheatsheet/cheatsheet.html for API reference
# * https://github.com/vaiorabbit/raylib-bindings/tree/main/examples for more actual codes written in Ruby

require 'raylib'
require_relative 'raylib/system/image'
require_relative 'raylib/system/input'
require_relative 'raylib/system/text'
require_relative 'raylib/system/timer'
require_relative 'raylib/system/draw'
require_relative 'raylib/system/sound'

shared_lib_path = Gem::Specification.find_by_name('raylib-bindings').full_gem_path + '/lib/'

case RUBY_PLATFORM
when /mswin|msys|mingw|cygwin/
  Raylib.load_lib(shared_lib_path + 'libraylib.dll', raygui_libpath: shared_lib_path + 'raygui.dll', physac_libpath: shared_lib_path + 'physac.dll')
when /darwin/
  Raylib.load_lib(shared_lib_path + 'libraylib.dylib', raygui_libpath: shared_lib_path + 'raygui.dylib', physac_libpath: shared_lib_path + 'physac.dylib')
else
  raise RuntimeError, "Unknown OS: #{RUBY_PLATFORM}"
end

include Raylib

if __FILE__ == $PROGRAM_NAME
  screen_width = 1280
  screen_height = 720
  InitWindow(screen_width, screen_height, "Yet Another Ruby-raylib bindings")
  SetTargetFPS(60)

  ruby_red = Color.from_u8(155, 17, 30, 255)

  # Camera
  camera = Camera.new
  reset_camera = lambda {
    camera[:position] = Vector3.create(0.0, 10.0, 10.0)
    camera[:target] = Vector3.create(0.0, 0.0, 0.0)
    camera[:up] = Vector3.create(0.0, 1.0, 0.0)
    camera[:fovy] = 45.0
    camera[:projection] = CAMERA_PERSPECTIVE
  }
  reset_camera.call
  SetCameraMode(camera, CAMERA_FREE)
  auto_rotate = false

  # Player (red cube) settings
  player_pos = Vector3.create(0.0, 0.0, 0.0)
  player_size = Vector3.create(2.0, 2.0, 2.0)
  speed = 0.25

  # Obstacle settings
  obstacle_cube_pos = Vector3.create(-4.0, 1.0, 0.0)
  obstacle_cube_size = Vector3.create(2.0, 2.0, 2.0)
  obstacle_sphere_pos = Vector3.create(4.0, 0.0, 0.0)
  obstacle_sphere_size = 1.5

  image = Image.new
  image.setup('asset/effect/hit_effect.png')

  Text.setup

  circle = Circle::Cache.new(radius: 15.0, r: 255, g: 32, b: 32, a: 128)

  InitAudioDevice()
#  bgm = Sound::Bgm.new('asset/sound/GameOver.mp3').setup
  bgm = Sound::Bgm.new('asset/sound/Main.mp3').setup
  sefx = Sound::Sefx.new('asset/sound/swing2.wav').setup

  game_timer = Timer.new
  game_timer.setup
  game_timer.start

  dt = 0.0

  input = Input.new
  input.setup
  input.screen_width = screen_width
  input.screen_height = screen_height

  mapping = InputMapping.new(:title)
  # mapping.register_key(:exit_game, Raylib::KEY_ESCAPE)
  mapping.register_key(:start_game, Raylib::KEY_SPACE)
  # mapping.register_button(:exit_game, SDL::CONTROLLER_BUTTON_BACK, gamepad_id: 0)
  # mapping.register_button(:start_game, SDL::CONTROLLER_BUTTON_START, gamepad_id: 0)
  # mapping.register_mouse(:start_game, SDL::BUTTON_LEFT, repeat_enabled: false)
  mapping.register_mouse(:resume_game, Raylib::MOUSE_BUTTON_LEFT)
  mapping.register_button(:resume_game, Raylib::GAMEPAD_BUTTON_RIGHT_FACE_DOWN, repeat_enabled: true, repeat_interval: 5)

  input.register_mapping(mapping)
  input.set_mapping(:title)

  until WindowShouldClose()
    ### Update phase

    input.handle_event
    input.update

    if input.down? :start_game
      p 'start_game'
    end
    if input.trigger? :resume_game
      p 'resume_game'
    end
    # p [input.mouse_pos_x, input.mouse_pos_y, input.mouse_rel_x, input.mouse_rel_y]

    Sound::Bgm.update(dt)
    if IsKeyPressed(KEY_S)
      Sound::Bgm.play(bgm, do_loop: true)
    end
    if IsKeyPressed(KEY_F)
      Sound::Bgm.fadeout(sec: 1.0)
    end
    if IsKeyPressed(KEY_H)
      sefx.play
    end

    # Reset camera settings
    if IsKeyPressed(KEY_F1)
      auto_rotate = !auto_rotate
      reset_camera.call
      SetCameraMode(camera, auto_rotate ? CAMERA_ORBITAL : CAMERA_FREE)
    end
    UpdateCamera(camera)

    # Calculate move direction
    move = Vector3.create(0, 0, 0)
    move[:x] += speed if IsKeyDown(KEY_RIGHT)
    move[:x] -= speed if IsKeyDown(KEY_LEFT)
    move[:z] += speed if IsKeyDown(KEY_DOWN)
    move[:z] -= speed if IsKeyDown(KEY_UP)

    to_camera = Vector3Normalize(Vector3.create(camera[:position][:x], 0, camera[:position][:z]))
    rotate_y = QuaternionFromVector3ToVector3(Vector3.create(0, 0, 1), to_camera)
    move = Vector3RotateByQuaternion(move, rotate_y)

    player_pos = Vector3Add(player_pos, move)
    player_screen_pos = GetWorldToScreen(Vector3.create(player_pos[:x], player_pos[:y] + 2.5, player_pos[:z]), camera)

    # Check collision status
    collision = false

    player_bbox = BoundingBox.create(player_pos[:x] - player_size[:x]/2,
                                     player_pos[:y] - player_size[:y]/2,
                                     player_pos[:z] - player_size[:z]/2,
                                     player_pos[:x] + player_size[:x]/2,
                                     player_pos[:y] + player_size[:y]/2,
                                     player_pos[:z] + player_size[:z]/2)

    obstacle_cube_bbox = BoundingBox.create(obstacle_cube_pos[:x] - obstacle_cube_size[:x]/2,
                                            obstacle_cube_pos[:y] - obstacle_cube_size[:y]/2,
                                            obstacle_cube_pos[:z] - obstacle_cube_size[:z]/2,
                                            obstacle_cube_pos[:x] + obstacle_cube_size[:x]/2,
                                            obstacle_cube_pos[:y] + obstacle_cube_size[:y]/2,
                                            obstacle_cube_pos[:z] + obstacle_cube_size[:z]/2)

    # Check collisions player vs obstacle_cube
    collision = true if CheckCollisionBoxes(player_bbox, obstacle_cube_bbox)

    # Check collisions player vs obstacle_sphere
    collision = true if CheckCollisionBoxSphere(player_bbox, obstacle_sphere_pos, obstacle_sphere_size)

    Text.set(0, 0, 'Hello', Raylib::RED)
    Text.set(0, 16, 'World', Raylib::BLUE)

    ### Rendering phase

    BeginDrawing()

      ClearBackground(RAYWHITE)

      ## 3D scene
      BeginMode3D(camera)
        # Red cube
        DrawCube(player_pos, 2.0, 2.0, 2.0, collision ? Fade(ruby_red, 0.25) : ruby_red)
        DrawCubeWires(player_pos, 2.0, 2.0, 2.0, MAROON)
        # Obstacle cube
        DrawCube(obstacle_cube_pos, obstacle_cube_size[:x], obstacle_cube_size[:y], obstacle_cube_size[:z], GRAY)
        DrawCubeWires(obstacle_cube_pos, obstacle_cube_size[:x], obstacle_cube_size[:y], obstacle_cube_size[:z], DARKGRAY)
        # Obstacle sphere
        DrawSphere(obstacle_sphere_pos, obstacle_sphere_size, GRAY)
        DrawSphereWires(obstacle_sphere_pos, obstacle_sphere_size, 16, 16, DARKGRAY)
        # Floor
        DrawGrid(10, 1)
      EndMode3D()

      ## HUD
      # Text over the red cube
      DrawText("Player HP: 100 / 100", player_screen_pos[:x] - MeasureText("Player HP: 100/100", 20)/2, player_screen_pos[:y], 20, BLACK)
      # Help message
      DrawRectangle(10, screen_height - 100, 300, 80, Fade(MAROON, 0.25))
      DrawRectangleLines(10, screen_height - 100, 300, 80, ruby_red)
      DrawText("Arrow keys : move red cube", 20, screen_height - 90, 20, BLACK)
      DrawText("F1 : camera rotation", 20, screen_height - 70, 20, BLACK)
      DrawText("ESC : exit", 20, screen_height - 50, 20, BLACK)
      # FPS
      DrawFPS(screen_width - 100, 16)

      image.x = 60
      image.y = 60
      image.render

      Text.render

      Circle.render(circle, 200, 200)

    EndDrawing()

    dt = game_timer.elapsed
    game_timer.start
  end

  sefx.cleanup
  bgm.cleanup

  image.cleanup

  input.unset_mapping
  input.cleanup

  Text.cleanup

  CloseAudioDevice()
  CloseWindow()
end
