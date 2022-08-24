module ActiveStash
  class Assess
    # @private
    class NameRules
      RULES = [
        # TODO: names can probably be collapsed into one rule
        { name: 'name', display_name: 'names', column_names: ['name'] },
        { name: 'last_name', display_name: 'last names', column_names: %w[lastname lname surname] },
        { name: 'phone', display_name: 'phone numbers', column_names: %w[phone phonenumber] },
        { name: 'date_of_birth', display_name: 'dates of birth', column_names: %w[dateofbirth birthday dob] },
        { name: 'postal_code', display_name: 'postal codes', column_names: %w[zip zipcode postalcode postcode] },
        { name: 'oauth_token', display_name: 'OAuth tokens', column_names: %w[accesstoken refreshtoken] }
      ]

      class << self
        def check(field_names)
          # TODO: downcase and remove underscores

          # TODO: check if the offending column name is in the field_name name at all (vs the full name)

          # TODO: how to handle false positives?
          # Name is a good example of having a high potential for a false positive. A name for a something like a "tags"
          # table prob isn't actually sensetive and there could be a lot of examples like that.
          #
          # Ideally you can run the task multiple times without it re-adding things that you've already marked as false
          # positives. This is nice for picking up new examples of PII

          {}.tap do |matches|
            field_names.each do |field_name|
              suspects = RULES.select { |rule| rule[:column_names].include?(field_name) }

              if suspects.size > 0
                matches[field_name] ||= []
                matches[field_name] << suspects
                matches[field_name].flatten!
              end
            end
          end
        end
      end
    end
  end
end
