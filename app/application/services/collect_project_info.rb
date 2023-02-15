# frozen_string_literal: true

require 'dry/transaction'

module CodePraise
  module Service
    # Transaction to store project from Github API to database
    class CollectProjectInfo
      include Dry::Transaction

      step :find_project
      step :store_project

      private

      DB_ERR_MSG = 'Having trouble accessing the database'
      GH_NOT_FOUND_MSG = 'Could not find that project on Github'

      # Expects input[:owner_name] and input[:project_name]
      def find_project(input)
        gem = input[:gem].nil? ? raise('No gem provided') : input[:gem]
        input[:owner_name], input[:project_name] = gem.repo_uri.split('/')[-2..-1]
        puts "Getting project #{input[:owner_name]}/#{input[:project_name]} from Github..."

        db_proj = project_in_database(input)
        input[:project] = project_from_github(input) if db_proj.nil?

        Success(input)
      rescue CodePraise::Github::Api::Response::Forbidden => e
        raise e
      rescue CodePraise::Github::Api::Response::NotFound => e
        raise e
      rescue StandardError => e
        Failure(Value::Result.new(status: :cannot_process, message: e.message))
      end

      def store_project(input)
        puts "Storing project #{input[:owner_name]}/#{input[:project_name]} in database..."
        project = Repository::For.entity(input[:project]).update_or_create(input[:project]) if input[:project]
        appraise_project(input[:owner_name], input[:project_name]) if project

        Success(Value::Result.new(status: :stored, message: project))
      rescue StandardError => e
        Failure(Value::Result.new(status: :internal_error, message: DB_ERR_MSG))
      end

      # following are support methods that other services could use

      def project_from_github(input)
        Github::ProjectMapper
          .new(App.config.GITHUB_TOKEN)
          .find(input[:owner_name], input[:project_name])
      end

      def project_in_database(input)
        Repository::For.klass(Entity::Project)
          .find_full_name(input[:owner_name], input[:project_name])
      rescue StandardError => e
        raise DB_ERR_MSG
      end

      def appraise_project(owner_name, project_name)
        puts "Notify worker to appraise project #{owner_name}/#{project_name}..."
        Gateway::Api.new(CodePraise::App.config).appraise(owner_name, project_name)
      end
    end
  end
end
