module ActiveStash
  class Railtie < Rails::Railtie
    config.active_stash = ActiveSupport::OrderedOptions.new

    initializer "active_stash.configure" do |app|
      ActiveStash.configure do |config|
        app.config.active_stash.each { |key, value| config.public_send("#{key}=", value) }

        if active_stash_credentials = app.credentials.active_stash
          active_stash_credentials.each { |key, value| config.public_send("#{key}=", value) }
        end
      end
    end

    rake_tasks do
      load "tasks/active_stash.rake"
    end
  end
end
