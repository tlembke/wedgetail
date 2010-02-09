class AddPoster < ActiveRecord::Migration
  def self.up
    add_column :results, :posted_by, :string
  end

  def self.down
    remove_column :results, :posted_by
  end
end
