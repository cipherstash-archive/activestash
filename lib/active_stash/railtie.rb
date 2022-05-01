module ActiveStash
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/active_stash.rake"
    end
  end
end
