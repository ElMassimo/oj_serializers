# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/string/inflections'

require 'oj'

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
  ALLOWED_INSTANCE_VARIABLES = %w[memo object].freeze

  CACHE = if defined?(Rails)
    Rails.cache
  else
    defined?(ActiveSupport::Cache::MemoryStore) ? ActiveSupport::Cache::MemoryStore.new : {}
  end

  # Internal: The environment the app is currently running on.
  environment = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'production'

  # Internal: Used to display warnings or detect misusage during development.
  DEV_MODE = %w[test development].include?(environment) && !ENV['BENCHMARK']

  DEFAULT_OPTIONS = {}.freeze

  # Backwards Compatibility: Allows to access options passed through `render json`,
  # in the same way than ActiveModel::Serializers.
  def options
    @object.try(:options) || DEFAULT_OPTIONS
  end

  # Internal: Used internally to write attributes and associations to JSON.
  #
  # NOTE: Binds this instance to the specified object and options and writes
  # to json using the provided writer.
  def write_flat(writer, item)
    @memo.clear if defined?(@memo)
    @object = item
    write_to_json(writer)
  end

  # NOTE: Helps developers to remember to keep serializers stateless.
  if DEV_MODE
    prepend(Module.new do
      def write_flat(writer, item)
        if instance_values.keys.any? { |key| !ALLOWED_INSTANCE_VARIABLES.include?(key) }
          bad_keys = instance_values.keys.reject { |key| ALLOWED_INSTANCE_VARIABLES.include?(key) }
          raise ArgumentError, "Serializer instances are reused so they must be stateless. Use `memo.fetch` for memoization purposes instead. Bad keys: #{bad_keys.join(',')}"
        end
        super
      end
    end)
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
    item.define_singleton_method(:options) { options } if options
    writer.push_object
    write_flat(writer, item)
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
    defined?(@memo) ? @memo : @memo = {}
  end

