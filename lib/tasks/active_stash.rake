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
end

