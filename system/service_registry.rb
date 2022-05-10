class Service
  attr_reader :requests

  def initialize
    @requests = []
  end

  protected

  def request_services(*reqs)
    @requests.push(*reqs)
  end
end

####################################################################################################

class ServiceRegistry
  def initialize
    @services = Hash.new
    @external_services = Hash.new
  end

  def register(id, instance)
    raise RuntimeError "Service ID #{id} is already registered" if @services.key?(id) || @external_services.key?(id)
    @services[id] = instance
  end

  def register_external(id, instance)
    raise RuntimeError "Service ID #{id} is already registered" if @services.key?(id) || @external_services.key?(id)
    @external_services[id] = instance
  end

  def setup
  end

  def cleanup
    @services.each do |id, instance|
      instance.cleanup
    end
    @external_services.clear
  end

  def unregister(id)
    if @services.key?(id)
      @services.delete(id)
    elsif @external_services.key?(id)
      @external_services.delete(id)
    end
  end

  def get(id)
    if @services.key?(id)
      @services[id]
    elsif @external_services.key?(id)
      @external_services[id]
    else
      raise RuntimeError "Service ID #{id} is not registered"
      nil
    end
  end

  def setup_instance(instance)
    services = Hash.new
    instance.requests.each do |id|
      services[id] = get(id)
    end
    instance.setup(services)
  end

  def resolve
  end
end
