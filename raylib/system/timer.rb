require 'raylib'

class Timer
  def initialize
    @start = 0
    @now = 0
  end

  def setup
  end

  def cleanup; end

  def start
    @start = Raylib.GetTime()
  end

  def now
    @now = Raylib.GetTime()
  end

  def elapsed
    diff(now, @start)
  end

  private

  def diff(count_end, count_start)
    (count_end - count_start).to_f
  end
end
