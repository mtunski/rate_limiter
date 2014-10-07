class DataStore
  def initialize
    @data = {}
  end

  def get(key)
    @data[key]
  end

  def set(key, value)
    @data[key] = value
  end
end
