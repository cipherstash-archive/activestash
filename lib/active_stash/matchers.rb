require_relative "./assess"

if defined?(RSpec)
  RSpec::Matchers.define :encrypt_sensitive_fields do
    match do |model|
      unprotected(model).empty?
    end

    failure_message do |model|
      unprotected = unprotected(model)

      field_text =
        if unprotected.size > 1
          "fields"
        else
          "field"
        end

      "Unprotected sensitive #{field_text}: #{unprotected.join(", ")}"
    end

    def unprotected(model)
      assessment = ActiveStash::Assess.new.read_report
      assessment_entry = assessment.fetch(model.name, [])
        .map { |field| field[:field].to_sym }
        .reject { |field_name| encrypted?(model, field_name) }
    end

    def encrypted?(model, field_name)
      model.respond_to?(:encrypted_attributes) && model.encrypted_attributes.kind_of?(Array) && model.encrypted_attributes.include?(field_name)
    end
  end
end
