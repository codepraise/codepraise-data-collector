# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:projects) do
      primary_key :id
      foreign_key :owner_id, :members

      Integer     :origin_id, unique: true
      String      :name
      String      :ssh_url
      String      :http_url
      Integer     :size
      Integer     :downloads
      String      :project_start
      String      :project_last_maintain

      DateTime :created_at
      DateTime :updated_at
    end
  end
end
