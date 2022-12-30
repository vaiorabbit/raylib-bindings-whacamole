require 'sdl2'

class Timer
  def initialize
    @start = 0
    @now = 0
    @frequency = 0
  end

  def setup(frequency)
    @frequency = frequency
  end

  def cleanup; end

  def start
    @start = SDL::GetPerformanceCounter()
  end

  def now
    @now = SDL::GetPerformanceCounter()
  end

  def elapsed
    diff(now, @start)
  end

  private

  def diff(count_end, count_start)
    (count_end - count_start).to_f / @frequency
  end
end
