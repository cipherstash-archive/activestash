
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
      ensure_stash_id

      ActiveStash::Logger.info("Indexing #{self.stash_id}")
      ActiveStash::Logger.debug("Record content: #{self.stash_attrs.inspect}")

      # TODO: If this fails, throw :abort
      # it should unset stash_id if this record did not already exist
      # Note: It turns out that Lockbox doesn't support serializable_hash
     self.class.collection.upsert(
        self.stash_id,
        self.stash_record
      )
    end

    def stash_record
      {}.tap do |record|
        self.class.stash_fields.each do |field|



      self.attributes.select do |k, v|
        indexed_fields.include?(k.to_sym)
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

      # Declare one or more fields to be indexed in CipherStash.
      #
      # Before an encrypted field in a model can be queried, it must be declared as a queryable field so that ActiveStash knows to index it.
      # This is done by calling `stash_index` with the names of one or more fields in the model, or in associated models.
      #
      #
      # # Declaring a field to be fully indexed
      #
      # The simplest way to say that a field on the current model is to be indexed is to just pass the field name, as a symbol, to `stash_index`:
      #
      # ```
      # class Foo < ApplicationRecord
      #   # Makes the `stash_index` method available to the model
      #   include ActiveStash::Search
      #
      #   # Make the `name` field queryable, even though it's encrypted
      #   stash_index :name
      # ```
      #
      # If you have more than one field that needs to be queryable, you can use several `stash_index` calls, or pass them into one call:
      #
      # ```
      #   # ...
      #   stash_index :name, :date_of_birth, :something_else, :etc
      #   # ...
      # ```
      #
      #
      # # Restricting index types
      #
      # CipherStash provides [several different kinds of indexes](https://docs.cipherstash.com/reference/index-types/index.html), to support different kinds of queries on encrypted data.
      # By default, ActiveStash will create indexes of all relevant kinds for the type of data that is being indexed.
      #
      # However, indexes are not zero-cost: the more indexes there are, the more data needs to be written to the collection, which means writes will be slightly slower.
      # If you don't need to perform certain types of queries on a field, you can restrict which indexes are created for a field, using the `only:` and `except:` options.
      # Both of these options take a symbol or array of symbols representing the various index types:
      #
      # * `:exact` (supports "is this value identical to that value" equality operations)
      # * `:range` (supports "is this value less than/greater than that value" inequality operations, and also needed for ordering)
      # * `:match` (supports "is this string a subset of that other string" text match operations)
      #
      # So, if you have a string field where you only want to support `field == "something"` queries, such as an enum, then you can improve performance like this:
      #
      # ```
      #   # ...
      #   stash_index :field, only: :exact
      #   # ...
      # ```
      #
      # On the other hand, if you want to do equality queries and sort by the values in a string field, but don't want to support full-text search, this will do the job:
      #
      # ```
      #   # ...
      #   stash_index :field, except: :match
      #   # ...
      # ```
      #
      #
      # # Querying across multiple models
      #
      # Unlike relational databases (like MySQL, Postgres, SQL Server, etc), CipherStash does not support "joining" multiple collections in a single query.
      # Instead, ActiveStash provides the ability to include fields from multiple models in the records in a single collection, so that queries can use all of those fields.
      # This happens automatically, and the data in the collection is automatically updated whenever any of the data in the relevant models are modified.
      #
      # To declare that a field in an associated model should be included in the records of this model, pass the relation and the field name(s) as a hash to `stash_index`,
      # ***after*** the association has been defined:
      #
      # ```
      #   class Book < ApplicationRecord
      #     include ActiveStash::Search
      #
      #     # Declare the association -- this MUST be done before referring to the association with `stash_index`
      #     belongs_to :author
      #
      #     # Make some of the fields in User queryable
      #     stash_index author: %i{first_name last_name dob}
      #   end
      # ```
      #
      # Note that ActiveStash is quite capable of indexing fields in other models that aren't themselves encrypted.
      # Including data from other models is a search convenience.
      # You should include all fields from other related models that you need to use in "joined" queries, regardless of whether those fields are encrypted.
      #
      # "Nesting" of associations is also supported (ie `stash_index foo: { bar: :baz }`), to support transitive associations.
      # These work identically to single-level associations.
      #
      def stash_index(*fields, only: nil, except: nil, **assocs)
        p :STASH_INDEX_CALL, self, fields, only, except, assocs
        opts = {only: only, except: except}.compact

        fields.each do |field|
          unless field.is_a?(Symbol)
            raise ArgumentError, "Field names must be symbols (got #{field.inspect})"
          end

          if stash_config[:fields].has_key?(field)
            ActiveStash::Logger.warn("index for '#{field}' was defined more than once on '#{self}'")
          end

          stash_config[:fields][field] = opts
        end

        assocs.each do |assoc, fields|
          unless assoc.is_a?(Symbol)
            raise ArgumentError, "Association names must be symbols (got #{assoc.inspect})"
          end

          expand_assoc_fields(fields).each do |field|
            k = { assoc => field }

            if stash_config[:fields].has_key?(k)
              ActiveStash::Logger.warn("index for '#{k.inspect}' was defined more than once on '#{self}'")
            end

            p :ASSOC_ASSIGN, field, opts, k

            stash_config[:fields][k] = opts
          end
        end
      end

      def stash_match_all(*args)
        stash_config[:multi] = args
      end

      # Perform a query using the CipherStash collection indexes
      def query(*args, &block)
        ::ActiveStash::Relation.new(current_scope || self).query(*args, &block)
      end

      # Reindex all records into CipherStash
      def reindex
        records = find_each.lazy.map do |r|
          if r.stash_id.nil?
            r.update_columns(stash_id: SecureRandom.uuid)
          end
          { id: r.stash_id, record: r.attributes }
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
        @stash_indexes ||= StashIndexes.new(self, stash_config)
      end

      def stash_fields
        stash_config[:fields].keys
      end

      def stash_config
        @stash_config ||= {fields: {}, multi: []}
      end

      def stash_field_type(field)
        case field
        when Symbol
          self.attribute_types[field.to_s].type
        when Hash
          if field.length > 1
            raise ArgumentError, "Invalid hash passed to stash_field_type; must be a single-value hash (got #{field.inspect})"
          end
          assoc_name = field.keys.first
          unless assoc_name.is_a?(Symbol)
            raise ArgumentError, "Invalid hash key passed to stash_field_type; must be a symbol (got #{assoc_name.inspect})"
          end
          assoc = self.reflections[assoc_name.to_s]
          if assoc.nil?
            raise ArgumentError, "No association on #{self} named '#{assoc_name}'"
          end
          assoc.klass.stash_field_type(field.values.first)
        else
          raise ArgumentError, "Must pass symbol or hash to stash_field_type (got #{field.inspect})"
        end
      end

      private

      def expand_assoc_fields(fields)
        case fields
        when Symbol
          [fields]
        when Array
          fields
        when Hash
          [].tap do |expansion|
            fields.each do |k, v|
              expand_assoc_fields(v).each do |f|
                expansion << { k => f }
              end
            end
          end
        else
          raise ArgumentError, "Value of association index must be symbol or array of symbols (got #{fields.inspect})"
        end
      end
    end
  end
end
