require "bundler/setup"
require 'rspec/expectations'
require "active_record"
require "active_stash"
require "active_stash/railtie"
require "factory_bot"

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  host: 'localhost',
  username: ENV["PGUSER"] || nil,
  password: ENV["PGPASSWORD"] || nil,
  database: ENV["PGDATABASE"] || 'activestash_test'
)

Dir["./spec/support/migrations/*.rb"].each {|file| require  file }

ActiveStash::Railtie.initializers.each(&:run)

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.full_backtrace = ENV.key?("RSPEC_FULL_BACKTRACE")

  config.before(:suite) do
    FactoryBot.find_definitions

    # [
    #   CreateUsers,
    #   CreateUsers2,
    #   CreateUsers3,
    #   CreateUsers4,
    #   CreateUsers5,
    #   CreateUsers6,
    # ].each{|m| m.migrate(:up)}

    ActiveRecord::Migration.descendants.each{|m| m.migrate(:up)}

    require './spec/support/user' # This one must be loaded first
    Dir["./spec/support/*.rb"].each {|file| require file }
  end

  config.after(:suite) do
    # [
    #   CreateUsers6,
    #   CreateUsers5,
    #   CreateUsers4,
    #   CreateUsers3,
    #   CreateUsers2,
    #   CreateUsers,
    # ].each{|m| m.migrate(:down)}
    ActiveRecord::Migration.descendants.each{|m| m.migrate(:down)}
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end


RSpec::Matchers.define :have_an_exact_index do |name|
  match do |actual|
    target = actual.find { |i| i.type == :exact }
    !target.nil? && target.name == name
  end
end

RSpec::Matchers.define :have_an_exact_unique_index do |name|
  match do |actual|
    target = actual.find { |i| i.type == :exact}
    !target.nil? && target.name == name && target.unique == true
  end
end


RSpec::Matchers.define :have_a_range_index do |name|
  match do |actual|
    target = actual.find { |i| i.type == :range }
    !target.nil? && target.name == name
  end
end

RSpec::Matchers.define :have_a_range_unique_index do |name|
  match do |actual|
    target = actual.find { |i| i.type == :range }
    !target.nil? && target.name == name  && target.unique == true
  end
end

RSpec::Matchers.define :have_a_match_index do |name|
  match do |actual|
    target = actual.find { |i| i.type == :match }
    !target.nil? && target.name == name
  end
end
