module ActiveStash
  class Index
    attr_accessor :type, :valid_ops
    attr_reader :field
    attr_reader :name

    RANGE_TYPES = [:timestamp, :date, :datetime, :float, :decimal, :integer]
    RANGE_OPS = [:lt, :lte, :gt, :gte, :eq, :between]

    def initialize(field, name = field)
      @field = field
      @name = name
    end

    def self.exact(field)
      new(field).tap do |index|
        index.type = :exact
        index.valid_ops = [:eq]
      end
    end

    def self.match(field)
      new(field, "#{field}_match").tap do |index|
        index.type = :match
        index.valid_ops = [:match]
      end
    end

    def self.range(field)
      new(field, "#{field}_range").tap do |index|
        index.type = :range
        index.valid_ops = RANGE_OPS
      end
    end

    def valid_op?(op)
      valid_ops.include?(op)
    end
  end

  class StashIndexes
    def initialize(model)
      @model = model
    end

    def on(field)
      all.select do |index|
        index.field.to_s == field.to_s
      end
    end

    def all
      build! unless @indexes
      @indexes
    end

    def build!
      @indexes = fields.flat_map do |(field, type)|
        case type
          when *Index::RANGE_TYPES
            [Index.range(field)]

          # TODO: Probably shouldn't do range types on text
          # but AR Encrypted record treats all strings as :text
          when :string, :text
            # Special case!
            [Index.exact(field), Index.match(field), Index.range(field)]

          when :boolean
            [Index.exact(field)]

          when :binary
            ActiveStash::Logger.warn("ignoring field '#{field}' which has type binary as index type cannot be implied")
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
