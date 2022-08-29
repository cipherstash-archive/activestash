module ActiveStash
  class Assess
    # @private
    class ColumnNameRules
      ERR_PII = "AS0001"
      ERR_PHI = "AS0002"
      ERR_FINANCIAL = "AS0003"
      ERR_AUTH = "AS0004"

      RULES = [
        { name: 'last_name', display_name: 'names', column_names: %w[name fname firstname lastname lname surname], error_code: ERR_PII },
        { name: 'phone', display_name: 'phone numbers', column_names: %w[phone phonenumber], error_code: ERR_PII },
        { name: 'date_of_birth', display_name: 'dates of birth', column_names: %w[dateofbirth birthday dob], error_code: ERR_PII },
        { name: 'address', display_name: 'addresses', column_names: %w[address city state county country zip zipcode postalcode postcode postal], error_code: ERR_PII },
        { name: 'oauth_token', display_name: 'OAuth tokens', column_names: %w[accesstoken refreshtoken], error_code: ERR_AUTH },
        { name: 'email', display_name: 'emails', column_names: ['email'], error_code: ERR_PII },
        { name: 'ip_address', display_name: 'IP addresses', column_names: %w[ip ipaddress], error_code: ERR_PII },
        { name: 'credit_card_number', display_name: 'credit card numbers', column_names: %w[ccn creditcardnumber], error_code: ERR_FINANCIAL },
        { name: 'social_security_number', display_name: 'social security numbers', column_names: %w[ssn socialsecuritynumber], error_code: ERR_PII },
        { name: 'gender', display_name: 'genders', column_names: ['gender'], error_code: ERR_PII },
        { name: 'nationality', display_name: 'nationalities', column_names: ['nationality'], error_code: ERR_PII },
        { name: 'tax_file_number', display_name: 'tax file numbers', column_names: %w[tfn taxfilenumber], error_code: ERR_FINANCIAL },
        { name: 'medicare_number', display_name: 'medicare numbers', column_names: ['medicarenumber'], error_code: ERR_PHI },
      ]

      def self.check(field_names)
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
