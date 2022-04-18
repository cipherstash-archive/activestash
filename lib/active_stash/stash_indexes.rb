module ActiveStash
  class Index
    attr_accessor :field, :type

    def initialize(field)
      @field = field
    end

    def self.exact(field)
      new(field).tap do |index|
        index.type = :exact
      end
    end

    def self.match(field)
      new(field).tap do |index|
        index.type = :match
      end
    end

    def self.range(field)
      new(field).tap do |index|
        index.type = :range
      end
    end

    def self.ordering(field)
      new(field).tap do |index|
        index.type = :ordering
      end
    end
  end

  class StashIndexes
    def initialize(model)
      @model = model
    end

    def on(field)
      all.select do |index|
        index.field == field
      end
    end

    def all
      build! unless @indexes
      @indexes
    end

    def build!
      @indexes = fields.flat_map do |(field, type)|
        case type
          when :text, :string
            [Index.exact(field), Index.match(field)]

          when :string
            [Index.ordering(field)]

          when :timestamp, :date, :datetime, :float, :decimal, :integer
            [Index.range(field)]

          when :boolean
            [Index.exact(field)]

          when :binary
            STDERR.puts "Warning: ignoring field '#{field}' which has type binary as index type cannot be implied"
        end
      end

      self
    end

    def fields
      fields = @model.attribute_types.inject({}) do |attrs, (k,v)|
        attrs.tap { |a| a[k] = v.type }
      end
      
      handle_encrypted_types(fields)
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
  end
end
