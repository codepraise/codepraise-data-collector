# frozen_string_literal: true

require 'dry/transaction'

module CodePraise
  module Service
    # Transaction to store project from Github API to database
    class GetProjectsInfo
      include Dry::Transaction

      step :retrieve_projects

      private

      def retrieve_projects(input)
        project = Repository::For.klass(Entity::Project).find_id(input[:id])
        gem_repo = Repository::For.klass(Entity::Gem)
        gem = gem_repo.find_repo_uri(project.http_url) || gem_repo.find_name(project.name)

        result = OpenStruct.new(
                  id: project.id,
                  origin_id: project.origin_id,
                  full_name: project.fullname,
                  name: project.name,
                  http_url: project.http_url,
                  age: ((DateTime.now - DateTime.parse(project.project_start)).to_i + 1) / 365.0,
                  lifetime: ((DateTime.parse(project.project_last_maintain) - DateTime.parse(project.project_start)).to_i + 1) / 365.0,
                  downloads: gem.downloads,
                  pulls: project.issues.select { |issue| issue.type == 'pull_request' }.count,
                  issues: project.issues.select { |issue| issue.type == 'issue' }.count,
                  contributors: project.contributors.count,
                  project_start: DateTime.parse(project.project_start).strftime('%Y-%m-%d'),
                  project_last_maintain: DateTime.parse(project.project_last_maintain).strftime('%Y-%m-%d')
                 )

        Success(Value::Result.new(status: :ok, message: result))
      rescue StandardError => e
        Failure(Value::Result.new(status: :internal_error, message: 'Error when getting project info'))
      end
    end
  end
end
