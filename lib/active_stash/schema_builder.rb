module ActiveStash
  class SchemaBuilder
    def initialize(model)
      @model = model
    end

    # Steps
    # - load columns_hash
    # - adjust types
    #   - has lockbox columns
    #   - has encrypted columns
    #     - read a record to infer the types (warn if unable to do so)

    # TODO: Don't worry about encrypted fields, just index everything
    # Because we'd need to have all fields available to filter/sort on

    # TODO: all strings in one index
    # TODO: dates, integers
    def build
      encrypted_columns.inject({}) do |schema, pair|
        case pair[1]
        when string_index!(schema, pair[0])
        end
        schema
      end
    end

    # TODO: Use dynamics wherever possible
    def string_index!(schema, name)
      schema["#{name}_exact"] = { kind: "exact", field: name }
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

    def encrypted_columns
      @model.encrypted_attributes.map do |attr|
        [attr, User.columns_hash[attr.to_s].type]
      end
    end
  end
end
