module ActiveStash
  class Assess
    # @private
    class ColumnNameRules
      RULES = [
        { name: 'last_name', display_name: 'names', column_names: %w[name fname firstname lastname lname surname], error_code: "AS0001" },
        { name: 'phone', display_name: 'phone numbers', column_names: %w[phone phonenumber], error_code: "AS0001" },
        { name: 'date_of_birth', display_name: 'dates of birth', column_names: %w[dateofbirth birthday dob], error_code: "AS0001" },
        { name: 'address', display_name: 'addresses', column_names: %w[address city state county country zip zipcode postalcode postcode postal], error_code: "AS0001" },
        { name: 'oauth_token', display_name: 'OAuth tokens', column_names: %w[accesstoken refreshtoken], error_code: "AS0001" },
        { name: 'email', display_name: 'emails', column_names: ['email'], error_code: "AS0001" },
        { name: 'ip_address', display_name: 'IP addresses', column_names: %w[ip ipaddress], error_code: "AS0001" },
        { name: 'credit_card_number', display_name: 'credit card numbers', column_names: %w[ccn creditcardnumber], error_code: "AS0001" },
        { name: 'social_security_number', display_name: 'social security numbers', column_names: %w[ssn socialsecuritynumber], error_code: "AS0001" },
        { name: 'gender', display_name: 'genders', column_names: ['gender'], error_code: "AS0001" },
        { name: 'nationality', display_name: 'nationalities', column_names: ['nationality'], error_code: "AS0001" },
        { name: 'tax_file_number', display_name: 'tax file numbers', column_names: %w[tfn taxfilenumber], error_code: "AS0001" },
        { name: 'medicare_number', display_name: 'medicare numbers', column_names: ['medicarenumber'], error_code: "AS0001" },
      ]

      class << self
        def check(field_names)
          # TODO: how to handle false positives?
          # Name is a good example of having a high potential for a false positive. A name for a something like a "tags"
          # table prob isn't actually sensetive and there could be a lot of examples like that.
          #
          # Ideally you can run the task multiple times without it re-adding things that you've already marked as false
          # positives. This is nice for picking up new examples of PII

          {}.tap do |matches|
            field_names.each do |field_name|
              suspects = RULES.select { |rule| rule[:column_names].include?(field_name.gsub("_", "")) }

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
