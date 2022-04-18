module ActiveStash
  class Railtie < Rails::Railtie
    generators do
      require "active_stash/generators/schema_generator"
    end
  end
end
