require_relative "./assess/column_name_rules"

module ActiveStash
  # @private
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
              puts "- #{model}.#{field} is suspected to contain: #{evidences.map { |e| e[:display_name] }.join(", ")} (#{evidences.map{ |e| e[:error_code] }.uniq.join(", ")})"
            end
            puts
          end
        end

        error_codes = assessment.map { |model, fields| fields.values }
          .flatten
          .map {|e| e[:error_code] }
          .uniq

        puts "Online documentation:"
        puts "#{error_codes.map{ |e| "- https://docs.cipherstash.com/assess/checks##{e}"}.join("\n")}"
        puts

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

      def suspected_personal_data(model)
        # TODO: could also include whether or not field is encrypted in report

        fields = model_fields(model)
        ColumnNameRules.check(fields)
      end

      # Source file and line number could also be nice to report on
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
