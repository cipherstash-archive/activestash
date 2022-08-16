require "bundler/setup"
require "active_record"
require "active_stash"
require "active_stash/railtie"
require "factory_bot"

require_relative "./support/migrations/create_users"
require_relative "./support/migrations/create_employees"
require_relative "./support/migrations/create_managers"

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

    CreateManagers.migrate(:down) rescue nil
    CreateEmployees.migrate(:down) rescue nil
    CreateUsers.migrate(:down) rescue nil
    CreateUsers.migrate(:up)
    CreateEmployees.migrate(:up)
    CreateManagers.migrate(:up)

    Employee.collection.drop! rescue nil
    User.collection.drop! rescue nil
    User.collection.create!
    Employee.collection.create!
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.fail_fast = !!ENV["RSPEC_CONFIG_FAIL_FAST"]

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
