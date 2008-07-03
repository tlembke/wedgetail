class CreatePrefs < ActiveRecord::Migration
  def self.up
    create_table :prefs do |t|
      t.column :server_id,    :string
      t.column :time_out,   :integer
      t.column :use_ssl, :integer
    end
  end

  def self.down
    drop_table :prefs
  end
end
