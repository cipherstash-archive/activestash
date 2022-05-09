require 'forwardable'

module ActiveStash
  class CollectionProxy
    extend Forwardable
    def_delegators :collection, :query
    def_delegators :@model, :collection_name, :stash_indexes

    def initialize(model)
      @model = model
    end

    def upsert(stash_id, attrs, store_record:)
      collection.upsert(stash_id, attrs, store_record: store_record)
    rescue GRPC::NotFound
      raise NoCollectionError, name: collection_name
    end

    def schema
      SchemaBuilder.new(@model).build
    end

    def create!
      client.create_collection(collection_name, schema)
      logger.info("Successfully created '#{collection_name}'")
      true
    rescue GRPC::AlreadyExists
      raise CollectionExistsError, name: collection_name
    end

    def drop!
      collection(skip_consistency_check: true).drop
      logger.info("Successfully dropped '#{collection_name}'")
      @collection = nil
      true
    rescue GRPC::NotFound
      raise NoCollectionError, "Collection '#{collection_name}' cannot be dropped because it doesn't exist"
    end

    # TODO: This is a stub
    def info
      collection
    rescue GRPC::NotFound
      raise NoCollectionError, name: collection_name
    end

    private
      def collection(skip_consistency_check: false)
        @collection ||= client.collection(collection_name).tap do |collection|
          consistency_check!(collection) unless skip_consistency_check
        end
      rescue GRPC::NotFound
        raise NoCollectionError, name: collection_name
      end

      def consistency_check!(collection)
        reflection = ActiveStash::Reflection.new(collection)

        if reflection.indexes.size != stash_indexes.all.size
          raise CollectionDivergedError, name: collection_name
        end

        stash_indexes.all.each do |target|
          if !reflection.has_index?(target)
            raise CollectionDivergedError, name: collection_name
          end
        end
      end

      def client
        @client = CipherStash::Client.new(logger: ActiveStash::Logger.instance)
      end

      def logger
        ActiveStash::Logger
      end
  end
end
