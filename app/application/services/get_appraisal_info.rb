# frozen_string_literal: true

require 'dry/transaction'
require 'json'
require 'ostruct'

module CodePraise
  module Service
    # Transaction to store project from Github API to database
    class GetAppraisalInfo
      include Dry::Transaction

      step :appraise_project

      private

      def appraise_project(input)
        owner_name, project_name = input[:owner_name], input[:project_name]

        json = Gateway::Api.new(CodePraise::App.config).appraise(owner_name, project_name)
        @data = JSON.parse(json, object_class: OpenStruct)

        results = calculate_metric_for_folder(@data.content.folder)
        results['commits'] = @data.content.commits.count

        Success(Value::Result.new(status: :ok, message: results))
      rescue StandardError => e
        # binding.irb
        Failure(Value::Result.new(status: :internal_error, message: e.message || 'Error when getting appraisal info'))
      end

      def calculate_metric_for_file(file)
        total_line_credits = file.total_line_credits
        if total_line_credits.zero? || total_line_credits.nil?
          return {
            'readability' => 0,
            'code_smell' => 0,
            'cyclomatic_complexity' => 0,
            'abc_metric' => 0,
            'idiomaticity' => 0,
            'code_churn' => 0
          }
        end
        total_line_credits = total_line_credits.to_f

        readability = file.readability || 0
        code_smell = file.code_smells&.offenses&.count || 0
        cyclomatic_complexity = file.idiomaticity&.cyclomatic_complexity || 0
        abc_metric = file.complexity&.average || 0
        idiomaticity = file.idiomaticity&.offense_count || 0
        code_churn = calculate_code_churn_for_file(file, total_line_credits)

        {
          'readability' => (readability / total_line_credits * code_churn) || 0,
          'code_smell' => (code_smell / total_line_credits * code_churn) || 0,
          'cyclomatic_complexity' => (cyclomatic_complexity / total_line_credits * code_churn) || 0,
          'abc_metric' => (abc_metric / total_line_credits * code_churn) || 0,
          'idiomaticity' => (idiomaticity / total_line_credits * code_churn) || 0,
          'code_churn' => code_churn
        }
      end

      def calculate_metric_for_folder(folder)
        total_files = 0
        total_readability = 0
        total_code_smell = 0
        total_cyclomatic_complexity = 0
        total_abc_metric = 0
        total_idiomaticity = 0
        total_code_churn = 0

        if folder.any_base_files?
          folder.base_files.each do |file|
            metrics = calculate_metric_for_file(file)
            total_files += 1
            total_readability += metrics['readability']
            total_code_smell += metrics['code_smell']
            total_cyclomatic_complexity += metrics['cyclomatic_complexity']
            total_abc_metric += metrics['abc_metric']
            total_idiomaticity += metrics['idiomaticity']
            total_code_churn += metrics['code_churn']
          end
        end

        if folder.any_subfolders?
          folder.subfolders.each do |subfolder|
            metrics = calculate_metric_for_folder(subfolder)
            total_files += 1
            total_readability += metrics['total_readability']
            total_code_smell += metrics['total_code_smell']
            total_cyclomatic_complexity += metrics['total_cyclomatic_complexity']
            total_abc_metric += metrics['total_abc_metric']
            total_idiomaticity += metrics['total_idiomaticity']
            total_code_churn += metrics['total_code_churn']
          end
        end

        {
          'total_files' => total_files,
          'total_readability' => total_readability,
          'total_code_smell' => total_code_smell,
          'total_cyclomatic_complexity' => total_cyclomatic_complexity,
          'total_abc_metric' => total_abc_metric,
          'total_idiomaticity' => total_idiomaticity,
          'total_code_churn' => total_code_churn,
          'readability' => total_readability / total_files,
          'code_smell' => total_code_smell / total_files,
          'cyclomatic_complexity' => total_cyclomatic_complexity / total_files,
          'abc_metric' => total_abc_metric / total_files,
          'idiomaticity' => total_idiomaticity / total_files,
          'code_churn' => total_code_churn
        }
      end

      def calculate_code_churn_for_file(file, total_line_credits)
        code_churn = 0
        filename = file.file_path.filename
        commits = @data.content.commits
        commits.each do |commit|
          file_changes = commit.file_changes
          file_changes.each do |file_change|
            if file_change.name.include?(filename)
              code_churn += (file_change.addition + file_change.deletion)
            end
          end
        end

        code_churn /= total_line_credits.to_f

        code_churn
      end
    end
  end
end
