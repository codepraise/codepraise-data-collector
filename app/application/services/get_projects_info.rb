# frozen_string_literal: true

require 'dry/transaction'

module CodePraise
  module Service
    # Transaction to store project from Github API to database
    class GetProjectsInfo
      include Dry::Transaction

      step :retrieve_all_projects

      private

      def retrieve_all_projects
        projects = Repository::For.klass(Entity::Project).all
        gem_repo = Repository::For.klass(Entity::Gem)
        results = []

        projects.each do |project|
          results.append(
            OpenStruct.new(
              id: project.id,
              origin_id: project.origin_id,
              full_name: project.fullname,
              name: project.name,
              http_url: project.http_url,
              age: (DateTime.now - DateTime.parse(project.project_start)).to_i,
              lifetime: (DateTime.parse(project.project_last_maintain) - DateTime.parse(project.project_start)).to_i,
              downloads: gem_repo.find_repo_uri(project.http_url).downloads,
              pulls: project.issues.select { |issue| issue.type == 'pull_request' }.count,
              issues: project.issues.select { |issue| issue.type == 'issue' }.count,
              contributors: project.contributors.count,
              project_start: project.project_start,
              project_last_maintain: project.project_last_maintain
            )
          )
        rescue StandardError => e
          binding.irb
          puts e.backtrace.join("\n")
        end

        Success(Value::Result.new(status: :ok, message: results))
      rescue StandardError => e
        puts e.backtrace.join("\n")
        Failure(Value::Result.new(status: :internal_error, message: DB_ERR_MSG))
      end
    end
  end
end
