# frozen_string_literal: true

require 'dry/transaction'

module CodePraise
  module Service
    # Transaction to store project from Github API to database
    class CollectProjectInfo
      include Dry::Transaction

      step :find_project
      step :update_project

      private

      DB_ERR_MSG = 'Having trouble accessing the database'
      GH_NOT_FOUND_MSG = 'Could not find that project on Github'

      # Expects input[:owner_name] and input[:project_name]
      def find_project(input)
        input[:project] = project_from_github(input)
        Success(input)
      rescue StandardError => e
        puts e.full_message
        Failure(Value::Result.new(status: :not_found, message: e.to_s))
      end

      def update_project(input)
        project = if project_in_database(input)
                    Repository::For.entity(input[:project]).update(input[:project])
                  else
                    Repository::For.entity(input[:project]).create(input[:project])
                  end

        Success(Value::Result.new(status: :updated, message: project))
      rescue StandardError => e
        puts e.backtrace.join("\n")
        Failure(Value::Result.new(status: :internal_error, message: DB_ERR_MSG))
      end

      # following are support methods that other services could use

      def project_from_github(input)
        Github::ProjectMapper
          .new(App.config.GITHUB_TOKEN)
          .find(input[:owner_name], input[:project_name])
      rescue StandardError => e
        raise GH_NOT_FOUND_MSG
      end

      def project_in_database(input)
        Repository::For.klass(Entity::Project)
          .find_full_name(input[:owner_name], input[:project_name])
      end
    end
  end
end
