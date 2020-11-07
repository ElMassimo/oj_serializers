# frozen_string_literal: true

# Internal: Provides a simple API on top of Hash for memoization purposes.
class OjSerializers::Memo
  def initialize
    @cache = {}
  end

  # Internal: Allows to clear the cache when binding the serializer to a
  # different object.
  def clear
    @cache.clear
  end

  # Public: Allows to use a simple memoization pattern that also works for
  # falsey values.
  def fetch(key)
    @cache.fetch(key) { @cache[key] = yield }
  end
end
