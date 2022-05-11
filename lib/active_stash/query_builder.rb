module ActiveStash
  # Query DSL
  #
  # @private
  class QueryBuilder # :nodoc:
    attr_reader :constraints

    def initialize(constraints)
      @constraints = constraints
    end

    # Build a query for the given model
    def self.build_query(model, constraint = {})
      # TODO: Eventually this can take a collection proxy
      collector = Collector.new(model)

      case constraint
        when Hash
          collector.add_hash(constraint)
        when String
          collector.match_all(constraint)
      end

      if block_given?
        yield collector
      end

      new(collector.fields)
    end

    class Collector < BasicObject # :nodoc:
      attr_reader :fields

      def initialize(model)
        @fields = []
        @model = model
        @stash_indexes = model.stash_indexes
      end

      def match_all(arg)
        index = @stash_indexes.get_match_multi
        ::Kernel.raise NoMatchAllError, name: @model.collection_name unless index
        @fields << (Field.new("__match_multi", [index]) =~ arg)
      end

      def method_missing(name, *args)
        field = Field.new(name, @stash_indexes.on(name))
        @fields << field
        field
      end

      def add_hash(fields)
        fields.map do |(field_name, value)|
          field = Field.new(field_name, @stash_indexes.on(field_name))
          @fields << (field == value)
        end
      end

      def inspect
        "<Constraints: " + fields.map(&:inspect).join(" AND ") + ">"
      end
    end

    class Field < BasicObject # :nodoc:
      attr_reader :index, :values, :op

      def initialize(name, available_indexes)
        @name = name
        @available_indexes = available_indexes
        ::Kernel.raise "No indexes available for '#{name}'" if @available_indexes.empty?
      end

      def inspect
        index_name = index ? index.name : "no-index"
        "<#{index_name} #{op} '#{value}'>"
      end

      def ==(value)
        @op ||= :eq
        set(value)
      end

      def =~(value)
        @op ||= :match
        set(value)
      end

      def >(value)
        @op ||= :gt
        set(value)
      end

      def >=(value)
        @op ||= :gte
        set(value)
      end

      def <(value)
        @op ||= :lt
        set(value)
      end

      def <=(value)
        @op ||= :lte
        set(value)
      end

      def between(min, max)
        @op ||= :between
        set(min, max)
      end

      private
      def set(*values)
        # Find the appropriate index to use
        @index = @available_indexes.find do |index|
          index.valid_op?(@op)
        end

        if @index.nil?
          ::Kernel.raise "No available index for '#{@name}' using '#{@op}'"
        end

        @values ||= values.map { |value| maybe_cast(value) }
        self
      end

      # Failsafe to munge types into a type we want
      def maybe_cast(value)
        if defined?(::ActiveSupport::TimeWithZone) && ::ActiveSupport::TimeWithZone === value
          value.to_time
        else
          value
        end
      end
    end

    private_constant :Collector
  end
end
