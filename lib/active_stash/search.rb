
module ActiveStash
  module Search
    def self.included(base)
      base.extend ClassMethods

      base.class_eval do
        before_save :ensure_stash_id
        after_save :cs_put
        after_destroy :cs_delete
      end
    end

    def ensure_stash_id
      self.stash_id ||= SecureRandom.uuid
    end

    def cs_put
      ActiveStash::Logger.info("Indexing #{self.stash_id}")

      self.class.collection.upsert(
        self.stash_id,
        self.attributes,
        store_record: false
      )
    end

    def cs_delete
      self.class.collection.delete(self.stash_id)
    end

    module ClassMethods
      attr_writer :collection_name

      def is_stash_model?
        true
      end

      def query(*args, &block)
        query = QueryDSL.new(self).build_query(*args, &block)

        # Map our "higher-level" DSL to ruby-client
        ids = collection.query { |q|
          query.fields.each do |field|
            q.add_constraint(field.index.name, field.op.to_s, field.value)
          end
        }.records.map(&:id)

        relation = where(stash_id: ids)
        # TODO: Ordering
        #order ? relation.in_order_of(:stash_id, ids) : relation
        relation
      end

      def reindex
        find_each(&:save!)
        true
      end

      def collection
        # TODO: Pass the logger option
        @collection ||= CipherStash::Client.new(logger: ActiveStash::Logger.instance).collection(collection_name)
      end

      # Name of the Stash collection
      # Defaults to the name of the table
      def collection_name
        @collection_name || table_name
      end

      def stash_indexes
        @stash_indexes ||= StashIndexes.new(self).build!
      end
    end
  end
end
