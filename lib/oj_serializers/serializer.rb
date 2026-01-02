# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/string/inflections'

require 'oj'
require 'oj_serializers/memo'
require 'oj_serializers/json_value'

# Public: Implementation of an "ActiveModelSerializer"-like DSL, but with a
# design that allows replacing the internal object, which greatly reduces object
# allocation.
#
# Unlike ActiveModelSerializer, which builds a Hash which then gets encoded to
# JSON, this implementation allows to use Oj::StringWriter to write directly to
# JSON, greatly reducing the overhead of allocating and garbage collecting the
# hashes.
class OjSerializers::Serializer
  # Public: Used to validate incorrect memoization during development. Users of
  # this library might add additional options as needed.
  ALLOWED_INSTANCE_VARIABLES = %w[
    memo
    object
    options
    _routes
  ]

  KNOWN_ATTRIBUTE_OPTIONS = %i[
    attribute
    association
    identifier
    if
    optional
    type
    serializer
  ].to_set

  CACHE = (defined?(Rails) && Rails.cache) ||
          (defined?(ActiveSupport::Cache::MemoryStore) ? ActiveSupport::Cache::MemoryStore.new : OjSerializers::Memo.new)

  # Internal: The environment the app is currently running on.
  environment = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'production'

  # Internal: Used to display warnings or detect misusage during development.
  DEV_MODE = %w[test development].include?(environment) && !ENV['BENCHMARK']

  DEFAULT_OPTIONS = {}.freeze

  # Backwards Compatibility: Allows to access options passed through `render json`,
  # in the same way than ActiveModel::Serializers.
  def options
    @options || DEFAULT_OPTIONS
  end

  # NOTE: Helps developers to remember to keep serializers stateless.
  if DEV_MODE
    def _check_instance_variables
      if instance_values.keys.any? { |key| !ALLOWED_INSTANCE_VARIABLES.include?(key) }
        bad_keys = instance_values.keys.reject { |key| ALLOWED_INSTANCE_VARIABLES.include?(key) }
        raise ArgumentError, "Serializer instances are reused so they must be stateless. Use `memo.fetch` for memoization purposes instead. Bad keys: #{bad_keys.join(',')} in #{self.class}"
      end
    end
  end

  # Internal: Used internally to write a single object to JSON.
  #
  # writer - writer used to serialize results
  # item - item to serialize results for
  # options - list of external options to pass to the serializer (available as `options`)
  #
  # NOTE: Binds this instance to the specified object and options and writes
  # to json using the provided writer.
  def write_one(writer, item, options = nil)
    writer.push_object
    write_to_json(writer, item, options)
    writer.pop
  end

  # Internal: Used internally to write an array of objects to JSON.
  #
  # writer - writer used to serialize results
  # items - items to serialize results for
  # options - list of external options to pass to the serializer (available as `options`)
  def write_many(writer, items, options = nil)
    writer.push_array
    items.each do |item|
      write_one(writer, item, options)
    end
    writer.pop
  end

