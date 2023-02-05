# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:projects_issues) do
      primary_key [:project_id, :issue_id]
      foreign_key :project_id, :projects
      foreign_key :issue_id, :issues

      index [:project_id, :issue_id]
    end
  end
end
