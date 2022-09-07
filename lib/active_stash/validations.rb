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
      # It relies on an exact index being present for the
      # attribute (created by default with `stash_index`)
      #
      def validate_each(record, attribute, value)
        puts "validate_each 1"
        indexes_on_attribute = record.class.stash_indexes.on(attribute)
        puts "indexes on attribute #{attribute} #{indexes_on_attribute}"

        if indexes_on_attribute.length > 0
          puts "validate_each 2"
          result = record.class.query(attribute => value).first
          puts "validate_each 2.1 #{result}"

          if (options[:case_sensitive] && result[attribute] == attribute) || result
            puts "validate_each 3"
            record.errors.add(attribute, options[:message] || "already exists")
          end
        else
          super
        end
      end
    end
  end
end
