# frozen_string_literal: true

require 'sequel'

module CodePraise
  module Database
    # Object-Relational Mapper for Issues
    class IssueOrm < Sequel::Model(:issues)
      many_to_one :project,
                  class: :'CodePraise::Database::ProjectOrm'

      plugin :timestamps, update_on_create: true
      plugin :association_dependencies

      def self.find_or_create(issue_info)
        first(number: issue_info[:number]) || create(issue_info)
      end
    end
  end
end
