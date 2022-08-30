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
end