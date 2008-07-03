class Firewall < ActiveRecord::Migration
 def self.up
    create_table :firewalls,:id=>false do |t|
      t.column:patient_wedgetail,    :string
      t.column:user_wedgetail,   :string
    end
  end

  def self.down
    drop_table :firewalls
  end
end
