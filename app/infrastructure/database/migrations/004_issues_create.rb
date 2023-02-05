# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:issues) do
      primary_key :id
      foreign_key :project_id, :projects

      Integer     :origin_id, unique: true
      String     :node_id, unique: true
      String      :url, unique: true, null: false
      String      :title, null: false
      Integer     :number, null: false
      String      :type, null: false

      DateTime :created_at
      DateTime :updated_at
    end
  end
end