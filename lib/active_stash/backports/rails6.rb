module ActiveStash
  module Backports
    module Rails6

      def self.install
        ActiveRecord::ConnectionAdapters::AbstractAdapter.send :include, AbstractAdapterMonkeyPatch
        ActiveRecord::Relation.send :include, RelationMonkeyPatch
      end

      module RelationMonkeyPatch
        # This code is pilfered from Rails 7
        def in_order_of(column, values)
          klass.disallow_raw_sql!([column], permit: connection.column_name_with_order_matcher)
          return spawn.none! if values.empty?

          references = column_references([column])
          self.references_values |= references unless references.empty?

          values = values.map { |value| type_caster.type_cast_for_database(column, value) }
          arel_column = column.is_a?(Symbol) ? order_column(column.to_s) : column

          spawn
            .order!(connection.field_ordered_value(arel_column, values))
            .where!(arel_column.in(values))
        end

        def column_references(order_args)
          references = order_args.flat_map do |arg|
            case arg
            when String, Symbol
              arg
            when Hash
              arg.keys.map do |key|
                key if key.is_a?(String) || key.is_a?(Symbol)
              end
            end
          end
          references.map! { |arg| arg =~ /^\W?(\w+)\W?\./ && $1 }.compact!
          references
        end
      end

      module AbstractAdapterMonkeyPatch
        def field_ordered_value(column, values) # :nodoc:
          node = Arel::Nodes::Case.new(column)
          values.each.with_index(1) do |value, order|
            node.when(value).then(order)
          end

          Arel::Nodes::Ascending.new(node.else(values.length + 1))
        end
      end
    end
  end
end