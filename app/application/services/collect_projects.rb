# frozen_string_literal: true

require 'dry/transaction'

module CodePraise
  module Service
    # Transaction to store project from Github API to database
    class CollectProjects
      include Dry::Transaction

      step :search_project
      step :store_project

      private

      DB_ERR_MSG = 'Having trouble accessing the database'
      GH_NOT_FOUND_MSG = 'Could not find that project on Github'

      # Expects input[:owner_name] and input[:project_name]
      def search_project(input)
        puts "Getting projects from Github..."
        input[:projects] = projects_from_github(input)
        Success(input)
      rescue StandardError => e
        puts e.full_message
        Failure(Value::Result.new(status: :not_found, message: e.to_s))
      end

      def store_project(input)
        projects = input[:projects].each do |project|
          puts "Storing #{project.fullname} in database..."
          proj = if project_in_database(project)
                      Repository::For.entity(project).update(project)
                    else
                      Repository::For.entity(project).create(project)
                    end
        end

        Success(Value::Result.new(status: :stored, message: nil))
      rescue StandardError => e
        puts e.backtrace.join("\n")
        Failure(Value::Result.new(status: :internal_error, message: DB_ERR_MSG))
      end

      # following are support methods that other services could use

      def projects_from_github(input)
        Github::ProjectMapper
          .new(App.config.GITHUB_TOKEN)
          .search(input[:query], input[:order])
      rescue StandardError => e
        puts e.full_message
        raise GH_NOT_FOUND_MSG
      end

      def project_in_database(project)
        Repository::For.klass(Entity::Project)
          .find_full_name(project.owner.username, project.name)
      end
    end
  end
end