private

  # Strategy: Writes an _id value to JSON using `id` as the key instead.
  # NOTE: We skip the id for non-persisted documents, since it doesn't actually
  # identify the document (it will change once it's persisted).
  def write_value_using_id_strategy(writer, _key)
    writer.push_value(@object.attributes['_id'], 'id') unless @object.new_record?
  end

  # Strategy: Writes an ActiveRecord or Mongoid attribute to JSON, this is the
  # fastest strategy.
  def write_value_using_attributes_strategy(writer, key)
    writer.push_value(@object.attributes[key], key)
  end

  # Override to detect missing attribute errors locally.
  if DEV_MODE
    alias original_write_value_using_attributes_strategy write_value_using_attributes_strategy
    def write_value_using_attributes_strategy(writer, key)
      original_write_value_using_attributes_strategy(writer, key).tap do
        # Apply a fake selection when 'only' is not used, so that we allow
        # read_attribute to fail on typos, renamed, and removed fields.
        @object.__selected_fields = @object.fields.merge(@object.relations.select { |_key, value| value.embedded? }).transform_values { 1 } if defined?(Mongoid) && !@object.__selected_fields
        @object.read_attribute(key) # Raise a missing attribute exception if it's missing.
      end
    rescue StandardError => e
      raise ActiveModel::MissingAttributeError, "#{e.message} in #{self.class} for #{@object.inspect}"
    end
  end

  # Strategy: Writes a Hash value to JSON, works with String or Symbol keys.
  def write_value_using_hash_strategy(writer, key)
    writer.push_value(@object[key], key.to_s)
  end

  # Strategy: Obtains the value by calling a method in the object, and writes it.
  def write_value_using_method_strategy(writer, key)
    writer.push_value(@object.send(key), key)
  end

  # Strategy: Obtains the value by calling a method in the serializer.
  def write_value_using_serializer_strategy(writer, key)
    writer.push_value(send(key), key)
  end

  class << self
    # Internal: We want to discourage instantiating serializers directly, as it
    # prevents the possibility of reusing an instance.
    #
    # NOTE: `one` serves as a replacement for `new` in these serializers.
    private :new

    # Internal: Delegates to the instance methods, the advantage is that we can
    # reuse the same serializer instance to serialize different objects.
    delegate :write_one, :write_many, :write_flat, to: :instance

    # Internal: Keep a reference to the default `write_one` method so that we
    # can use it inside cached overrides and benchmark tests.
    alias non_cached_write_one write_one

    # Internal: Keep a reference to the default `write_many` method so that we
    # can use it inside cached overrides and benchmark tests.
    alias non_cached_write_many write_many

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
    def one(item, options = nil)
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
    def many(items, options = nil)
      writer = new_json_writer
      write_many(writer, items, options)
      writer
    end

    # Public: Creates an alias for the internal object.
    def object_as(name)
      define_method(name) { @object }
    end

    # Internal: Will alias the object according to the name of the wrapper class.
    def inherited(subclass)
      object_alias = subclass.name.demodulize.chomp('Serializer').underscore
      subclass.object_as(object_alias) unless method_defined?(object_alias)
      super
    end

    # Internal: List of attributes to be serialized.
    #
    # Any attributes defined in parent classes are inherited.
    def _attributes
      @_attributes = superclass.try(:_attributes)&.dup || {} unless defined?(@_attributes)
      @_attributes
    end

    # Internal: List of associations to be serialized.
    # Any associations defined in parent classes are inherited.
    def _associations
      @_associations = superclass.try(:_associations)&.dup || {} unless defined?(@_associations)
      @_associations
    end

    # Internal: Iterating arrays is faster than iterating hashes.
    attr_reader :_attributes_entries, :_associations_entries

  protected

    # Internal: Calculates the cache_key used to cache one serialized item.
    def item_cache_key(item, cache_key_proc, options)
      cache_key_proc.parameters.count == 1 ? cache_key_proc.call(item) : cache_key_proc.call(item, options || item.try(:options) || {})
    end

    # Public: Allows to define a cache key strategy for the serializer.
    # Defaults to calling cache_key in the object if no key is provided.
    #
    # NOTE: Benchmark it, sometimes caching is actually SLOWER.
    def cached(cache_key_proc = :cache_key.to_proc)
      cache_options = { namespace: "#{name}#write_to_json" }.freeze

      # Internal: Redefine `write_one` to use the cache for the serialized JSON.
      define_singleton_method(:write_one) do |external_writer, item, options = nil|
        cached_item = CACHE.fetch(item_cache_key(item, cache_key_proc, options), cache_options) do
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
          item_key = item_cache_key(item, cache_key_proc, options)
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
        external_writer.push_json("#{JsonValue.array(cached_items)}\n") # Oj.dump expects a new line terminator.
      end
    end
    alias cached_with_key cached

    # Internal: The writer to use to write to json
    def new_json_writer
      Oj::StringWriter.new(mode: :rails)
    end

    # Public: Specify a collection of objects that should be serialized using
    # the specified serializer.
    def has_many(name, root: name, serializer:, **options)
      add_association(name, write_method: :write_many, root: root, serializer: serializer, **options)
    end

    # Public: Specify an object that should be serialized using the serializer.
    def has_one(name, root: name, serializer:, **options)
      add_association(name, write_method: :write_one, root: root, serializer: serializer, **options)
    end

    # Public: Specify an object that should be serialized using the serializer,
    # but unlike `has_one`, this one will write the attributes directly without
    # wrapping it in an object.
    def flat_one(name, root: false, serializer:, **options)
      add_association(name, write_method: :write_flat, root: root, serializer: serializer, **options)
    end

    # Public: Specify which attributes are going to be obtained from indexing
    # the object.
    def hash_attributes(*method_names, **options)
      options = { **options, strategy: :write_value_using_hash_strategy }
      method_names.each { |name| _attributes[name] = options }
    end

    # Public: Specify which attributes are going to be obtained from indexing
    # a model's `attributes` hash directly, for performance.
    #
    # See ./benchmarks/document_benchmark.rb
    def record_attributes(*method_names, **options)
      add_attributes(method_names, **options, strategy: :write_value_using_attributes_strategy)
    end

    # Public: Specify which attributes are going to be obtained from indexing
    # a mongoid model's `attributes` hash directly, for performance.
    #
    # Automatically renames `_id` to `id` for Mongoid models.
    #
    # See ./benchmarks/document_benchmark.rb
    def mongo_attributes(*method_names, **options)
      add_attribute('id', **options, strategy: :write_value_using_id_strategy) if method_names.delete(:id)
      record_attributes(*method_names, **options)
    end

    # Public: Specify which attributes are going to be obtained by calling a
    # method in the object.
    #
    # NOTE: Use `record_attributes` instead when possible, as it performs better.
    def object_attributes(*method_names, **options)
      add_attributes(method_names, **options, strategy: :write_value_using_method_strategy)
    end

    # Public: Specify which attributes are going to be obtained by calling a
    # method in the serializer.
    #
    # NOTE: This can be one of the slowest strategies, when in doubt, measure.
    def serializer_attributes(*method_names, **options)
      add_attributes(method_names, **options, strategy: :write_value_using_serializer_strategy)
    end

    # Syntax Sugar: Allows to use it before a method name.
    #
    # Example:
    #   attribute \
    #   def full_name
    #     "#{ first_name } #{ last_name }"
    #   end
    alias attribute serializer_attributes

    # Backwards Compatibility: Meant only to replace Active Model Serializers,
    # calling a method in the serializer, or using `read_attribute_for_serialization`.
    #
    # NOTE: Prefer to use `record_attributes`, `object_attributes`, or
    # `serializer_attributes` explicitly.
    def ams_attributes(*method_names, **options)
      method_names.each do |method_name|
        define_method(method_name) { @object.read_attribute_for_serialization(method_name) } unless method_defined?(method_name)
      end
      add_attributes(method_names, **options, strategy: :write_value_using_serializer_strategy)
    end

  private

    def add_attributes(names, options)
      names.each { |name| add_attribute(name, options) }
    end

    def add_attribute(name, options)
      _attributes[name.to_s.freeze] = options
    end

    def add_association(name, options)
      _associations[name.to_s.freeze] = options
    end

    # Internal: We generate code for the serializer to avoid the overhead of
    # using variables for method names, having to iterate the list of attributes
    # and associations, and the overhead of using `send` with dynamic methods.
    #
    # As a result, the performance is the same as writing the most efficient
    # code by hand.
    def write_to_json_body
      <<~WRITE_TO_JSON
          # Public: Writes this serializer content to a provided Oj::StringWriter.
          def write_to_json(writer)
        #{ _attributes.map do |method_name, attribute_options|
          include_method_name = "include_#{method_name}?"
          if render_if = attribute_options[:if]
            define_method(include_method_name, &render_if)
          end
          <<-WRITE_ATTRIBUTE
            #{attribute_options.fetch(:strategy)}(writer, #{method_name.inspect})#{" if #{include_method_name}" if method_defined?(include_method_name)}
          WRITE_ATTRIBUTE
        end.join }
        #{ _associations.map do |method_name, association_options|
          include_method_name = "include_#{method_name}?"
          if render_if = association_options[:if]
            define_method(include_method_name, &render_if)
          end

          # NOTE: Use a serializer method if defined, else call the association in the object.
          association_method = method_defined?(method_name) ? method_name : "@object.#{method_name}"
          association_root = association_options[:root]
          serializer_class = association_options.fetch(:serializer)

          write_association_body = case write_method = association_options.fetch(:write_method)
          when :write_one
            <<-WRITE_ONE
            if associated_object = #{association_method}
              writer.push_key(#{association_root.to_s.inspect})
              #{serializer_class}.write_one(writer, associated_object)
            end
            WRITE_ONE
          when :write_many
            <<-WRITE_MANY
            writer.push_key(#{association_root.to_s.inspect})
            #{serializer_class}.write_many(writer, #{association_method})
            WRITE_MANY
          when :write_flat
            <<-WRITE_FLAT
            #{serializer_class}.write_flat(writer, #{association_method})
            WRITE_FLAT
          else
            raise ArgumentError, "Unknown write_method #{write_method}"
          end

          if method_defined?(include_method_name)
            "if #{include_method_name};#{write_association_body};end\n"
          else
            write_association_body
          end
        end.join }  end
      WRITE_TO_JSON
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
      unless defined?(@instance_key)
        @instance_key = "#{name.underscore}_instance".to_sym
        # We take advantage of the fact that this method will always be called
        # before instantiating a serializer to define the write_to_json method.
        class_eval(write_to_json_body)
        raise ArgumentError, "You must use `cached ->(object) { ... }` in order to specify a different cache key when subclassing #{name}." if method_defined?(:cache_key) || respond_to?(:cache_key)
      end
      @instance_key
    end
  end
end

Oj::Serializer = OjSerializers::Serializer unless defined?(Oj::Serializer)
