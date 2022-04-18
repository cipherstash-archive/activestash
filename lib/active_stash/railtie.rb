module ActiveStash
  class Railtie < Rails::Railtie
    generators do
      require "active_stash/generators/schema_generator"
    end

    rake_tasks do
      load "tasks/active_stash.rake"
    end
  end
end
