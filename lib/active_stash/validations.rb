module ActiveStash
  module Validations
     class UniquenessValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      if record.class.query(attribute => value).exists?
        record.errors.add(attribute, options[:message] || "already exists")
      end
    end
  end
  end
end
