class AddCreatedBy < ActiveRecord::Migration
  def self.up
    rename_column :narratives, :user_id, :created_by
    change_column :narratives, :created_by, :string
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
