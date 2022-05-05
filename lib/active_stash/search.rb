
module ActiveStash # :nodoc:
  # = ActiveStash
  #
  # Provides encrypted index and search for ActiveRecord models that have encrypted fields.
  #
  # == (Re)indexing
  #
  # To index your encrypted data into CipherStash, use the reindex task:
  #
  #     rails active_stash:reindexall
  #
  # If you want to just reindex one model, for example `User`, run:
  #
  #     active_stash:reindex[User]
  #
  # You can also reindex in code:
  #
  #     User.reindex
  #
  # Depending on how much data you have, reindexing may take a while but you only need to do it once.
  # *ActiveStash will automatically index (and delete) data as it records are created, updated and deleted.*
  #
  # == Running Queries
  #
  # To perform queries over your encrypted records, you can use the `query` method
  # For example, to find a user by email address:
  #
  #     User.query(email: "person@example.com")
  #
  # This will return an ActiveStash::Relation which extends `ActiveRecord::Relation` so you can chain *most* methods
  # as you normally would!
  #
  # To constrain by multiple fields, include them in the hash:
  #
  #     User.query(email: "person@example.com", verified: true)
  #
  # You can perform a free-text search over all strings in the model by passing the query string as the first argument:
  #
  #     User.query("exam")
  #
  # To order by `dob`, do:
  #
  #     User.query(email: "person@example.com).order(:dob)
  #
  # You can even order by strings:
  #
  #     User.query(verified: true).order(:first_name)
  #  
  # Or to use limit and offset:
  #
  #     User.query(verified: true).limit(10).offset(20)
  #
  # This means that `ActiveStash` should work with pagination libraries like Kaminari.
  #
  # You also, don't have to provide any constraints at all and just use the encrypted indexes for ordering!
  # To order all records by `dob` descending and then `created_at`, do:
  #
  #     User.order(dob: :desc, :created_at)
  #
  # == Advanced Queries
  #
  # More advanced queries can be performed by passing a block to <tt>query</tt>.
  # For example, to find all users born in or after 1998:
  #
  #     User.query { |q| q.dob > "1998-01-01".to_date }
  #       
  # Or, to perform a free-text search on name:
  #
  #     User.query { |q| q.name =~ "Dan" }
  #
  # To combine multiple constraints, make multiple calls in the block:
  #
  #     User.query do |q|
  #       q.dob > "1998-01-01".to_date
  #       q.name =~ "Dan"
  #     end
  #
  # To perform a free-text search with additional constraints:
  #
  #    User.query("myquery") do |q|
  #      q.dob > "1998-01-01".to_date
  #    end
  #
  module Search
    def self.included(base)
      base.extend ClassMethods

      base.class_eval do
        before_save :ensure_stash_id
        after_save :cs_put
        after_destroy :cs_delete
      end
    end

    # Index this record into CipherStash
    def cs_put
      ActiveStash::Logger.info("Indexing #{self.stash_id}")
      ensure_stash_id

      # TODO: If this fails, throw :abort
      # it should unset stash_id if this record did not already exist
      # Note: It turns out that Lockbox doesn't support serializable_hash
      self.class.collection.upsert(
        self.stash_id,
        self.stash_attrs,
        store_record: false
      )
    end

    def stash_attrs
      indexed_fields = self.class.stash_config[:indexes].keys

      self.attributes.select do |k, v|
        indexed_fields.include?(k)
      end
    end

    # Delete the current record from the CipherStash index
    def cs_delete
      self.class.collection.delete(self.stash_id)
    end

    private
      def ensure_stash_id
        self.stash_id ||= SecureRandom.uuid
      end

    module ClassMethods
      attr_writer :collection_name

      # FIXME: A bunch of things break when we use this as a default scope
      #def default_scope
      #  Relation.new(self)
      #end

      # TODO: Make this universal
      def is_stash_model?
        true
      end

      def stash_index(*args)
        opts = args.extract_options!

        @stash_config ||= {}
        @stash_config[:indexes] ||= {}
        Array(args).each do |field|
          if @stash_config[:indexes].has_key?(field)
            ActiveStash::Logger.warn("index for '#{field}' was defined more than once on '#{self}'")
          end

          @stash_config[:indexes][field.to_s] = opts
        end
      end

      # TODO: Rename this to stash_match_all
      # By default index all strings - allow it to take only and except
      def stash_match_multi(*args)
        @stash_config ||= {}
        @stash_config[:multi] = Array(args)
      end

      # Perform a query using the CipherStash collection indexes
      def query(*args, &block)
        ::ActiveStash::Relation.new(current_scope || self).query(*args, &block)
      end

      # Reindex all records into CipherStash
      def reindex
        find_each do |record|
          record.save!(touch: false)
        end

        true
      end

      # Object representing the underlying CipherStash collection
      def collection
        @collection ||= CipherStash::Client.new(logger: ActiveStash::Logger.instance).collection(collection_name)
      end

      # TODO: create and drop collection methods here would be handy!

      # Name of the Stash collection
      # Defaults to the name of the table
      def collection_name
        @collection_name || table_name
      end

      def stash_indexes # :nodoc:
        @stash_indexes ||= StashIndexes.new(self, @stash_config).build!
      end

      def stash_config
        @stash_config || {indexes: [], multi: []}
      end
    end
  end
end
