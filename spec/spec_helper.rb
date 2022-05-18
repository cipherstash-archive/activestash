require "bundler/setup"
require "active_record"
require "active_stash"
require "active_stash/railtie"
require "factory_bot"

ActiveStash::Railtie.initializers.each(&:run)

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.full_backtrace = ENV.key?("RSPEC_FULL_BACKTRACE")

  config.before(:suite) do
    ActiveRecord::Base.establish_connection(
      adapter: 'postgresql',
      host: 'localhost',
      username: ENV["PGUSER"] || nil,
      password: ENV["PGPASSWORD"] || nil,
      database: ENV["PGDATABASE"] || 'activestash_test'
    )

    CreateUsers.migrate(:up)
  end

  config.after(:suite) do
    CreateUsers.migrate(:down)
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
