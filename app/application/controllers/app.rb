# frozen_string_literal: true


require_relative "../../../init.rb"

module CodePraise
  # Web App
  class App
    def self.run

      url = 'https://github.com/thoughtbot/factory_bot'
      owner_name, project_name = url.split('/')[-2..-1]

      result = Service::CollectProjectInfo.new.call(
        owner_name: owner_name, project_name: project_name
      )
    end

    run
  end
end