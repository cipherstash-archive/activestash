module ActiveStash
  class Assess
    class << self
      def run
        assessment = models.map { |model|
          [model.name, suspected_personal_data(model)]
        }
        assessment.each do |model, fields|
          if fields.size > 0
            puts "#{model}:"
            fields.each do |field, evidences|
              puts "- #{model}.#{field} is suspected to contain: #{evidences.map { |e| e[:display_name] }.join(", ")}"
            end
            puts
          end
        end
        write_report(assessment, assessment_path)
      end

      private

      def model_fields(model)
        model.column_names
      end

      def models
        Rails.application.eager_load!
        ApplicationRecord.descendants
      end

      def secured_by_active_stash?(fields)
        fields.include?("stash_id")
      end

      def name_rules
        [
          { name: "name", display_name: "names", column_names: ["name"] },
          { name: "last_name", display_name: "last names", column_names: ["lastname", "lname", "surname"] },
          { name: "phone", display_name: "phone numbers", column_names: ["phone", "phonenumber"] },
          { name: "date_of_birth", display_name: "dates of birth", column_names: ["dateofbirth", "birthday", "dob"] },
          { name: "postal_code", display_name: "postal codes", column_names: ["zip", "zipcode", "postalcode", "postcode"] },
          { name: "oauth_token", display_name: "OAuth tokens", column_names: ["accesstoken", "refreshtoken"] },
        ]
      end

      def suspected_personal_data(model)
        # TODO: downcase and remove underscores
        # TODO: could also include whether or not field is encrypted in report

        fields = model_fields(model)
        matches = {}
        fields.each do |field|
          # TODO: check if the offending column name is in the field name at all

          # TODO: how to handle false positives?
          # Name is a good example of having a high potential for a false positive. A name for a something like a "tags"
          # table prob isn't actually sensetive and there could be a lot of examples like that.
          #
          # Ideally you can run the task multiple times without it re-adding things that you've already marked as false
          # positives. This is nice for picking up new examples of PII

          suspects = name_rules.select { |rule| rule[:column_names].include?(field) }
          if suspects.size > 0
            matches[field] ||= []
            matches[field] << suspects
            matches[field].flatten!
          end
        end
        matches
      end

      def write_report(assessment, filename)
        report = {}
        assessment.each do |model, fields|
          fields.each do |field, reasons|
            display = reasons.map { |r| r[:display_name] }.join(", ")
            report[model] ||= []
            report[model] << { field: field, comment: "suspected to contain: #{display}" }
          end
        end

        File.open(filename, "w") { |file| file.write(report.to_yaml) }

        puts "Assessment written to: #{filename}"
      end

      def assessment_path
        Rails.root.join("active_stash_assessment.yml")
      end

      def read_report(filename)
        YAML.load(assessment_path.read)
      end
    end
  end
end
