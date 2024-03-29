require 'forwardable'

module ActiveStash
  class CollectionProxy
    extend Forwardable
    def_delegators :collection, :query, :upsert, :delete, :streaming_upsert
    def_delegators :@model, :collection_name, :cipherstash_metrics, :stash_indexes

    def initialize(model)
      @model = model
    end

    def schema
      SchemaBuilder.new(@model).build
    end

    def create!
      client.create_collection(collection_name, schema)
      logger.info("Successfully created '#{collection_name}'")
      true
    rescue CipherStash::Client::Error::CollectionCreateFailure
      raise CollectionExistsError, name: collection_name
    end

    def drop!
      collection(skip_consistency_check: true).drop
      logger.info("Successfully dropped '#{collection_name}'")
      @collection = nil
      true
    rescue CipherStash::Client::Error::CollectionDeleteFailure
      raise NoCollectionError, "Collection '#{collection_name}' cannot be dropped because it doesn't exist"
    end

    # TODO: This is a stub
    def info
      collection
    end

    private
      def collection(skip_consistency_check: false)
        @collection ||= client.collection(collection_name).tap do |collection|
          consistency_check!(collection) unless skip_consistency_check
        end
      rescue CipherStash::Client::Error::CollectionInfoFailure
        raise NoCollectionError, name: collection_name
      end

      def consistency_check!(collection)
        if indexes(collection).size != stash_indexes.indexes.size
          raise CollectionDivergedError, name: collection_name
        end

        stash_indexes.indexes.each do |target|
          if !has_index?(collection, target)
            raise CollectionDivergedError, name: collection_name
          end
        end
      end

      def client
        @client ||= CipherStash::Client.new(
          logger: ActiveStash::Logger.instance,
          metrics: cipherstash_metrics,
          **ActiveStash.config.to_client_opts
        )
      end

      def indexes(collection)
        collection.instance_variable_get("@indexes")
      end

      def has_index?(collection, target)
        self.indexes(collection).any? do |index|
          mapping = index.instance_variable_get("@settings")["mapping"]
          meta = index.instance_variable_get("@settings")["meta"]
          # TODO: Check other fields, too
          target.name == meta["$indexName"]
        end
      end

      def logger
        ActiveStash::Logger
      end
  end
end
