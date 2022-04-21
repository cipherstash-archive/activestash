module ActiveStash
  # TODO: Only use this if Rails is loaded
  class StashRelation < ::ActiveRecord::Relation
    def query(*args, &block)
      @query = Query.build_query(@klass, *args, &block)
      self
    end

    def where(*args)
      if @query
        ActiveStash::Logger.warn("Where clause ignored as query was used instead")
      end
      super
    end

    def limit(value)
      @limit = value
      self
    end

    def order(*args)
      # @query.order = 
      self
    end

    def offset(value)
      @offset = value
      self
    end

    def load
      if @query
        # Call stash ruby client low-level API
        ids = @klass.collection.query(limit: @limit, offset: @offset) do |q|
          @query.constraints.each do |constraint|
            q.add_constraint(constraint.index.name, constraint.op.to_s, constraint.value)
          end
        end.records.map(&:id)
        
        # TODO
        #order ? relation.in_order_of(:stash_id, ids) : relation
        @records = @klass.where(stash_id: ids)
        @loaded = true
      else
        super
      end
    end
  end

  # Query DSL
  #
  # @private
  class Query
    attr_accessor :constraints
    attr_accessor :order
    attr_accessor :limit
    attr_accessor :offset

    # Build a query for the given model
    def self.build_query(model, *args)
      collector = Collector.new(model.stash_indexes)

      str, opts =
        case args.length
          when 2 then args
          when 1 then String === args[0] ? [args[0], {}] : [nil, args[0]]
          when 0 then [nil, {}]
        else
          raise NameError, "build_query must take 0, 1 or 2 arguments"
        end

      #TODO: @constraints.merge!(all: str) if str
      collector.add_hash(opts[:where]) if opts[:where]
      order = opts[:order] if opts[:order]

      if block_given?
        yield collector
      end

      new.tap do |query|
        query.constraints = collector.fields
        query.order = order
      end
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
        if defined?(::ActiveSupport::TimeWithZone && ::ActiveSupport::TimeWithZone === value)
          value.to_time
        else
          value
        end
      end
    end

    private_constant :Collector
  end
end
