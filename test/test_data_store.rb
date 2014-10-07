require 'test_helper'

require 'rate_limiter/data_store'

class DataStoreTest < Minitest::Test
  def setup
    @data_store = DataStore.new
  end

  def test_store_stores_and_retrieves_values
    @data_store.set('key', 'value')

    assert_equal 'value', @data_store.get('key')
  end
end
