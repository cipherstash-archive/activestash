module ActiveStash
  class SchemaBuilder
    def initialize(model)
      @model = model
    end

    # Builds a schema object for the model
    #
    # ## Types
    #
    # * `:boolean` map to "exact" indexes
    # * `"timestamp`, `:date`, `:datetime` and all numeric types map to "range" indexes
    # * `:string` and `text` types map to exact indexes but also have "match" indexes
    # created with a "_match" suffix (e.g. "email_match")
    #
    def build
      indexes = {}.tap do |indexes|
        @model.stash_indexes.all.each do |index|
          case index.type
            when :exact
              exact_index!(indexes, index)

            when :match
              match_index!(indexes, index)

            when :range
              range_index!(indexes, index)

            when :dynamic_match
              dynamic_match!(indexes, index)
          end
        end
      end
    
      {"indexes" => indexes, "type" => stash_type}.tap do |schema|
        ActiveStash::Logger.debug(<<-MSG
          Creating Schema
          #{stash_type}
          #{indexes}
          MSG
        )
      end
    end

    private
    # TODO: This method would be handy as a public method on the collection proxy
    def stash_type
      # TODO: This code ignores the :only and :except options meaning
      # there may be fields here that are not indexed
      # However, we may want to revisit this because asynchronous reindexing
      # will need to have fields stored if new indexes are added later
      _fields = @model.stash_indexes.fields(@model)

      attrs = @model.stash_config[:fields].reduce({}) do |attrs, (field, _opts)|
        type = _fields[field.to_s]

        attrs[field] = map_db_type_to_stash_type(type)
        attrs
      end

      @model.stash_config[:assocs].reduce(attrs) do |attrs, (assoc, indexed_fields, _opts)|
        klass = @model.reflect_on_association(assoc).klass
        assoc_fields = @model.stash_indexes.fields(klass)
        indexed_fields.reduce(attrs) do |attrs, indexed_field|
          attrs["__#{assoc}_#{indexed_field}"] = map_db_type_to_stash_type(assoc_fields[indexed_field.to_s])
          attrs
        end
      end
    end

    def map_db_type_to_stash_type(db_type)
      case db_type
        when :text, :string; "string"
        when :timestamp, :date, :datetime; "date"
        when :float, :decimal; "float64"
        when :integer; "uint64"
        when :boolean; "boolean"
      else
        # TODO: Give this a sensible error type
        raise "Unknown mapping for type '#{type}'"
      end
    end

    def match_index!(schema, index)
      schema[index.name] = {
        "kind" => "match",
        "fields" => Array(index.field),
        "tokenFilters" => [
          { "kind" => "downcase" },
          { "kind" => "ngram", "tokenLength" => 3 }
        ],
        "tokenizer" => { "kind" => "standard" }
      }

      schema
    end

    def range_index!(schema, index)
      mapping = {
        "kind" => "range",
        "field" => index.field
      }

      if index.unique
        mapping = {
          "kind" => "range",
          "field" => index.field,
          "unique" => index.unique
        }
      end

      schema[index.name] = mapping

      schema
    end

    def exact_index!(schema, index)
      mapping = {
        "kind" => "exact",
        "field" => index.field
      }

      if index.unique
        mapping = {
          "kind" => "range",
          "field" => index.field,
          "unique" => index.unique
        }
      end

      schema[index.name] = mapping

      schema
    end

    def dynamic_match!(schema, index)
      schema[index.name] = {
        "kind" => "dynamic-match",
        "tokenFilters" => [
          { "kind" => "downcase" },
          { "kind" => "ngram", "tokenLength" => 3 }
        ],
        "tokenizer" => { "kind" => "standard" }
      }
    end
  end
end
