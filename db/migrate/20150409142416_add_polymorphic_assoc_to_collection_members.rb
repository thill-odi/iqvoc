class AddPolymorphicAssocToCollectionMembers < ActiveRecord::Migration
  def up
    add_column :collection_members, :target_type, :string, after: :target_id

    migrate_collection_members
  end

  def down
    remove_column :collection_members, :target_type
  end

  private

  def migrate_collection_members
    concept_query = "SELECT cm.id, c.type FROM collection_members cm JOIN concepts c ON cm.target_id = c.id"

    collection_member_concept_rows = select_rows(concept_query)

    collection_member_concept_rows.each do |id, target_type|
      execute "UPDATE collection_members SET target_type = '#{target_type}' WHERE id = '#{id}'"
    end
  end

end
