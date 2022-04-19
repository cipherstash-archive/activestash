require 'open3'

def stash(cmd)
  Open3.popen3("stash #{cmd}") do |stdin, stdout, stderr|
    puts stdout.read
  end 
end

namespace :active_stash do
  desc "List stash collections"
  task :login, [:workspace] do |task, args|
    stash("login --workspace #{args[:workspace]}")
  end 

  desc "List all collections"
  task :"list-collections" do
    stash("list-collections")
  end

  desc "Describe collection"
  task :"describe-collection", [:name] do |task, args|
    stash("describe-collection #{args[:name]}")
  end

  desc "Creates any collections with schemas defined in db/stash"
  task :"create-collections" do
    # TODO: Make the schema dir configurable
    Dir["db/stash/**"].each do |schema|
      collection_name = File.basename(Dir[schema].first, ".json")
      puts "Creating collection '#{collection_name}' from schema: #{schema}"
      stash("create-collection #{collection_name} --schema #{schema}")
    end
  end 

  desc "Reindex the CipherStash collection for the given model"
  task(:reindex, [:name] => :environment) do |task, args|
    model = args[:name].constantize
    model.reindex
  end

  desc "Reindex all CipherStash collections (this may take some time!)"
  task(:reindexall => :environment) do
    Dir.glob("#{Rails.root}/app/models/*.rb").each { |file| require file }
    p ActiveRecord::Base.descendants
    ActiveRecord::Base.descendants.select { |m|
      m.respond_to?(:is_stash_model?)
    }.each do |model|
      ActiveStash::Logger.info("Reindexing #{model.collection_name}...")
      model.reindex
    end
  end
end

