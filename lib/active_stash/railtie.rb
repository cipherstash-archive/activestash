require 'rails'

module ActiveStash
  class Railtie < Rails::Railtie
    config.active_stash = ActiveSupport::OrderedOptions.new

    initializer "active_stash.configure" do |app|
      # When running specs there will be no "app" passed into the block.  That's
      # OK because we're not using this configuration method in the specs.
      if app
        ActiveStash.configure do |config|
          app.config.active_stash.each { |key, value| config.public_send("#{key}=", value) }

          if active_stash_credentials = app.credentials.active_stash
            active_stash_credentials.each { |key, value| config.public_send("#{key}=", value) }
          end
        end
      end

      case Rails::VERSION::MAJOR
      when 6
        ActiveSupport.on_load(:active_record) do
          require 'active_stash/backports/rails6'
          ActiveStash::Backports::Rails6.install
        end
      when 0..5
        STDERR.puts "ActiveStash only supports Rails versions >= 6"
        exit 1
      end
    end

    rake_tasks do
      path = File.expand_path(File.join(__dir__, "../tasks/active_stash.rake"))
      load path
    end
  end

end
