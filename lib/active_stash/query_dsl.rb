module ActiveStash
  class QueryDSL
    class ConstraintHelper
      OPS = [:lt, :lte, :gt, :gte, :eq]

      def match(value, opts = {})
        { op: :match, value: value }
      end

      def between(a, b)
        { op: :between, value: [a, b] }
      end

      def method_missing(op, *args)
        if OPS.include?(op) && args.size == 1
          { op: op, value: args[0] }
        else
          super
        end
      end
    end

    def initialize(model)
      @model = model
      @constraints = {}
    end

    def build_query(*args)
      str, opts =
        if args.length == 2
          args
        elsif args.length <= 1
          [nil, args[0] || {}]
        else
          raise NameError, "build_query must take 1 or 2 arguments"
        end

      @constraints.merge!(all: str) if str
      @constraints.merge!(opts[:where]) if opts[:where]
      @order = opts[:order] if opts[:order]

      if block_given?
        @constraints.merge!(yield ConstraintHelper.new)
      end

      self
    end

    def validate!
      @constraints.each do |(field, condition)|
        op = condition.instance_of?(Hash) ? condition[:op] : :eq
        indexes_for_field = @model.stash_indexes.on(field)
        valid_indexes = indexes_for_field.detect do |index|
          index.valid_op?(op)
        end

        unless field == :all # FIXME: Remove this and make sure an all index has been generated
          raise "No valid indexes for query on #{field} (#{condition})" unless valid_indexes
        end
      end

      self
    end
  end
end
