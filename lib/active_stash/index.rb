module ActiveStash
  class Index
    attr_accessor :type, :valid_ops, :options, :name, :unique
    attr_reader :field

    # TODO: boolean supports range
    # TODO: string and text support ranges

    # These index types support uniqueness.
    # Note that when using :auto indexing with :unique, only the generated
    # :exact index will have the uniqueness validation.
    INDEX_TYPES_WITH_UNIQUE_SUPPORT = [:exact, :range]

    FIELD_TYPE_TO_SUPPORTED_INDEX_TYPES = {
      :timestamp => [:range],
      :date => [:range],
      :datetime => [:range],
      :float => [:range],
      :decimal => [:range],
      :integer => [:range],
      :string => [:range, :exact, :match],
      :text => [:range, :exact, :match],
      :boolean => [:range],
      :uuid => [:range],
    }

    RANGE_OPS = [:lt, :lte, :gt, :gte, :eq, :between]
    EXACT_OPS = [:eq]
    MATCH_OPS = [:match]

    INDEX_TYPE_TO_OPS = {
      :exact => EXACT_OPS,
      :range => RANGE_OPS,
      :match => MATCH_OPS
    }

    OPS_HASH = {
      lt: "<",
      lte: "<=",
      gt: ">",
      gte: ">=",
      eq: "==",
      match: "=~",
      between: "between"
    }

    def initialize(field, type, **opts)
      @field = field
      @type = type
      @options = opts
      @name = @options[:name] || @field.to_s
      @options.delete(:name)
      @valid_ops = INDEX_TYPE_TO_OPS[type]
      @unique = @options[:unique] || false
      @options.delete(:unique)
    end

    def self.valid_index_type_for_field_type?(index_type, field_type)
      applicable_index_types(field_type).include?(index_type)
    end

    def self.applicable_index_types(type)
      FIELD_TYPE_TO_SUPPORTED_INDEX_TYPES[type] || []
    end

    def make_unique!
      @unique = true
    end

    def self.exact(field, **opts)
      new(field, :exact, **opts)
    end

    def self.match(field, **opts)
      new(field, :match, name: "#{field}_match", **opts)
    end

    def self.match_multi(fields, **opts)
      new(fields, :match, name: "__match_multi", **opts)
    end

    def self.range(field, **opts)
      new(field, :range, name: "#{field}_range", **opts)
    end

    def self.dynamic_match(field, **opts)
      new(field, :match, name: "#{field}_dynamic_match", **opts)
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
end