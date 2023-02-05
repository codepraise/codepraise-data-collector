# frozen_string_literal: true

require_relative 'members'

module CodePraise
  module Repository
    # Repository for Issue Entities
    class Issues
      def self.all
        Database::IssueOrm.all.map { |db_project| rebuild_entity(db_project) }
      end

      def self.find(entity)
        find_origin_id(entity.origin_id)
      end

      def self.find_id(id)
        db_record = Database::IssueOrm.first(id: id)
        rebuild_entity(db_record)
      end

      def self.find_origin_id(origin_id)
        db_record = Database::IssueOrm.first(origin_id: origin_id)
        rebuild_entity(db_record)
      end

      def self.find_or_create(entity)
        find(entity) || create(entity)
      end

      def self.create(entity)
        Database::IssueOrm.create(entity.to_attr_hash)
      end

      def self.update(entity)
        db_issue = Database::IssueOrm.where(origin_id: entity.origin_id)
        db_issue.update(origin_id: entity.origin_id,
                        node_id: entity.node_id,
                        url: entity.url,
                        title: entity.title,
                        number: entity.number,
                        type: entity.type,
                        updated_at: Time.now)
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::Issue.new(
          id: db_record.id,
          origin_id: db_record.origin_id,
          node_id: db_record.node_id,
          url: db_record.url,
          title: db_record.title,
          number: db_record.number,
          type: db_record.type
        )
      end

      def self.rebuild_many(db_records)
        db_records.map do |db_issue|
          Issues.rebuild_entity(db_issue)
        end
      end
    end
  end
end
