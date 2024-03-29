module ActiveStash
  module Validations
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def validates_uniqueness_of(*attr_names)
        validates_with ActiveStash::Validations::UniquenessValidator, _merge_attributes(attr_names)
      end
    end

    class UniquenessValidator < ActiveRecord::Validations::UniquenessValidator
      # Uniqueness validator for encrypted fields.
      #
      # It relies on an exact index being present for the attribute (created by
      # default with `stash_index`)
      #
      # It's worth pointing out that this validation does not care of there is a
      # unique index on that field within the collection. This mirrors how
      # ActiveRecord works, which does not care if there is a unique index on
      # the field in the database in order for validates_uniqueness_of to work.
      #
      def validate_each(record, attribute, value)
        indexes_on_attribute = record.class.stash_indexes.on(attribute).select{|idx| [:exact, :range].include?(idx.type)}

        if indexes_on_attribute.length > 0
          result = record.class.query(attribute => value).first

          if (options[:case_sensitive] && result[attribute] == attribute) || result
            record.errors.add(attribute, options[:message] || "already exists")
          end
        else
          super
        end
      end
    end
  end
end
