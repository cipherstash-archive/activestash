module ActiveStash
  class Index
    attr_accessor :type, :valid_ops, :unique, :options
    attr_reader :field
    attr_reader :name

    RANGE_TYPES = [:timestamp, :date, :datetime, :float, :decimal, :integer]
    RANGE_OPS = [:lt, :lte, :gt, :gte, :eq, :between]

    OPS_HASH = {
      lt: "<",
      lte: "<=",
      gt: ">",
      gte: ">=",
      eq: "==",
      match: "=~",
      between: "between"
    }

    def initialize(field, name = field)
      @field = field
      @name = name.to_s
      @options = {}
    end

    def self.exact(field)
      new(field).tap do |index|
        index.type = :exact
        index.valid_ops = [:eq]
      end
    end

    def self.exact_unique(field)
      new(field).tap do |index|
        index.type = :exact
        index.valid_ops = [:eq]
        index.unique = true
      end
    end

    def self.match(field, **opts)
      new(field, "#{field}_match").tap do |index|
        index.type = :match
        index.valid_ops = [:match]
        index.options = opts
      end
    end

    def self.match_multi(fields, name, **opts)
      new(fields, name).tap do |index|
        index.type = :match
        index.valid_ops = [:match]
        index.options = opts
      end
    end

    def self.range(field)
      new(field, "#{field}_range").tap do |index|
        index.type = :range
        index.valid_ops = RANGE_OPS
      end
    end

    def self.range_unique(field)
      new(field, "#{field}_range").tap do |index|
        index.type = :range
        index.valid_ops = RANGE_OPS
        index.unique = true
      end
    end

    def self.dynamic_match(field)
      new(field, "#{field}_dynamic_match").tap do |index|
        index.type = :dynamic_match
        index.valid_ops = [:match]
      end
    end

    def valid_op?(op)
      @valid_ops.include?(op)
    end

    def valid_ops
      @valid_ops.map do |op|
        OPS_HASH[op]
      end
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

          targets = validate_unique_targets(targets, options, field)

          @indexes.concat(new_indexes(field, targets, options))
        end
      end

      # TODO: Test this case
      if @stash_config[:multi]
        opts = {}
        # Check that all multi fields are texty
        @stash_config[:multi].each do |field|
          if field.is_a?(Hash)
            opts = field
          else
            type = _fields[field.to_s]
            unless type == :string || type == :text
              raise ConfigError, "Cannot specify field '#{field}' in stash_match_all because it is neither a string nor text type"
            end
          end
        end

        @indexes << Index.match_multi(@stash_config[:multi], "__match_multi", **opts)
      end

      self
    end

    def fields
      fields = @model.attribute_types.inject({}) do |attrs, (k,v)|
        type = v.type

        # ActiveRecord encryption is available from Rails 7.
        if Rails::VERSION::MAJOR >= 7
          type = ActiveRecord::Encryption::EncryptedAttributeType === v ? v.cast_type.type : v.type
        end

        attrs.tap { |a| a[k] = type }
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

      def unique_constraint_on_match_index?(options, targets)
        (options.key?(:unique) && targets.member?(:match)) && (!targets.member?(:exact) && !targets.member?(:range))
      end

      # Returns original targets as is if a unique key has not been specified on the field.
      #
      # It will raise a config error if a unique key has been provided and only a match index has been set on the field.
      #
      # Otherwise will map through the targets and update only the exact and range indexes as
      # unique indexes and return other targets as is.
      def validate_unique_targets(targets, options, field)
        unique_constraint_on_match_index =
        if !options.key?(:unique)
          targets
        elsif unique_constraint_on_match_index?(options, targets)
          raise ConfigError, "Cannot specify field '#{field}' with a unique constraint on match"
        else
          targets.map do |t|
            case t
            when :exact
              options[:unique] ? :exact_unique : :exact
            when :range
              options[:unique] ? :range_unique : :range
            else
              t
            end
          end
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

      def new_indexes(field, index_types, index_options)
        if index_types.empty?
          ActiveStash::Logger.warn("configuration for '#{field}' means that it has no stash indexes defined")
        end

        Array(index_types).map do |index_type|
          case index_type
            when :exact; Index.exact(field)
            when :range; Index.range(field)
            when :match; Index.match(field, **index_options)
            when :exact_unique; Index.exact_unique(field)
            when :range_unique; Index.range_unique(field)
          end
        end
      end
  end
end
