class ChangeResultRef < ActiveRecord::Migration
  def self.up
    rename_column :result_tickets, :result_ref, :request_set
    rename_column :actions, :result_ref, :request_set
  end

  def self.down
    rename_column :result_tickets, :request_set, :result_ref
    rename_column :actions, :request_set, :result_ref
  end
end
