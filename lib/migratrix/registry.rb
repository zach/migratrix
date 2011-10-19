module Migratrix
  # Basically a place to story our factories
  class Registry
    def register(name, klass, init_options)
      registry[name] = [klass, init_options]
    end

    def class_for(name)
      registry.fetch(name).first
    end

    def options_for(name)
      registry.fetch(name).second
    end

    def registered?(name)
      registry.key?(name)
    end

    def registry
      @registry ||= {}
    end
  end
end