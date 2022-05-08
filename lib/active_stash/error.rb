module ActiveStash
  class ActiveStashError < StandardError; end

  class ConfigError < ActiveStashError; end

  class QueryError < ActiveStashError; end

  # Raised when no collection exists
  class CollectionError < ActiveStashError
    def initialize(message = nil, name: nil)
      if name && !message
        message = default_message(name)
      end

      super(message)
    end

    def default_message(name)
      "An error occurred that relates to the '#{name}' collection"
    end
  end

  class NoCollectionError < CollectionError
    def default_message(name)
      <<-STR
      The collection '#{name}' does not exist.
      You probably need to create it via rake active_stash:collections:create
      STR
    end
  end

  class CollectionExistsError < CollectionError
    def default_message(name)
      "The collection '#{name}' already exists"
    end
  end

  class CollectionDivergedError < CollectionError
    def default_message(name)
      <<-STR
      The '#{name}' collection has diverged. Its settings are no longer reflected on the server.
      You probably want to recreate it and reindex your data.
      STR
    end
  end

  class NoMatchAllError < CollectionError
    def default_message(name)
      <<-STR
      There is no `stash_match_all` index defined for the '#{name}' collection.
      Queries of the form "Model.query(str)" require this to work.
      STR
    end
  end
end
