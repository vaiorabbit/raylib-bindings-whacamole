class WhacAMole

  ##################################################
  # WhacAMole::MoleStatus

  class MoleStatus

    ##################################################
    # WhacAMole::MoleStatus::HitInfo

    class HitInfo
      attr_reader :active, :rect_min, :rect_max, :time_current, :time_end

      def initialize
        @active = false
        @time_current = 0.0
        @time_end = 0.0

        @rect_min = [0.0, 0.0]
        @rect_max = [0.0, 0.0]
      end

      def reset(time_end: 2.0)
        @active = false
        @time_current = 0.0
        @time_end = time_end
      end

      def start_detection
        @active = true
        @time_current = 0.0
      end

      def stop_detection
        @active = false
        @time_current = 0.0
      end

      def set_rect(min_x, min_y, max_x, max_y)
        @rect_min[0] = min_x
        @rect_min[1] = min_y
        @rect_max[0] = max_x
        @rect_max[1] = max_y
      end

      def update(dt)
        @time_current += dt
        if @time_current > @time_end
          @time_current = @time_end
          @active = false
        end
      end

    end

    ##################################################
    # WhacAMole::MoleStatus::Animation

    class Animation
      STATES = [:hidden, :go_up, :go_down, :appeared]

      attr_reader :state, :running, :time_current, :time_end
      attr_reader :scale_x, :scale_y

      def initialize
        reset
      end

      def reset(time_end: 2.0)
        @state = :hidden
        @running = false
        @time_current = 0.0
        @time_end = time_end
        @scale_x = 0.0
        @scale_y = 0.0
      end

      def go_up
        return if @state == :go_up

        # TODO make configurable
        @state = :go_up
        @time_current = 0.0
        @time_end = 0.0625
        @scale_x = 1.0
        @scale_y = 0.0
        @running = true
      end

      def go_down
        return if @state == :go_down

        # TODO make configurable
        @state = :go_down
        @time_current = 0.0
        @time_end = 0.0625
        @scale_x = 1.0
        @scale_y = 1.0
        @running = true
      end

      def update(dt)
        return if not @running

        if @time_current > @time_end
          @time_current = @time_end
          @running = false
        end

        case @state
        when :go_up
          # Evaluate a quadratic function:
          #   y = a * x^2 + b * x + c  (where a = -2.5, b = 3.5 and c = 0)
          # This function produces:
          # - y = 1.2 at x = 0.8
          # - y = 1.0 at x = 1.0
          t = @time_current / @time_end
          a = -2.5
          b = 3.5
          @scale_y = a * t ** 2 + b * t # @scale_y = 1.0 * [1.0, t].min
          @scale_x = [0.8, [1.0, t].min].max
          if @running == false
            @state = :appeared
          end
        when :go_down
          @scale_y = [0.0, 1.0 - (@time_current / @time_end)].max
          if @running == false
            @state = :hidden
          end
        end

        @time_current += dt
      end
    end

    ##################################################
    # WhacAMole::MoleStatus

    attr_accessor :id, :position_x, :position_y

    def initialize(id)
      @id = id
      @hit_info = HitInfo.new
      @animation = Animation.new
      @position_x = 0.0
      @position_y = 0.0
    end

    def hit_rect_min = @hit_info.rect_min
    def hit_rect_max = @hit_info.rect_max
    def reset(time_end: 2.0) = @hit_info.reset(time_end:)
    def hit_detection_active? = @hit_info.active
    def start_hit_detection = @hit_info.start_detection
    def stop_hit_detection = @hit_info.stop_detection

    def animation_state = @animation.state
    def animation_scale_x = @animation.scale_x
    def animation_scale_y = @animation.scale_y
    def visible? = @animation.state != :hidden
    def set_hit_rect(min_x, min_y, max_x, max_y) = @hit_info.set_rect(min_x, min_y, max_x, max_y)

    def go_up
      @animation.go_up
      @hit_info.start_detection
    end

    def go_down
      @animation.go_down
      @hit_info.stop_detection
    end

    def overlap_with_circle?(circle_x, circle_y, circle_radius)
      return false if not @hit_info.active
      x_inside = ((@hit_info.rect_min[0] - circle_radius) <= circle_x) && (circle_x <= (@hit_info.rect_max[0] + circle_radius))
      return false if not x_inside
      y_inside = ((@hit_info.rect_min[1] - circle_radius) <= circle_y) && (circle_y <= (@hit_info.rect_max[1] + circle_radius))
      return y_inside
    end

    def update(dt)
      @hit_info.update(dt)
      @animation.update(dt)
    end
  end

  ##################################################
  # WhacAMole

  attr_reader :game_over, :moles_status, :score, :visible_time_current

  EVENT_ID = [:event_unknown, :event_appear, :event_hide, :event_finish]

  # 0 : time to trigger this event
  # 1 : event ID (appear / hide / finish)
  # 2 : moles to be appeared
  EVENT_SAMPLE = [
    [ 0.0, :event_appear, [0, 1, 2]],
    [ 1.0, :event_hide, nil],
    [ 1.5, :event_appear, [3, 4, 5]],
    [ 2.5, :event_hide, nil],
    [ 3.0, :event_appear, [6, 7, 8]], # [ 3.0, :event_appear, [*0...16]],
    [ 4.5, :event_finish, nil],
  ]

  def choose_random_moles(rng: Random.new, moles_choose: 3, moles_count: 9)
    moles = []
    moles_choose.times do |i|
      id = rng.rand(moles_count)
      redo if moles.include? id
      moles << id
    end
    moles
  end

  def generate_random_event(seed: 12345, game_duration: 30.0, moles_count: 9, first_appear_time: 0.0,  appear_duration_normal: 1.0, hide_duration_normal: 0.5, appear_duration_fast: 0.9, hide_duration_fast: 0.25)
    random = Random.new(seed)
    schedule = []
    time = first_appear_time

    actual_duration = game_duration - first_appear_time
    get_difficulty_entry = lambda { |time|
      difficulty_table = [
        [first_appear_time + 0.0,                    1, appear_duration_normal, hide_duration_normal],
        [first_appear_time + 0.4  * actual_duration, 2, appear_duration_normal, hide_duration_normal],
        [first_appear_time + 0.7 * actual_duration, 3, appear_duration_normal, hide_duration_normal],
        [first_appear_time + 0.85 * actual_duration, 5, appear_duration_fast, hide_duration_fast],
      ]
      difficulty_table.each do |entry|
        return entry if time <= entry[0]
      end
      return difficulty_table.last
    }

    while time < game_duration
      difficulty_info = get_difficulty_entry.call(time)
      moles_choose = difficulty_info[1]
      appear_duration = difficulty_info[2]
      hide_duration = difficulty_info[3]

      schedule << [time, :event_appear, choose_random_moles(rng: random, moles_choose: moles_choose, moles_count: moles_count)]
      time += appear_duration
      break if time > game_duration
      schedule << [time, :event_hide, nil]
      time += hide_duration
      break if time > game_duration
    end

    schedule << [game_duration, :event_finish, nil]

    return schedule
  end

  def initialize(row:, col:) # TODO make configurable
    @row = row
    @col = col
    @moles = row * col
    @score = 0
    @time_current = 0.0
    @time_end = 0.0
    @game_over = false

    @moles_status = Array.new(@moles)
    @moles_status.length.times do |i|
      @moles_status[i] = MoleStatus.new(i)
    end

    reset
  end

  def reset
    @moles_status.each do |status|
      status.reset
    end

    @event_schedule = EVENT_SAMPLE
    @event_schedule = generate_random_event()

    @score = 0
    @time_current = 0.0
    @time_end = @event_schedule.last[0] # 30.0 #  TODO make configurable
    @game_over = false

    @prev_event = nil
    @current_event = nil
  end

  def update_event
    @prev_event = @current_event

    event = nil
    @event_schedule.each do |e|
      if e[0] <= @time_current
        event = e
        next
      else
        @current_event = event
        return
      end
    end
    @current_event = @event_schedule.last
  end

  def event_triggered?
    @prev_event != @current_event
  end

  def current_event_symbol
    @current_event[1]
  end

  def setup(services)
  end

  def cleanup
  end

  def add_score(score)
    @score += score
  end

  def total_moles_count
    moles_count = 0
    @event_schedule.each do |e|
      moles_count += (e[2].nil? ? 0 : e[2].length)
    end
    moles_count
  end

  def time_left
    @time_end - @time_current
  end

  def update(dt)
    @time_current += dt
    update_event
    if event_triggered? && @current_event
      case @current_event[1]
      when :event_appear
        ids = @current_event[2]
        ids.each do |id|
          @moles_status[id].start_hit_detection
          @moles_status[id].go_up
        end
      when :event_hide
        @moles_status.each do |status|
          status.stop_hit_detection
          status.go_down if status.animation_state != :hidden
        end
      when :event_finish
        @game_over = true
        @moles_status.each do |status|
          status.go_down if status.animation_state != :hidden
        end
      end
    end

    @moles_status.each do |status|
      status.update(dt)
    end
  end

  def render
  end
end
