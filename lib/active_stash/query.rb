module ActiveStash
  module RelationCompatability
    def self.included(base)
      base.extend ClassMethods
    end

    def unsupported!(method_name)
      # TODO: Use a proper class
      raise "'#{method_name}' is unsupported when used with encrypted queries or sorts"
    end

    module ClassMethods
      def stash_wrap(*names)
        names.each do |name|
          define_method(name) do |*args|
            @scope = @scope.send(name, *args)
            self
          end
        end
      end

      def stash_unsupported(*names)
        names.each do |name|
          define_method(name) do |*args|
            if stash_query?
              unsupported!(name)
            else
              super
            end
          end
        end
      end
    end
  end

  class StashRelation < ::ActiveRecord::Relation
    include RelationCompatability

    stash_wrap(:select, :all)
    stash_unsupported(:where)

    def initialize(model)
      @klass = model
      @scope = model
    end

    def query(*args, &block)
      @query = Query.build_query(@klass, *args, &block)
      self
    end

    def _where(*args)
      if stash_query?
        unsupported!(__method__)
      else
        super
      end
    end

    def count(_column_name = nil)
      if loaded?
        @records.size
      else
        # TODO: Make this include an aggregate on stash or just count
        puts "Calling count"
        10
      end
    end

    def limit(value)
      @limit = value
      self
    end

    def offset(value)
      @offset = value
      self
    end

    def first
      if stash_query?
        limit(1)
        self.load[0]
      else
        super
      end
    end

    def last(n = nil)
      if stash_query?
        n ? self.load.last(n) : self.load.last
      else
        super
      end
    end

    def order(*args)
      @stash_order = process_order_args(*args)
      self
    end

    def load
      if stash_query?
        return @records if @loaded

        # Call stash ruby client low-level API
        ids = @klass.collection.query(limit: @limit, offset: @offset) do |q|
          (@stash_order || []).each do |ordering|
            q.order_by(ordering[:index_name], ordering[:direction])
          end

          @query.constraints.each do |constraint|
            q.add_constraint(constraint.index.name, constraint.op.to_s, constraint.value)
          end
        end.records.map(&:id)
        
        relation = @scope.where(stash_id: ids)
        relation = relation.in_order_of(:stash_id, ids) if @stash_order
        @loaded = true
        @records = relation.load
      else
        super
      end
    end

    def stash_query?
      @query || @stash_order
    end

    protected
    def process_order_args(*args)
      args.flat_map do |field_or_hash|
        if Hash === field_or_hash
          field_or_hash.map do |(field, direction)|
            range_index = @klass.stash_indexes.on(field.to_s).find do |index|
              index.type == :range
            end

            if range_index.nil?
              raise "Unable to order by '#{field}' as there are no range indexes defined for it"
            end
            { index_name: range_index.name, direction: direction.upcase.to_sym }
          end
        else
          process_order_args(field_or_hash => :ASC)
        end
      end
    end
  end

  # Query DSL
  #
  # @private
  class Query
    attr_reader :constraints

    def initialize(constraints)
      @constraints = constraints
    end

    # Build a query for the given model
    def self.build_query(model, constraint = {})
      collector = Collector.new(model.stash_indexes)

      case constraint
        when Hash
          collector.add_hash(constraint)
        when String
          constraints.add_hash(all: constraint)
      end

      if block_given?
        yield collector
      end

      new(collector.fields)
    end

    class Collector < BasicObject
      attr_reader :fields

      def initialize(stash_indexes)
        @fields = []
        @stash_indexes = stash_indexes
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

    class Field < BasicObject
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

      private
      def set(value)
        # Find the appropriate index to use
        @index = @available_indexes.find do |index|
          index.valid_op?(@op)
        end

        if @index.nil?
          raise "No available index for '#{@name}' using '#{@op}'"
        end

        @value ||= maybe_cast(value)
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
