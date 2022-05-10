module Layout
  @@positions = {
    :background => [0, 0],
    :finish_header => [250, 300],
    :mole_first => [50, 150],
    :score_header => [32, 16],
    :score_current => [32, 32],
    :ready_header => [250, 300],
    :result_header => [250, 200],
    :result_score => [150, 296],
    :result_moles => [150, 312],
    :result_rate => [150, 328],
    :time_header => [280, 16],
    :time_current => [265, 32],
  }

  @@sizes = {
    :background_image => [600, 180],
    :font => [16, 16],
    :grass_image => [160, 30],
    :grass_image_offset => [0, 87],
    :hit_image => [50, 50],
    :hammer_image => [200, 200],
    :hammer_image_offset => [-35, -210],
    :mole_gap => [25, 5],
    :mole_image => [150, (150 * (663.0 / 800)).to_i],
    :screen => [600, 550],
  }

  def self.position(id)
    raise ArgumentError unless @@positions.keys.include? id
    @@positions[id]
  end

  def self.size(id)
    raise ArgumentError unless @@sizes.keys.include? id
    @@sizes[id]
  end
end