protected

  # Internal: An internal cache that can be used for temporary memoization.
  def memo
    @memo ||= OjSerializers::Memo.new
  end

  class << self
    # Public: Allows the user to specify `default_format :json`, as a simple
    # way to ensure that `.one` and `.many` work as in Version 1.
    #
    # This setting is inherited from parent classes.
    def default_format(format)
      define_singleton_method(:_default_format) { format }
      define_serialization_shortcuts
    end

    # Public: Allows to sort fields by name instead of by definition order, or
    # pass a Proc to apply a custom order.
    #
    # This setting is inherited from parent classes.
    def sort_attributes_by(strategy)
      case strategy
      when :name, :definition, Proc
        define_singleton_method(:_sort_attributes_by) { strategy }
      else
        raise ArgumentError, "Unknown sorting option: #{strategy.inspect}"
      end
    end

    # Public: Allows to transform the JSON keys to camelCase, or pass a Proc
    # to apply a custom transformation.
    #
    # This setting is inherited from parent classes.
    def transform_keys(strategy = nil, &block)
      transformer = case (strategy ||= block)
      when :camelize, :camel_case then ->(key) { key.camelize(:lower).chomp('?') }
      when :none then nil
      when Symbol then strategy.to_proc
      when Proc then strategy
      else
        raise(ArgumentError, "Expected transform_keys to be callable, got: #{strategy.inspect}")
      end
      define_singleton_method(:_transform_keys) { transformer }
    end

    # Public: Creates an alias for the internal object.
    def object_as(name, **)
      define_method(name) { @object }
    end

    # Internal: We want to discourage instantiating serializers directly, as it
    # prevents the possibility of reusing an instance.
    #
    # NOTE: `one` serves as a replacement for `new` in these serializers.
    private :new

    # Internal: Delegates to the instance methods, the advantage is that we can
    # reuse the same serializer instance to serialize different objects.
    delegate :write_one, :write_many, :write_to_json, to: :instance

    # Internal: Keep a reference to the default `write_one` method so that we
    # can use it inside cached overrides and benchmark tests.
    alias_method :non_cached_write_one, :write_one

    # Internal: Keep a reference to the default `write_many` method so that we
    # can use it inside cached overrides and benchmark tests.
    alias_method :non_cached_write_many, :write_many

    # Helper: Serializes one or more items.
    def render(item, options = nil)
      many?(item) ? many(item, options) : one(item, options)
    end

    # Helper: Serializes one or more items.
    def render_as_hash(item, options = nil)
      many?(item) ? many_as_hash(item, options) : one_as_hash(item, options)
    end

    # Helper: Serializes the item unless it's nil.
    def one_if(item, options = nil)
      one(item, options) if item
    end

    # Public: Serializes the configured attributes for the specified object.
    #
    # item - the item to serialize
    # options - list of external options to pass to the sub class (available in `item.options`)
    #
    # Returns an Oj::StringWriter instance, which is encoded as raw json.
    def one_as_json(item, options = nil)
      writer = new_json_writer
      write_one(writer, item, options)
      writer
    end

    # Public: Serializes an array of items using this serializer.
    #
    # items - Must respond to `each`.
    # options - list of external options to pass to the sub class (available in `item.options`)
    #
    # Returns an Oj::StringWriter instance, which is encoded as raw json.
    def many_as_json(items, options = nil)
      writer = new_json_writer
      write_many(writer, items, options)
      writer
    end

    # Public: Renders the configured attributes for the specified object,
    # without serializing to JSON.
    #
    # item - the item to serialize
    # options - list of external options to pass to the sub class (available in `item.options`)
    #
    # Returns a Hash, with the attributes specified in the serializer.
    def one_as_hash(item, options = nil)
      instance.render_as_hash(item, options)
    end

    # Public: Renders an array of items using this serializer, without
    # serializing to JSON.
    #
    # items - Must respond to `each`.
    # options - list of external options to pass to the sub class (available in `item.options`)
    #
    # Returns an Array of Hash, each with the attributes specified in the serializer.
    def many_as_hash(items, options = nil)
      serializer = instance
      items.map { |item| serializer.render_as_hash(item, options) }
    end

    # Internal: Will alias the object according to the name of the wrapper class.
    def inherited(subclass)
      object_alias = subclass.name.demodulize.chomp('Serializer').underscore
      subclass.object_as(object_alias) unless method_defined?(object_alias) || object_alias == 'base'
      super
    end

    # Internal: List of attributes to be serialized.
    #
    # Any attributes defined in parent classes are inherited.
    def _attributes
      @_attributes ||= superclass.try(:_attributes)&.dup || {}
    end

  protected

    # Internal: Calculates the cache_key used to cache one serialized item.
    def item_cache_key(item, cache_key_proc)
      ActiveSupport::Cache.expand_cache_key(cache_key_proc.call(item))
    end

    # Public: Allows to define a cache key strategy for the serializer.
    # Defaults to calling cache_key in the object if no key is provided.
    #
    # NOTE: Benchmark it, sometimes caching is actually SLOWER.
    def cached(cache_key_proc = :cache_key.to_proc)
      cache_options = { namespace: "#{name}#write_to_json", version: OjSerializers::VERSION }.freeze
      cache_hash_options = { namespace: "#{name}#render_as_hash", version: OjSerializers::VERSION }.freeze

      # Internal: Redefine `one_as_hash` to use the cache for the serialized hash.
      define_singleton_method(:one_as_hash) do |item, options = nil|
        CACHE.fetch(item_cache_key(item, cache_key_proc), cache_hash_options) do
          instance.render_as_hash(item, options)
        end
      end

      # Internal: Redefine `many_as_hash` to use the cache for the serialized hash.
      define_singleton_method(:many_as_hash) do |items, options = nil|
        # We define a one-off method for the class to receive the entire object
        # inside the `fetch_multi` block. Otherwise we would only get the cache
        # key, and we would need to build a Hash to retrieve the object.
        #
        # NOTE: The assignment is important, as queries would return different
        # objects when expanding with the splat in fetch_multi.
        items = items.entries.each do |item|
          item_key = item_cache_key(item, cache_key_proc)
          item.define_singleton_method(:cache_key) { item_key }
        end

        # Fetch all items at once by leveraging `read_multi`.
        #
        # NOTE: Memcached does not support `write_multi`, if we switch the cache
        # store to use Redis performance would improve a lot for this case.
        CACHE.fetch_multi(*items, cache_hash_options) do |item|
          instance.render_as_hash(item, options)
        end.values
      end

      # Internal: Redefine `write_one` to use the cache for the serialized JSON.
      define_singleton_method(:write_one) do |external_writer, item, options = nil|
        cached_item = CACHE.fetch(item_cache_key(item, cache_key_proc), cache_options) do
          writer = new_json_writer
          non_cached_write_one(writer, item, options)
          writer.to_json
        end
        external_writer.push_json("#{cached_item}\n") # Oj.dump expects a new line terminator.
      end

      # Internal: Redefine `write_many` to use fetch_multi from cache.
      define_singleton_method(:write_many) do |external_writer, items, options = nil|
        # We define a one-off method for the class to receive the entire object
        # inside the `fetch_multi` block. Otherwise we would only get the cache
        # key, and we would need to build a Hash to retrieve the object.
        #
        # NOTE: The assignment is important, as queries would return different
        # objects when expanding with the splat in fetch_multi.
        items = items.entries.each do |item|
          item_key = item_cache_key(item, cache_key_proc)
          item.define_singleton_method(:cache_key) { item_key }
        end

        # Fetch all items at once by leveraging `read_multi`.
        #
        # NOTE: Memcached does not support `write_multi`, if we switch the cache
        # store to use Redis performance would improve a lot for this case.
        cached_items = CACHE.fetch_multi(*items, cache_options) do |item|
          writer = new_json_writer
          non_cached_write_one(writer, item, options)
          writer.to_json
        end.values
        external_writer.push_json("#{OjSerializers::JsonValue.array(cached_items)}\n") # Oj.dump expects a new line terminator.
      end

      define_serialization_shortcuts
    end
    alias_method :cached_with_key, :cached

    def define_serialization_shortcuts(format = _default_format)
      case format
      when :json, :hash
        singleton_class.alias_method :one, :"one_as_#{format}"
        singleton_class.alias_method :many, :"many_as_#{format}"
      else
        raise ArgumentError, "Unknown serialization format: #{format.inspect}"
      end
    end

    # Internal: The writer to use to write to json
    def new_json_writer
      Oj::StringWriter.new(mode: :rails)
    end

    # Public: Identifiers are always serialized first.
    #
    # NOTE: We skip the id for non-persisted documents, since it doesn't
    # actually identify the document (it will change once it's persisted).
    def identifier(name = :id, **options)
      add_attribute(name, attribute: :method, if: -> { !@object.new_record? }, **options, identifier: true)
    end

    # Public: Specify a collection of objects that should be serialized using
    # the specified serializer.
    def has_many(name, serializer:, **options, &block)
      define_method(name, &block) if block
      add_attribute(name, association: :many, serializer: serializer, **options)
    end

    # Public: Specify an object that should be serialized using the serializer.
    def has_one(name, serializer:, **options, &block)
      define_method(name, &block) if block
      add_attribute(name, association: :one, serializer: serializer, **options)
    end
    # Alias: From a serializer perspective, the association type does not matter.
    alias_method :belongs_to, :has_one

    # Public: Specify an object that should be serialized using the serializer,
    # but unlike `has_one`, this one will write the attributes directly without
    # wrapping it in an object.
    def flat_one(name, serializer:, **options)
      add_attribute(name, association: :flat, serializer: serializer, **options)
    end

    # Public: Specify which attributes are going to be obtained from indexing
    # the object.
    def hash_attributes(*attr_names, **options)
      attributes(*attr_names, **options, attribute: :hash)
    end

    # Public: Specify which attributes are going to be obtained from indexing
    # a Mongoid model's `attributes` hash directly, for performance.
    #
    # Automatically renames `_id` to `id` for Mongoid models.
    #
    # See ./benchmarks/document_benchmark.rb
    def mongo_attributes(*attr_names, **options)
      identifier(:_id, as: :id, attribute: :mongoid, **options.slice(:if)) if attr_names.delete(:id)
      attributes(*attr_names, **options, attribute: :mongoid)
    end

    # Public: Specify which attributes are going to be obtained by calling a
    # method in the object.
    def attributes(*attr_names, **methods_with_options)
      attr_options = methods_with_options.extract!(:if, :as, :attribute)
      attr_options[:attribute] ||= :method

      attr_names.each do |attr_name|
        add_attribute(attr_name, **attr_options)
      end

      methods_with_options.each do |attr_name, options|
        options = { as: options } if options.is_a?(Symbol)
        options[:attribute] ||= attr_options[:attribute]
        add_attribute(attr_name, **options)
      end
    end

    # Public: Specify which attributes are going to be obtained by calling a
    # method in the serializer.
    def serializer_attributes(*attr_names, **options)
      attributes(*attr_names, **options, attribute: :serializer)
    end

    # Syntax Sugar: Allows to use it before a method name.
    #
    # Example:
    #   attribute
    #   def full_name
    #     "#{ first_name } #{ last_name }"
    #   end
    def attribute(name = nil, **options, &block)
      options[:attribute] = :serializer
      if name
        define_method(name, &block) if block
        add_attribute(name, **options)
      else
        @_current_attribute_options = options
      end
    end
    alias_method :attr, :attribute

    # Internal: Intercept a method definition, tying a type that was
    # previously specified to the name of the attribute.
    def method_added(name)
      super(name)
      if @_current_attribute_options
        add_attribute(name, **@_current_attribute_options)
        @_current_attribute_options = nil
      end
    end

    # Backwards Compatibility: Meant only to replace Active Model Serializers,
    # calling a method in the serializer, or using `read_attribute_for_serialization`.
    #
    # NOTE: Prefer to use `attributes` or `serializer_attributes` explicitly.
    def ams_attributes(*attr_names, **options)
      attr_names.each do |attr_name|
        define_method(attr_name) { @object.read_attribute_for_serialization(attr_name) } unless method_defined?(attr_name)
      end
      attributes(*attr_names, **options, attribute: :serializer)
    end

  private

    def add_attribute(value_from, root: nil, as: nil, **options)
      # Because it's so common, automatically mark id as an identifier.
      options[:identifier] = true if value_from == :id && !options.key?(:identifier)

      # Hash attributes could be numbers or symbols.
      value_from = value_from.to_s unless options[:attribute] == :hash

      # Obtain the JSON key to use for the attribute.
      key = (root || as || value_from).to_s

      # Should be able to add "duplicate" flat associations.
      key += _attributes.count.to_s if options[:association] == :flat

      # Check for typos in options.
      if DEV_MODE && (option, = options.find { |option, _value| !KNOWN_ATTRIBUTE_OPTIONS.include?(option) })
        raise ArgumentError, "Unknown option #{option.inspect} for attribute #{value_from.inspect} in #{name}. Please check for typos."
      end

      _attributes[key.freeze] = { value_from: value_from, **options }.freeze
    end

    # Internal: Whether the object should be serialized as a collection.
    def many?(item)
      item.is_a?(Array) ||
        (defined?(ActiveRecord::Relation) && item.is_a?(ActiveRecord::Relation)) ||
        (defined?(Mongoid::Association::Many) && item.is_a?(Mongoid::Association::Many))
    end

    # Internal: We generate code for the serializer to avoid the overhead of
    # using variables for method names, having to iterate the list of attributes
    # and associations, and the overhead of using `send` with dynamic methods.
    #
    # As a result, the performance is the same as writing the most efficient
    # code by hand.
    def code_to_write_to_json(attributes)
      <<~WRITE_TO_JSON
        # Public: Writes this serializer content to a provided Oj::StringWriter.
        def write_to_json(writer, item, options = nil)
          @object = item
          @options = options
          @memo.clear if defined?(@memo)
          #{ attributes.map { |key, options|
            code_to_write_conditionally(options) {
              if options[:association]
                code_to_write_association(key, options)
              else
                code_to_write_attribute(key, options)
              end
            }
          }.join("\n  ") }#{code_to_rescue_no_method if DEV_MODE}
        end
      WRITE_TO_JSON
    end

    # Internal: We generate code for the serializer to avoid the overhead of
    # using variables for method names, having to iterate the list of attributes
    # and associations, and the overhead of using `send` with dynamic methods.
    #
    # As a result, the performance is the same as writing the most efficient
    # code by hand.
    def code_to_render_as_hash(attributes)
      <<~RENDER_AS_HASH
        # Public: Writes this serializer content to a Hash.
        def render_as_hash(item, options = nil)
          @object = item
          @options = options
          @memo.clear if defined?(@memo)
          {
            #{attributes.map { |key, options|
              code_to_render_conditionally(options) {
                if options[:association]
                  code_to_render_association(key, options)
                else
                  code_to_render_attribute(key, options)
                end
              }
            }.join(",\n    ")}
          }#{code_to_rescue_no_method if DEV_MODE}
        end
      RENDER_AS_HASH
    end

    def code_to_rescue_no_method
      <<~RESCUE_NO_METHOD

        rescue NoMethodError => e
          key = e.name.to_s.inspect
          message = if respond_to?(e.name)
            raise e, "Perhaps you meant to call \#{key} in \#{self.class} instead?\nTry using `attribute :\#{key} do` or `attribute def \#{key}`.\n\#{e.message}"
          elsif @object.respond_to?(e.name)
            raise e, "Perhaps you meant to call \#{key} in \#{@object.class} instead?\nTry using `attributes :\#{key}`.\n\#{e.message}"
          else
            raise e
          end
        ensure
          _check_instance_variables
      RESCUE_NO_METHOD
    end

    # Internal: Detects any include methods defined in the serializer, or defines
    # one by using the lambda passed in the `if` option, if any.
    def check_conditional_method(options)
      value_from = options.fetch(:value_from)
      include_method_name = "include_#{value_from}#{'?' unless value_from.to_s.ends_with?('?')}"
      if render_if = options[:if]
        if render_if.is_a?(Symbol)
          alias_method(include_method_name, render_if)
        else
          define_method(include_method_name, &render_if)
        end
      end
      include_method_name if method_defined?(include_method_name)
    end

    # Internal: Returns the code to render an attribute or association
    # conditionally.
    #
    # NOTE: Detects any include methods defined in the serializer, or defines
    # one by using the lambda passed in the `if` option, if any.
    def code_to_write_conditionally(options)
      if (include_method_name = check_conditional_method(options))
        "if #{include_method_name};#{yield};end\n"
      else
        yield
      end
    end

    # Internal: Returns the code for the association method.
    def code_to_write_attribute(key, options)
      value_from = options.fetch(:value_from)

      value = case (strategy = options.fetch(:attribute))
      when :serializer
        # Obtains the value by calling a method in the serializer.
        value_from
      when :method
        # Obtains the value by calling a method in the object, and writes it.
        "@object.#{value_from}"
      when :hash
        # Writes a Hash value to JSON, works with String or Symbol keys.
        "@object[#{value_from.inspect}]"
      when :mongoid
        # Writes an Mongoid attribute to JSON, this is the fastest strategy.
        "@object.attributes['#{value_from}']"
      else
        raise ArgumentError, "Unknown attribute strategy: #{strategy.inspect}"
      end

      "writer.push_value(#{value}, #{key.inspect})"
    end

    # Internal: Returns the code for the association method.
    def code_to_write_association(key, options)
      # Use a serializer method if defined, else call the association in the object.
      value_from = options.fetch(:value_from)
      value = method_defined?(value_from) ? value_from : "@object.#{value_from}"
      serializer_class = options.fetch(:serializer)

      case type = options.fetch(:association)
      when :one
        <<~WRITE_ONE
          if __value = #{value}
            writer.push_key('#{key}')
            #{serializer_class}.write_one(writer, __value)
          end
        WRITE_ONE
      when :many
        <<~WRITE_MANY
          writer.push_key('#{key}')
          #{serializer_class}.write_many(writer, #{value})
        WRITE_MANY
      when :flat
        <<~WRITE_FLAT
          #{serializer_class}.write_to_json(writer, #{value})
        WRITE_FLAT
      else
        raise ArgumentError, "Unknown association type: #{type.inspect}"
      end
    end

    # Internal: Returns the code to render an attribute or association
    # conditionally.
    #
    # NOTE: Detects any include methods defined in the serializer, or defines
    # one by using the lambda passed in the `if` option, if any.
    def code_to_render_conditionally(options)
      if (include_method_name = check_conditional_method(options))
        "**(#{include_method_name} ? {#{yield}} : {})"
      else
        yield
      end
    end

    # Internal: Returns the code for the attribute method.
    def code_to_render_attribute(key, options)
      value_from = options.fetch(:value_from)

      value = case (strategy = options.fetch(:attribute))
      when :serializer
        value_from
      when :method
        "@object.#{value_from}"
      when :hash
        "@object[#{value_from.inspect}]"
      when :mongoid
        "@object.attributes['#{value_from}']"
      else
        raise ArgumentError, "Unknown attribute strategy: #{strategy.inspect}"
      end

      "#{key}: #{value}"
    end

    # Internal: Returns the code for the association method.
    def code_to_render_association(key, options)
      # Use a serializer method if defined, else call the association in the object.
      value_from = options.fetch(:value_from)
      value = method_defined?(value_from) ? value_from : "@object.#{value_from}"
      serializer_class = options.fetch(:serializer)

      case type = options.fetch(:association)
      when :one
        "#{key}: (__value = #{value}) ? #{serializer_class}.one_as_hash(__value) : nil"
      when :many
        "#{key}: #{serializer_class}.many_as_hash(#{value})"
      when :flat
        "**#{serializer_class}.one_as_hash(#{value})"
      else
        raise ArgumentError, "Unknown association type: #{type.inspect}"
      end
    end

    # Internal: Allows to obtain a pre-existing instance and binds it to the
    # specified object.
    #
    # NOTE: Each class is only instantiated once to reduce object allocation.
    # For that reason, serializers must be completely stateless (or use global
    # state).
    def instance
      Thread.current[instance_key] ||= new
    end

    # Internal: Cache key to set a thread-local instance.
    def instance_key
      @instance_key ||= begin
        # We take advantage of the fact that this method will always be called
        # before instantiating a serializer, to apply last minute adjustments.
        prepare_serializer
        "#{name.underscore}_instance_#{object_id}".to_sym
      end
    end

    # Internal: Generates write_to_json and render_as_hash methods optimized for
    # the specified configuration.
    def prepare_serializer
      attributes = prepare_attributes
      class_eval(code_to_write_to_json(attributes))
      class_eval(code_to_render_as_hash(attributes))
    end

    # Internal: Returns attributes sorted and with keys transformed using
    # the specified strategies.
    def prepare_attributes(transform_keys: try(:_transform_keys), sort_by: try(:_sort_attributes_by))
      attributes = _attributes
      attributes = attributes.transform_keys(&transform_keys) if transform_keys

      if sort_by == :name
        sort_by = ->(name, options, _) { options[:identifier] ? "__#{name}" : name }
      elsif !sort_by || sort_by == :definition
        sort_by = ->(name, options, index) {
          if options[:identifier]
            0 - (_attributes.count - index)
          else
            index
          end
        }
      end

      attributes.sort_by.with_index { |(name, options), index| sort_by.call(name, options, index) }.to_h
    end
  end

  default_format :hash
end

Oj::Serializer = OjSerializers::Serializer unless defined?(Oj::Serializer)
