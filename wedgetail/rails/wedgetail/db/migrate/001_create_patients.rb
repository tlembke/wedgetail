class CreatePatients < ActiveRecord::Migration
  def self.up
    create_table :patients do |t|
      t.column:identifier,    :string
      t.column:family_name,   :string
      t.column:given_names,   :string
      t.column:known_as,      :string
      t.column:address_line,  :string
      t.column:town,          :string
      t.column:state,         :integer
      t.column:postcode,      :string
      t.column:sex,           :integer
      t.column:dob,           :date
      t.column:created_at,    :timestamp
    end
      add_index :patients,    :identifier
      add_index :patients,    :family_name
  end

  def self.down
    drop_table :patients
  end
end
