require_relative 'services'

class GameState
  attr_reader :state_id
  attr_accessor :manager
  private attr_accessor :renderer, :input

  def initialize(state_id)
    raise ArgumentError unless state_id.is_a? Symbol

    @state_id = state_id
    @manager = nil
    @renderer = nil
    @input = nil
  end

  def setup(services)
    @renderer = services.get(:Renderer)
    @input = services.get(:Input)
  end

  def cleanup
    @renderer = nil
    @input = nil
  end

  def enter(prev_state_id); end

  def leave(next_state_id); end

  def update(_dt, _input)
    # return next state ID you want to switch
    @state_id

    # or you can return next state ID and a request to the manager like this:
    # return @state_id, (game_over ? GameStateManager::STATE_REQUEST_EXIT : nil)
  end

  def render; end
end

# # e.g.)
# state_manager = GameStateManager.new
# state_manager.register(TitleState.new(:title))
# state_manager.register(MainState.new(:main))
# state_manager.register(EndState.new(:end))
# state_manager.initial_state_id = :title
# state_manager.setup(renderer, input)
# state_manager.start
# until end_game do
#   state_manager.update(dt) # some state may set REQUEST_EXIT here
#   state_manager.render()
#   end_game = (state_manager.request & REQUEST_EXIT) != 0
# end
# state_manager.cleanup
class GameStateManager
  attr_accessor :initial_state_id
  attr_reader :current_state, :current_state_id, :state_request

  STATE_REQUEST_NONE = 0b00
  STATE_REQUEST_EXIT = 0b01
  STATE_REQUESTS = [
    STATE_REQUEST_NONE,
    STATE_REQUEST_EXIT,
  ]

  def initialize
    @initial_state_id = :gamestate_manager_initialized
    @current_state_id = @initial_state_id
    @current_state = nil
    @states = {}
    @state_request = STATE_REQUEST_NONE
  end

  def setup(services)
    @states.each_value do |state|
      state.setup(services)
    end
  end

  def cleanup
    @states.each_value(&:cleanup)
    @current_state = nil
  end

  def register(state)
    state.manager = self
    @states[state.state_id] = state
  end

  def unregister(state_id)
    state = @states.delete(state_id)
    state.manager = nil unless state.nil?
    state
  end

  def start
    @current_state = @states[@initial_state_id]
    @current_state_id = @current_state.state_id
    @current_state.enter(:gamestate_manager_started)
  end

  def update(dt)
    @state_request = STATE_REQUEST_NONE
    next_state_id, request = @current_state.update(dt)

    unless request.nil?
      raise RuntimeError unless STATE_REQUESTS.include? request
      @state_request = request
    end

    return unless next_state_id != @current_state_id

    prev_state_id = @current_state_id
    @current_state.leave(next_state_id)
    @current_state = @states[next_state_id]
    @current_state.enter(prev_state_id)
    @current_state_id = @current_state.state_id
  end

  def render
    @current_state.render
  end
end
