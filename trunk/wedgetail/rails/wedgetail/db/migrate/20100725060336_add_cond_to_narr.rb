class AddCondToNarr < ActiveRecord::Migration
    def self.up
      add_column :narratives, :condition, :integer, :default => 0
    end

    def self.down
      remove_column :narratives, :condition
    end

end
