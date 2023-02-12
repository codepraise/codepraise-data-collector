# frozen_string_literal: true

module CodePraise
  module Repository
    # Repository for Gem Entities
    class Gems
      def self.all
        Database::GemOrm.all.map { |db_project| rebuild_entity(db_project) }
      end

      def self.find(entity)
        find_id(entity.id)
      end

      def self.find_id(id)
        db_record = Database::GemOrm.first(id: id)
        rebuild_entity(db_record)
      end

      def self.find_name(name)
        db_record = Database::GemOrm.first(name: name)
        rebuild_entity(db_record)
      end

      def self.find_repo_uri(repo_uri)
        db_record = Database::GemOrm.first(repo_uri: repo_uri)
        rebuild_entity(db_record)
      end

      def self.find_or_create(entity)
        find(entity) || create(entity)
      end

      def self.create(entity)
        Database::GemOrm.create(entity.to_attr_hash)
      end

      def self.update(entity)
        db_gem = Database::GemOrm.where(id: entity.id)
        db_gem.update(name: entity.name,
                      source_code_uri: entity.source_code_uri,
                      homepage_uri: entity.homepage_uri,
                      downloads: entity.downloads,
                      repo_uri: entity.repo_uri,
                      updated_at: Time.now)
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::Gem.new(
          id: db_record.id,
          name: db_record.name,
          source_code_uri: db_record.source_code_uri,
          homepage_uri: db_record.homepage_uri,
          downloads: db_record.downloads,
          repo_uri: db_record.repo_uri
        )
      end

      def self.rebuild_many(db_records)
        db_records.map do |db_gem|
          Gems.rebuild_entity(db_gem)
        end
      end
    end
  end
end
