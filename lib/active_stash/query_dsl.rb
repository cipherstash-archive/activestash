module ActiveStash
  class QueryDSL
    class Query
      attr_accessor :order

      def initialize
        @constraints = {}
      end

      def add_constraint(hash)
        @constraints.merge!(hash)
      end
    end

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

    def build_query(str = nil, opts = {})
      Query.new().tap do |payload|
        payload.add_constraint(all: str) if str
        payload.add_constraint(opts[:where]) if opts[:where]
        payload.order = opts[:order] if opts[:order]

        if block_given?
          payload.add_constraint(yield ConstraintHelper.new)
        end
      end



      #yield self if block_given?
    end
  end
end
