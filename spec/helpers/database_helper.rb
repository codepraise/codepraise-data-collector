# frozen_string_literal: true

# Helper to clean database during test runs
class DatabaseHelper
  def self.wipe_database
    # Ignore foreign key constraints when wiping tables
    CodePraise::App.DB.run('PRAGMA foreign_keys = OFF')
    CodePraise::Database::ProjectOrm.map(&:destroy)
    CodePraise::Database::MemberOrm.map(&:destroy)
    CodePraise::App.DB.run('PRAGMA foreign_keys = ON')
  end
end
