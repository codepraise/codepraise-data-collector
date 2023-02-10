# frozen_string_literal: true

# Helper to clean database during test runs
class DatabaseHelper
  def self.wipe_database
    # Ignore foreign key constraints when wiping tables
    CodePraise::App.DB.run("SET session_replication_role = 'replica';")
    CodePraise::Database::ProjectOrm.map(&:destroy)
    CodePraise::Database::MemberOrm.map(&:destroy)
    CodePraise::App.DB.run("SET session_replication_role = 'origin';")
  end

  def self.reset_database
    CodePraise::Api.DB.run("DROP SCHEMA public CASCADE;
      CREATE SCHEMA public;
      GRANT ALL ON SCHEMA public TO postgres;
      GRANT ALL ON SCHEMA public TO public;
      COMMENT ON SCHEMA public IS 'standard public schema';")
  end
end
