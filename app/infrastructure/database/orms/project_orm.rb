# frozen_string_literal: true

require 'sequel'

module CodePraise
  module Database
    # Object Relational Mapper for Project Entities
    class ProjectOrm < Sequel::Model(:projects)
      many_to_one :owner,
                  class: :'CodePraise::Database::MemberOrm'

      many_to_many :contributors,
                   class: :'CodePraise::Database::MemberOrm',
                   join_table: :projects_members,
                   left_key: :project_id, right_key: :member_id

      one_to_many :issues,
                  class: :'CodePraise::Database::IssueOrm',
                  key: :project_id

      plugin :timestamps, update_on_create: true
      plugin :association_dependencies
      add_association_dependencies owner: :delete, contributors: :nullify, issues: :delete

      def fullname
        "#{owner.username}/#{name}"
      end
    end
  end
end
