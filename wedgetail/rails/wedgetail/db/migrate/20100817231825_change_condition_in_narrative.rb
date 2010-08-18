class ChangeConditionInNarrative < ActiveRecord::Migration
  def self.up
    rename_column :narratives, :condition, :condition_id
  end

  def self.down
    rename_column :narratives, :condition_id, :condition
  end
end
