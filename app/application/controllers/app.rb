# frozen_string_literal: true
require 'pry'

module CodePraise
  # Web App
  class App
    def self.run

      ('a'..'z').each do |letter|
        (1..200).each do |number|
          sleep 2
          result = Service::CollectGems.new.call(query: letter, page: number)
          if result.failure?
            puts "停止於 letter: #{letter}, page: #{number}"
            break
          end
        end
      end
    
    rescue StandardError => e
      puts e.inspect + '\n' + e.backtrace
    end

    def self.single
      repo_uri = 'https://github.com/aws/aws-sdk-ruby'
      gem = Repository::For.klass(Entity::Gem).find_repo_uri(repo_uri)
      result = Service::CollectProjectInfo.new.call(gem: gem)
      raise(result.failure.message) unless result.success?
    rescue StandardError => e
      puts e.message
    end

    def self.export
      result = Service::GetProjectsInfo.new.call
      projects = result.value!.message

      CSV.open("data.csv", "w") do |csv|
        # Write the header row
        csv << %w[id origin_id full_name name http_url age lifetime downloads pulls issues contributors project_start project_last_maintain]

        # Write the data rows
        projects.each do |project|
          csv << [project.id,
                  project.origin_id,
                  project.full_name,
                  project.name,
                  project.http_url,
                  project.age,
                  project.lifetime,
                  project.downloads,
                  project.pulls,
                  project.issues,
                  project.contributors,
                  project.project_start,
                  project.project_last_maintain]
        end
      end
    rescue StandardError => e
      puts e.inspect + '\n' + e.backtrace
    end
  end
end