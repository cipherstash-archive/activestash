require_relative "./assess"

if defined?(RSpec) && defined?(Rails)
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
      assessment = ActiveStash::Assess.read_report(assessment_path)
      assessment_entry = assessment.fetch(model.name, [])
        .map { |field| field[:field].to_sym }
        .reject { |name| model.encrypted_attributes.include?(name) }
    end
  end
end
