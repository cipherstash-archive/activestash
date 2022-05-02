require 'open3'

def stash(cmd)
  Open3.popen3("stash #{cmd}") do |stdin, stdout, stderr|
    puts stdout.read
  end 
end

def stash_enabled_models
  Dir.glob("#{Rails.root}/app/models/*.rb").each { |file| require file }
  ActiveRecord::Base.descendants.select do |m|
    if m.respond_to?(:is_stash_model?) && block_given?
      yield m
    end
  end
end

def info(message)
  ActiveStash::Logger.info(message)
  puts "\e[36m\e[1m#{message}\e[22m\e[0m"
end

def error(message)
  ActiveStash::Logger.error(message)
  STDERR.puts("\e[31m\e[1m#{message}\e[0m")
end

namespace :active_stash do
  desc "Login to stash workspace"
  task :login, [:workspace] do |task, args|
    stash("login --workspace #{args[:workspace]}")
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

  namespace :collections do
    desc "Describe collection"
    task :describe, [:name] => :environment do |task, args|
      client = CipherStash::Client.new(logger: ActiveStash::Logger.instance)
      collection = client.collection(args[:name])
      meta = collection.instance_variable_get("@metadata")
      indexes = collection.instance_variable_get("@indexes")

      puts "-" * 54
      puts ["field".center(20), "type".center(15), "indexes".center(20)].join("|")
      puts "-" * 54
      meta["recordType"].each do |(field, type)|
        index_types = indexes.select { |index|
          mapping = index.instance_variable_get("@settings")["mapping"]
          mapping["field"] == field || (mapping["fields"] || []).include?(field)
        }.map { |index|
          index.instance_variable_get("@settings")["mapping"]["kind"]
        }.join(", ")

        puts [ " " + field.ljust(19), type.ljust(14), index_types].join("| ")
      end

      # Dynamic Indexes
      indexes.select do |index|
        mapping = index.instance_variable_get("@settings")["mapping"]
        if mapping["kind"] == "dynamic-match"
          puts [ " *".ljust(20), "dynamic-match".ljust(14), "all" ].join("| ") # TODO: actual index name
        end
      end

      puts "-" * 54
    rescue GRPC::NotFound
      error("No such collection")
    end

    desc "Creates CipherStash indexes for all Stash enabled models"
    task :create => :environment do
      stash_enabled_models do |model|
        info("Creating #{model.collection_name}...")

        schema = ActiveStash::SchemaBuilder.new(model).build
        client = CipherStash::Client.new(logger: ActiveStash::Logger.instance)
        begin
          client.create_collection(model.collection_name, schema)
          info("Successfully created '#{model.collection_name}'")
        rescue GRPC::AlreadyExists
          error("Collection '#{model.collection_name}' already exists (skipping)")
        end
      end
    end 

    desc "Drop the given collection"
    task :drop, [:name] => :environment do |task, args|
      client = CipherStash::Client.new(logger: ActiveStash::Logger.instance)
      client.collection(args[:name]).drop
      info("Successfully dropped '#{args[:name]}'")
    rescue GRPC::NotFound
      error("No such collection '#{args[:name]}'")
    end

    desc "List all collections"
    task :list => :environment do
      client = CipherStash::Client.new(logger: ActiveStash::Logger.instance)
      collections = client.collections
      puts "\nCollections"
      puts "-" * 20
      collections.each do |collection|
        puts " - #{collection.name}"
      end
      puts "-" * 20
      puts "#{collections.size} collection#{'s' if collections.size != 1} in workspace"
      puts
    end
  end
end

