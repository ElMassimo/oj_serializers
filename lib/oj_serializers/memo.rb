# frozen_string_literal: true

# Internal: Provides a simple API on top of Hash for memoization purposes.
class OjSerializers::Memo
  def initialize
    @cache = {}
  end

  def clear
    @cache.clear
  end

  def fetch(key)
    @cache.fetch(key) { @cache[key] = yield }
  end
end
