require "cipherstash/client"
require "active_stash"
require "terminal-table"
require "launchy"

def stash_enabled_models
  Dir.glob("#{Rails.root}/app/models/*.rb").each { |file| Module.const_get("::" + File.basename(file, ".rb").camelize) }
  ActiveRecord::Base.descendants.select do |m|
    if m.respond_to?(:is_stash_model?) && block_given?
      yield m
    end
  end
end

def info(message)
  puts "\e[36m\e[1m#{message}\e[22m\e[0m"
end

def error(message)
  ActiveStash::Logger.error(message)
  STDERR.puts("\e[31m\e[1m#{message}\e[0m")
end

namespace :active_stash do
  desc "assess what data is sensitive"
  task(:assess => :environment) do
    ActiveStash::Assess.new.run
  end

  desc "Signup"
  task(:signup => :environment) do
    redirect_url = "https://cipherstash.com/signup/rake"
    info("")
    info("")
    info("")
    info("")
    info("")
    info("You are being redirected to #{redirect_url} to complete your signup.")
    info("")
    info("")
    info("NEXT STEPS:")
    info("")
    info("1. Sign up with your GitHub account or email.")
    info("")
    info("")
    info("2. Grab your workspace ID from the signup confirmation page")
    info("")
    info("")
    info("3. Log in using this Rake command with your workspace ID: rake active_stash:login[<your workspace id>]")
    info("")
    info("")
    info("")
    info("")
    info("")
    info("")
    Launchy.open(redirect_url)
    info("")
    info("")
    info("")
  end

  desc "Login to stash workspace"
  task :login, [:workspace] do |task, args|
    if args[:workspace].nil?
        error("Please provide a workspace ID.")
        info("")
        info("Using bash:")
        info("")
        info("rake active_stash:login[YOURWORKSPACEID]")
        info("")
        info("Using zsh:")
        info("")
        info("rake active_stash:login\\[YOURWORKSPACEID\\]")
        info("")
        info("")
        exit 1
    end
    CipherStash::Client::Profile.create(ENV.fetch("CS_PROFILE_NAME", "default"), ActiveStash::Logger.instance, workspace: args[:workspace])
  rescue CipherStash::Client::Error::CreateProfileFailure => ex
    error(ex.message)
  rescue CipherStash::Client::Error::LoadProfileFailure => ex
    error(ex.message)
  end

  desc "Reindex the CipherStash collection for the given model"
  task(:reindex, [:name] => :environment) do |task, args|
    model = args[:name].constantize
    info("Reindexing model: '#{args[:name]}' (collection: '#{model.collection_name}')")
    model.reindex
  end

  desc "Reindex all CipherStash collections (this may take some time!)"
  task(:reindexall => :environment) do
    stash_enabled_models do |model|
      info("Reindexing #{model.collection_name}...")
      model.reindex
    end
  end

  namespace :access_key do
    desc "Create a new access key"
    task :create, [:name] => :environment do |_task, args|
      if args[:name].nil?
        error("Must provide a key name")
        exit 1
      end
      puts CipherStash::Client.new(logger: ActiveStash::Logger.instance).create_access_key(args[:name]).secret_key
    end

    desc "List existing access keys"
    task :list => :environment do
      keys = CipherStash::Client.new(logger: ActiveStash::Logger.instance).access_keys.map { |k| [k.name, k.id, k.created_at, k.last_used_at] }
      puts Terminal::Table.new headings: ["Key Name", "Key ID", "Created At", "Last Used At"], rows: keys
    end

    desc "Delete an access key"
    task :delete, [:name] => :environment do |_task, args|
      if args[:name].nil?
        error("Must provide a key name")
        exit 1
      end
      CipherStash::Client.new(logger: ActiveStash::Logger.instance).delete_access_key(args[:name])
      puts "Key '#{args[:name]}' deleted"
    end
  end

  namespace :collections do
    desc "Describe the CipherStash collection attached to the given model"
    task :describe, [:name] => :environment do |task, args|
      model = args[:name].constantize
      table = Terminal::Table.new(headings: ["Name", "Type", "Field(s)", "Valid Operators"]) do |t|
        model.stash_indexes.all.each do |index|
          t << [index.name, index.type, Array(index.field).join(", "), index.valid_ops.join(", ")]
        end
      end

      puts table
    rescue GRPC::NotFound
      error("No such collection")
    end

    desc "Creates CipherStash indexes for all Stash enabled models"
    task :create => :environment do
      stash_enabled_models do |model|
        begin
          model.collection.create!
          info("Created collection `#{model.collection_name}`")
        rescue ActiveStash::CollectionExistsError
          error("Collection '#{model.collection_name}' already exists (skipping)")
        end
      end
    end

    desc "Drop the collection attached to the given model"
    task :drop, [:name] => :environment do |task, args|
      model = args[:name].constantize
      if model.respond_to?(:is_stash_model?) && model.is_stash_model?
        model.collection.drop!
      end
      info("Dropped collection '#{model.collection_name}' which was attached to `#{args[:name]}`")
    rescue ActiveStash::NoCollectionError
      error("No such collection '#{model.collection_name}'")
    end

    desc "List all stash enabled models and their CipherStash collections"
    task :list => :environment do
      table = Terminal::Table.new(headings: ["Model", "Collection"]) do |t|
        stash_enabled_models do |model|
          t << [model.name, model.collection_name]
        end
      end

      puts table
    end
  end
end
