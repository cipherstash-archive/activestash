module ActiveStash
  class QueryDSL
    class Field
      attr_reader :index, :value, :op

      def initialize(name, available_indexes)
        @name = name
        @available_indexes = available_indexes
        raise "No indexes available for '#{name}'" if @available_indexes.empty?
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

      def set(value)
        # Find the appropriate index to use
        @index = @available_indexes.find do |index|
          index.valid_op?(@op)
        end

        if @index.nil?
          raise "No available index for '#{@name}' using '#{@op}'"
        end

        @value ||= value
        self
      end
    end

    class ConstraintHelper
      attr_reader :fields

      def inspect
        "<Constraints: " + fields.map(&:inspect).join(" AND ") + ">"
      end

      def initialize(stash_indexes)
        @fields = []
        @stash_indexes = stash_indexes
      end

      def method_missing(name, *args)
        Field.new(name, @stash_indexes.on(name)).tap do |field|
          @fields << field
        end
      end

      def add_hash(fields)
        fields.map do |(field_name, value)|
          field = Field.new(field_name, @stash_indexes.on(field_name))
          @fields << (field == value)
        end
      end

      def build
        @fields.map(&:to_hash)
      end
    end

    def initialize(model)
      @model = model
      @constraints = ConstraintHelper.new(model.stash_indexes)
    end

    def build_query(*args)
      str, opts =
        case args.length
          when 2 then args
          when 1 then String === args[0] ? [args[0], {}] : [nil, args[0]]
          when 0 then [nil, {}]
        else
          raise NameError, "build_query must take 0, 1 or 2 arguments"
        end

      #TODO: @constraints.merge!(all: str) if str
      @constraints.add_hash(opts[:where]) if opts[:where]
      @order = opts[:order] if opts[:order]

      if block_given?
        yield @constraints
      end

      @constraints # TODO: Collapse ConstraintHelper and return self here
    end

    # TODO: call this map_and_validate!
    # Check that the indexes exist
    # and set the names of the indexes on the fields
    # Alternatively, we pass the stash_indexes to the constraint helper and field
    # and check things as they are added - this way we can keep the hash structure
    def validate!
      # TODO: Move this to the constraints class?
      @constraints.build.each do |constraint|
        op, field, value = constraint.values_at(:op, :field, :value)

        indexes_for_field = @model.stash_indexes.on(field)
        puts "indexes_for_field = #{indexes_for_field}"
        valid_indexes = indexes_for_field.detect do |index|
          index.valid_op?(op)
        end

        unless field == :all # FIXME: Remove this and make sure an all index has been generated
          raise "No valid indexes for query on #{field} (#{op})" unless valid_indexes
        end
      end

      self
    end
  end
end
