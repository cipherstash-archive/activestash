
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
      # TODO: Include Logging module which uses the Rails logger if defined
      puts "Indexing #{self.stash_id}"
      self.class.collection.put(self.stash_id, self)
    end

    def cs_delete
      self.class.collection.delete(self.stash_id)
    end

    module ClassMethods
      attr_writer :collection_name

      def is_stash_model?
        true
      end

      def query(str = nil, opts = {}, &block)
        QueryDSL.new().build_query(str, opts, &block)
      end

      def query_orig(field, condition, value, order = nil)
        ids = collection.query(field, condition, value, order)
        relation = where(stash_id: ids)

        # Ensure that stash ordering is maintained when hydrating
        order ? relation.in_order_of(:stash_id, ids) : relation
      end

      def reindex
        find_each(&:save!)
      end

      def collection
        @collection ||= ActiveStash::Stash.connect(collection_name)
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
