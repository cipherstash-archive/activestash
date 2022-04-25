
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

      # FIXME: A bunch of things break when we use this as a default scope
      #def default_scope
      #  StashRelation.new(self)
      #end

      def is_stash_model?
        true
      end

      def query(*args, &block)
        StashRelation.new(self).query(*args, &block)
      end

      def reindex
        find_each(&:save!)
        true
      end

      def collection
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
