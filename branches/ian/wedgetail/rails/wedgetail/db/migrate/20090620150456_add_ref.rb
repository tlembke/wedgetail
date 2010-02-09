class AddRef < ActiveRecord::Migration
  def self.up
    add_column :results, :result_ref, :string
  end

  def self.down
    remove_column :results, :results_ref
  end
end
