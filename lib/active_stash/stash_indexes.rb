module ActiveStash
  class Index
    attr_accessor :type, :valid_ops
    attr_reader :field
    attr_reader :name

    RANGE_TYPES = [:timestamp, :date, :datetime, :float, :decimal, :integer]
    RANGE_OPS = [:lt, :lte, :gt, :gte, :eq, :between]

    def initialize(field, name = field)
      @field = field
      @name = name.to_s
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

    def self.match_multi(fields, name)
      new(fields, name).tap do |index|
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

    def self.dynamic_match(field)
      new(field, "#{field}_dynamic_match").tap do |index|
        index.type = :dynamic_match
        index.valid_ops = [:match]
      end
    end

    def valid_op?(op)
      valid_ops.include?(op)
    end
  end

  class StashIndexes
    def initialize(model, config_indexes)
      @model = model
      # TODO: Warn if no indexes defined - should we just index everything then!?
      @stash_config = config_indexes || {}
    end

    # Returns the match_multi index if one is defined
    def get_match_multi
      all.find do |index|
        index.name == "__match_multi"
      end
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
      _fields = fields()
      @indexes = []

      if Hash === @stash_config[:indexes]
        @stash_config[:indexes].each do |field, options|
          type = _fields[field.to_s]

          targets =
            case type
              when *Index::RANGE_TYPES
                target_indexes(:range, options)

              when :string, :text
                target_indexes(:exact, :match, :range, options)

              when :boolean, :uuid
                target_indexes(:exact, options)

              else
                ActiveStash::Logger.warn("ignoring field '#{field}' which has type #{type} as index type cannot be implied")
                []
            end

          @indexes.concat(new_indexes(field, targets))
        end
      end

      # TODO: Test this case
      if @stash_config[:multi]
        # Check that all multi fields are texty
        @stash_config[:multi].each do |field|
          type = _fields[field.to_s]
          unless type == :string || type == :text
            raise ConfigError, "Cannot specify field '#{field}' in stash_match_all because it is neither a string nor text type"
          end
        end

        @indexes << Index.match_multi(@stash_config[:multi], "__match_multi")
      end

      self
    end

    def fields
      fields = @model.attribute_types.inject({}) do |attrs, (k,v)|
        attrs.tap { |a| a[k] = v.type }
      end

      handle_encrypted_types(fields)
    end

    private
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

      def target_indexes(*args)
        options = args.extract_options!
        if only = options[:only]
          args.select do |index_type|
            Array(only).include?(index_type)
          end
        elsif except = options[:except]
          args.reject do |index_type|
            Array(except).include?(index_type)
          end
        else
          args
        end
      end

      def new_indexes(field, index_types)
        if index_types.empty?
          ActiveStash::Logger.warn("configuration for '#{field}' means that it has no stash indexes defined")
        end

        Array(index_types).map do |index_type|
          case index_type
            when :exact; Index.exact(field)
            when :range; Index.range(field)
            when :match; Index.match(field)
          end
        end
      end
  end
end
