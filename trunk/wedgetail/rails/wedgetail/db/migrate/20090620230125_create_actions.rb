class CreateActions < ActiveRecord::Migration
  def self.up
    create_table :actions do |t|
      t.string :result_ref
      t.date :test_date
      t.string :action_code
      t.text :comment
      t.string :patient_ref
      t.boolean :last_flag

      t.timestamps
    end
  end

  def self.down
    drop_table :actions
  end
end
