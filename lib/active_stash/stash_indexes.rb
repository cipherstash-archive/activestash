module ActiveStash
  class Index
    attr_reader :type
    attr_reader :field
    attr_reader :name

    RANGE_OPS = [:lt, :lte, :gt, :gte, :eq, :between]
    EXACT_OPS = [:eq]
    MATCH_OPS = [:match]

    OPS_HASH = {
      lt: "<",
      lte: "<=",
      gt: ">",
      gte: ">=",
      eq: "==",
      match: "=~",
      between: "between"
    }

    def initialize(name, field, type, ops)
      @name = name
      @field = field
      @type = type
      @valid_ops = ops
    end

    def valid_op?(op)
      @valid_ops.include?(op)
    end

    def valid_ops
      @valid_ops.map do |op|
        OPS_HASH[op]
      end
    end

    def precedence
      case @type
      when :exact
        0
      when :match
        1
      when :range
        2
      else
        raise RuntimeError, "Unknown index type; please augment #{__FILE__}:#{__LINE__}"
      end
    end

    class << self
      def exact(field, name = nil)
        name ||= name_from_field(field)
        new(name, field, :exact, EXACT_OPS)
      end

      def match(field, name = nil)
        name ||= name_from_field(field, "_match")
        new(name, field, :match, MATCH_OPS)
      end

      def range(field, name = nil)
        name ||= name_from_field(field, "_range")
        new(name, field, :range, RANGE_OPS)
      end

      private

      def name_from_field(field, suffix = "")
        case field
        when Symbol
          field.to_s + suffix
        when Hash
          unless field.length == 1
            raise ArgumentError, "Field must be symbol or single-element hash (got #{field.inspect})"
          end
          unless field.keys.first.is_a?(Symbol)
            raise ArgumentError, "Hash key must be symbol (got #{field.inspect})"
          end
          field.keys.first.to_s + "__" + name_from_field(field.values.first, suffix)
        else
          raise ArgumentError, "Field must be symbol or single-element hash (got #{field.inspect})"
        end
      end
    end
  end

  class StashIndexes
    DATA_TYPES_BY_INDEX_TYPE = {
      range: %i{timestamp date datetime float decimal integer boolean string text},
      exact: %i{uuid string text},
      match: %i{string text}
    }

    def initialize(model, stash_config)
      @model = model
      @stash_config = stash_config
    end

    # Returns the match_multi index if one is defined
    def get_match_multi
      all.find do |index|
        index.name == "__match_multi"
      end
    end

    def on(field)
      unless field.is_a?(Symbol) || field.is_a?(Hash)
        raise ArgumentError, "Must specify field to retrieve indexes for as a symbol or hash"
      end
      all.select do |index|
        index.field == field
      end
    end

    def all
      @all ||= build_index_list
    end

    private

    def build_index_list
      [].tap do |indexes|
        @stash_config[:fields].each do |field, options|
          type = @model.stash_field_type(field)

          if create_index_of_type?(:range, field, options)
            indexes << Index.range(field)
          end

          if create_index_of_type?(:exact, field, options)
            indexes << Index.exact(field)
          end

          if create_index_of_type?(:match, field, options)
            indexes << Index.match(field)
          end
        end

        unless @stash_config[:multi].empty?
          # Check that all multi fields are texty
          @stash_config[:multi].each do |field|
            type = @model.stash_field_type(field)
            unless type == :string || type == :text
              raise ConfigError, "Cannot specify field '#{field}' in stash_match_all because it is neither a string nor text type"
            end
          end

          indexes << Index.match(@stash_config[:multi], "__match_multi")
        end
      end
    end

    def create_index_of_type?(index_type, field, options)
      DATA_TYPES_BY_INDEX_TYPE[index_type].include?(@model.stash_field_type(field)) && options_permit?(options, index_type)
    end

    def options_permit?(options, index_type)
      if options.key?(:only)
        Array(options[:only]).include?(index_type)
      elsif options.key?(:except)
        !Array(options[:except]).include?(index_type)
      else
        true
      end
    end
  end
end
