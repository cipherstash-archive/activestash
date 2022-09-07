module ActiveStash
  class Index
    attr_accessor :type, :valid_ops, :options
    attr_reader :field

    # TODO: boolean supports range
    # TODO: string and text support ranges

    RANGE_TYPES = [:timestamp, :date, :datetime, :float, :decimal, :integer, :boolean]
    EXACT_TYPES = [:string, :text, :uuid]
    MATCH_TYPES = [:string, :text]

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
      # TODO boolean should support range so that it can be sorted
      :boolean => [:exact],
      :uuid => [:exact],
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
      @valid_ops = INDEX_TYPE_TO_OPS[type]

      # This is sub-optimal. It's a result of being able to say
      #
      # stash_index :email, unique: true
      #
      # Assuming 'email' is a string field, then exact, range and match indexes
      # will be applied but unique only applies to the match index.
      #
      # The below if statement removes the unique option from the match index.
      if @type == :match
        @unique = false
      end
    end

    def self.applicable_index_types(type)
      index_types = FIELD_TYPE_TO_SUPPORTED_INDEX_TYPES[type] || []

      # unless index_types
      #   # TODO this should be an error
      #   ActiveStash::Logger.warn("ignoring field '#{field}' which has type #{type} as index type cannot be implied")
      # end

      index_types
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

    def name
      @options[:name] || @field.to_s
    end

    def unique
      @options[:unique]
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