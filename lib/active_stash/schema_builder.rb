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
      new_schema.tap do |schema|
        fields.inject(schema[:indexes]) do |indexes, (field, type)|
          case type
            when :text, :string
              string_index!(indexes, field)

            when :timestamp, :date, :datetime, :float, :decimal, :integer
              range_index!(indexes, field)

            when :boolean
              exact_index!(indexes, field)

            when :binary
              STDERR.puts "Warning: ignoring field '#{field}' which has type binary as index type cannot be implied"
          end

          indexes
        end
      end
    end

    def fields
      fields = @model.attribute_types.inject({}) do |attrs, (k,v)|
        attrs.tap { |a| a[k] = v.type }
      end
      
      handle_encrypted_types(fields)
    end

    private
    def new_schema
      {
        type: stash_type,
        indexes: {}
      }
    end

    def stash_type
      fields.inject({}) do |attrs, (field,type)|
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

    def handle_encrypted_types(fields)
      if @model.respond_to?(:lockbox_attributes)
        @model.lockbox_attributes.each do |(attr, settings)|
          if settings[:attribute] != settings[:encrypted_attribute]
            fields.delete(settings[:encrypted_attribute])
          end
        end
      end

      ignore_ids(fields)
    end

    def ignore_ids(fields)
      fields.tap do |f|
        f.delete("id")
        f.delete("stash_id")
      end
    end

    # Should we use dynamics?
    def string_index!(schema, name)
      exact_index!(schema, name)
      match_index!(schema, name)

      schema
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
