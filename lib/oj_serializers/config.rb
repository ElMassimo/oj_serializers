# frozen_string_literal: true

class OjSerializers::Config
  attr_accessor :cache

  def initialize
    self.cache = (defined?(Rails) && Rails.cache) ||
                 (defined?(ActiveSupport::Cache::MemoryStore) ? ActiveSupport::Cache::MemoryStore.new : OjSerializers::Memo.new)
  end
end
