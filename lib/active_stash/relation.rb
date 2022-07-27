require_relative "relation_help/compatibility"

module ActiveStash
  class Relation < ::ActiveRecord::Relation
    include ActiveStash::RelationHelp::Compatability

    # TODO: Add count aggregate support
    stash_unsupported(:where, :count)
    stash_wrap(:select, :all, :includes, :joins, :annotate)

    def initialize(scope)
      @klass = scope
      @scope = scope
    end

    def query(*args, &block)
      @query = QueryBuilder.build_query(@klass, *args, &block)
      self
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

    def stash_ids
      if stash_query?
        load_stash_ids_if_needed
        @stash_ids
      else
        raise "Can't request stash IDs on a non-stash query"
      end
    end

    def order(*args)
      @stash_order = process_order_args(*args)
      self
    end

    def load
      if stash_query?
        return @records if @loaded

        load_stash_ids_if_needed

        relation = @scope.where(stash_id: @stash_ids)
        relation = relation.in_order_of(:stash_id, @stash_ids) if @stash_order
        @loaded = true
        @records = relation.load
      else
        super
      end
    end

    def stash_query?
      @query || @stash_order
    end

    def inspect
      @scope.inspect
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

    private

    def load_stash_ids_if_needed
      return unless @stash_ids.nil?

      @klass.collection.query(limit: self.limit_value, offset: self.offset_value) do |q|
        (@stash_order || []).each do |ordering|
          q.order_by(ordering[:index_name], ordering[:direction])
        end

        @query.constraints.each do |constraint|
          q.add_constraint(
            constraint.index.name,
            constraint.op.to_s,
            *constraint.values
          )
        end
      end.records.map(&:uuid).tap do |ids|
        @stash_ids = ids
      end
    end
  end
end
