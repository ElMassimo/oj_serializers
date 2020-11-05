# frozen_string_literal: true

# Public: An example on how the writer can be modified to do funky stuff.
class NonBlankJsonWriter < DelegateClass(Oj::StringWriter)
  def self.new
    super(Oj::StringWriter.new(mode: :rails))
  end

  def push_value(value, key = nil)
    super if value.present?
  end

  # Internal: Used by Oj::Rails::Encoder because we use the `raw_json` option.
  def raw_json(*)
    # We need to pass no arguments to `Oj::StringWriter` because it expects 0 arguments
    # because its method definition `oj_dump_raw_json` defined in the C classes is defined
    # without arguments. Oj gets confused because it checks if the class is `Oj::StringWriter`
    # and if it is, then it passes 0 arguments, but when it's not (e.g. `NonBlankJsonWriter`)
    # then it passes both. So in this case, we're calling super() to `Oj::StringWriter` with
    # two arguments.
    #
    # https://github.com/ohler55/oj/commit/d0820d2ac1a72584329bc6451d430737a27f99ac#diff-854d0b67397d7006482043d1202c9647R532
    super()
  end
end
