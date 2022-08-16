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
          end
        end
      end

      {"indexes" => indexes, "type" => stash_schema_types}
    end

    private
    def stash_schema_types
      p :STASH_SCHEMA_TYPES, @model, @model.stash_fields
      @model.stash_fields.each_with_object({}) do |field, attrs|
        type = @model.stash_field_type(field)
        case type
          when :text, :string
            attrs[field] = "string"

          when :timestamp, :date, :datetime
            attrs[field] = "date"

          when :float, :decimal
            attrs[field] = "float64"

          when :integer
            attrs[field] = "uint64"

          when :boolean
            attrs[field] = "boolean"

          else
            ActiveStash::Logger.info("Not including field #{field.inspect} in schema because it has unsupported type #{type.inspect}")
          end
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
      schema[index.name] = {
        "kind" => "range",
        "field" => index.field
      }

      schema
    end

    def exact_index!(schema, index)
      schema[index.name] = {
        "kind" => "exact",
        "field" => index.field
      }

      schema
    end
  end
end
