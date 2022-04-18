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
              exact_index!(indexes, index.field)

            when :match
              match_index!(indexes, index.field)

            when :range
              range_index!(indexes, index.field)

            #when :ordering
            #  ordering_index!(schema.indexes, "#{index.field}_ordering")
          end
        end
      end
    
      {indexes: indexes, type: stash_type}
    end

    private
    def stash_type
      @model.stash_indexes.fields.inject({}) do |attrs, (field,type)|
        case type
          when :text, :string
            attrs[field] = :string

          when :timestamp, :date, :datetime
            attrs[field] = :date

          when :float, :decimal
            attrs[field] = :float64

          when :integer
            attrs[field] = :uint64

          when :boolean
            attrs[field] = :boolean
          end

        attrs
      end
    end

    def match_index!(schema, name)
      schema["#{name}_match"] = {
        kind: "match",
        fields: [name],
        tokenFilters: [
          { kind: "downcase" },
          { kind: "ngram", tokenLength: 3 }
        ],
        tokenizer: { kind: "standard" }
      }

      schema
    end

    def range_index!(schema, name)
      schema[name] = { kind: "range", field: name }

      schema
    end

    def exact_index!(schema, name)
      schema[name] = { kind: "exact", field: name }

      schema
    end
  end
end
