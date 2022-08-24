
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
      ActiveStash::Logger.info("Indexing #{self.class.name}[#{self.stash_id}]")
      ensure_stash_id

      # TODO: If this fails, throw :abort
      # it should unset stash_id if this record did not already exist
      # Note: It turns out that Lockbox doesn't support serializable_hash
      self.class.collection.upsert(
        self.stash_id,
        self.stash_record
      )
    end

    # TODO: Do we need to handle arbitrary nesting of associations?
    def stash_record
      associated_fields =
        self.class.stash_config[:assocs].reduce({}) do |attrs, (assoc, fields, _opts)|
          if send(assoc).present?
            send(assoc).attributes.reduce(attrs) do |attrs, (k, v)|
              attrs["__#{assoc}_#{k}"] = v if fields.include?(k)
              attrs
            end
          else
            attrs
          end
        end

      self.class.stash_config[:fields].reduce(associated_fields) do |attrs, (field, _)|
        self.attributes.reduce(attrs) do |attrs, (k, v)|
          attrs[k] = v if k == field
          attrs
        end
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
      attr_writer :collection_name, :cipherstash_metrics

      # FIXME: A bunch of things break when we use this as a default scope
      #def default_scope
      #  Relation.new(self)
      #end

      # TODO: Make this universal
      def is_stash_model?
        true
      end

      def validate_assoc_and_register_callback(assoc)
        reflection = self.reflect_on_association(assoc)
        
        case reflection
        when ActiveRecord::Reflection::HasOneReflection, ActiveRecord::Reflection::BelongsToReflection
          reflection.klass.after_save do |record|
            # TODO: Setting of stash ID
            inverse_name = reflection.inverse_of.name
            record.send(inverse_name).try(:cs_put)
          end

        when nil
          raise "No such association on #{self.name}: '#{assoc}'" # TODO: Use an error class

        else
          raise "Only 1-to-1 associations ('belongs_to' or 'has_one') are currently supported"
        end
      end

      # TODO: Note that this will only work for 1-1 associations
      # The only true solution here will be joins in CipherStash. Urf.
      def stash_index(*fields, only: nil, except: nil, **assocs)
        opts = {only: only, except: except}.compact

        stash_config[:fields] += fields.map do |field|
          unless field.is_a?(Symbol)
            raise ArgumentError, "Field names must be symbols (got #{field.inspect})"
          end

          # FIXME: its ok to define a field twice if its settings are different
          #if stash_config[:fields].has_key?(field)
          #  ActiveStash::Logger.warn("index for '#{field}' was defined more than once on '#{self}'")
          #end

          [field.to_s, opts]
        end

        # TODO: Validate assocs and register a callback for indexing
        assocs.each do |assoc, fields|
          unless assoc.is_a?(Symbol)
            raise ArgumentError, "Association names must be symbols (got #{assoc.inspect})"
          end

          validate_assoc_and_register_callback(assoc)

          stash_config[:assocs] << [assoc, fields.map(&:to_s), opts]
        end
      end

      # TODO: This could handle associations, too
      def stash_match_all(*args)
        stash_config[:multi] = Array(args)
      end

      # Perform a query using the CipherStash collection indexes
      def query(*args, &block)
        ::ActiveStash::Relation.new(current_scope || self).query(*args, &block)
      end

      # Reindex all records into CipherStash
      def reindex
        # TODO: eager load any associations
        records = find_each.lazy.map do |r|
          if r.stash_id.nil?
            r.update_columns(stash_id: SecureRandom.uuid)
          end

          ActiveStash::Logger.info("Indexing #{r.stash_id}")
          { id: r.stash_id, record: r.stash_record }
        end

        collection.streaming_upsert(records)

        true
      end

      # Object representing the underlying CipherStash collection
      def collection(reload = false)
        return @collection if @collection && !reload
        @collection = CollectionProxy.new(self)
      end

      # TODO: All of this can probably now get wrapped into the collection proxy
      #
      # Name of the Stash collection
      # Defaults to the name of the table
      def collection_name
        @collection_name || table_name
      end

      def cipherstash_metrics
        @cipherstash_metrics ||= CipherStash::Client::Metrics::Null.new
      end

      def stash_indexes # :nodoc:
        @stash_indexes ||= StashIndexes.new(self, stash_config).build!
      end

      # TODO: Can we collapse fields and assocs to be the same structure
      # Treat fields as being on a "root" type and assocs are nodes
      def stash_config
        @stash_config ||= {fields: [], assocs: [], multi: []}
      end
    end
  end
end
