class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
        t.string   "title"
        t.text     "description"
        t.integer  "goal_id", :default => 0,  :null => false
        t.string   "patient",      :default => ""
        t.string   "team",         :default => ""
        t.datetime "created_at"
        t.datetime "updated_at"
        t.integer  "active",       :default => 1
        t.integer  "parent",       :default => 0
        t.integer  "task_type",       :default => 0
      end
  end

  def self.down
    drop_table :tasks
  end
end
