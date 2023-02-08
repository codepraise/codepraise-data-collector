# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:gems) do
      primary_key :id

      String  :name, null: false, unique: true
      String  :source_code_uri, null: false
      String  :homepage_uri, null: false
      String  :repo_uri, null: false
      Integer :downloads, null: false

      DateTime :created_at
      DateTime :updated_at
    end
  end
end