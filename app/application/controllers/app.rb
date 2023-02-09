# frozen_string_literal: true

module CodePraise
  # Web App
  class App
    def self.run
      Service::CollectGems.new.call(query: '*', amount: 70)
      gems = Repository::For.klass(Entity::Gem).all
      gems.each do |gem|
        puts "Getting info for #{gem.name}..."
        owner_name, project_name = gem.repo_uri.split('/')[-2..-1]
        Service::CollectProjectInfo.new.call(owner_name: owner_name, project_name: project_name, gem_name: gem.name)
      end

    rescue StandardError => e
      puts e.inspect + '\n' + e.backtrace
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