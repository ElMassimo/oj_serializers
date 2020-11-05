# frozen_string_literal: true

# Internal: Allows to obtain a pre-existing instance and binds it to the
# specified object.
#
# NOTE: Each class is only instantiated once to reduce object allocation.
# For that reason, serializers must be completely stateless (or use global
# state).
module OjSerializers::InstanceCache
  if defined?(ActiveSupport::CurrentAttributes)
    class Current < ActiveSupport::CurrentAttributes
      attribute :instances
    end

    def self.fetch(instance_key)
      Current.instances ||= {}
      Current.instances.fetch(instance_key) { yield }
    end
  elsif defined?(RequestStore)
    def self.fetch(instance_key)
      RequestStore.fetch(instance_key) { yield }
    end
  elsif defined?(RequestLocals)
    def self.fetch(instance_key)
      RequestLocals.fetch(instance_key) { yield }
    end
  else
    warn 'To ensure reliable reuse of serializer instances, make sure request_store or request_store_rails are available, or that the app is running Rails >= 5.2.0'
    def self.fetch(instance_key)
      Thread.current[instance_key] ||= yield
    end
  end
end
