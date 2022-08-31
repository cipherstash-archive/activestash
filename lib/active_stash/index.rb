module ActiveStash
  class Index
    attr_accessor :type, :valid_ops, :options
    attr_reader :field

    RANGE_TYPES = [:timestamp, :date, :datetime, :float, :decimal, :integer]

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