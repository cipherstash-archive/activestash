require "bundler/setup"
require "active_record"
require "active_stash"
require "active_stash/railtie"
require "factory_bot"
require "faker"

require_relative "./support/user"
require_relative "./support/user2"
require_relative "./support/patient"
require_relative "./support/consultation"
require_relative "./support/migrations/create_users"
require_relative "./support/migrations/create_users2"
require_relative "./support/migrations/create_patients"
require_relative "./support/migrations/create_consultations"
require_relative "./support/migrations/create_medicare_cards"

ActiveStash::Railtie.initializers.each(&:run)

MIGRATIONS = [CreateUsers, CreateUsers2, CreatePatients, CreateConsultations, CreateMedicareCards]

def migrate(direction)
  MIGRATIONS.each { |migration| migration.migrate(direction) }
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.full_backtrace = ENV.key?("RSPEC_FULL_BACKTRACE")

  config.before(:suite) do
    FactoryBot.find_definitions

    ActiveRecord::Base.establish_connection(
      adapter: 'postgresql',
      host: 'localhost',
      username: ENV["PGUSER"] || nil,
      password: ENV["PGPASSWORD"] || nil,
      database: ENV["PGDATABASE"] || 'activestash_test'
    )

    migrate(:up)
  end

  config.after(:suite) do
    migrate(:down)
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
