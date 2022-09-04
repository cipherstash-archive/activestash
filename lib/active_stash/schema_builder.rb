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
      indexes = @model.stash_indexes.all.each_with_object({}) do |index, acc|
        case index.type
          when :exact
            exact_index(acc, index)

          when :match
            match_index(acc, index)

          when :range
            range_index(acc, index)

          when :dynamic_match
            dynamic_match(acc, index)
        end
      end

      {"indexes" => indexes, "type" => stash_type}
    end

    private
    def stash_type
      ActiveStash::ModelReflection.fields(@model).inject({}) do |attrs, (field,type)|
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
          end

        attrs
      end
    end

    def match_index(schema, index)
      schema[index.name] = {
        "kind" => "match",
        "fields" => Array(index.field),
        "tokenFilters" => [
          { "kind" => "downcase" },
          { "kind" => "ngram", "tokenLength" => 3 }
        ],
        "tokenizer" => { "kind" => "standard" }
      }.tap do |idx|
        if index.options.key?(:filter_size)
          idx["filterSize"] = index.options[:filter_size]
        end
        if index.options.key?(:filter_term_bits)
          idx["filterTermBits"] = index.options[:filter_term_bits]
        end
      end

      schema
    end

    def range_index(schema, index)
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

    def exact_index(schema, index)
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

    def dynamic_match(schema, index)
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
