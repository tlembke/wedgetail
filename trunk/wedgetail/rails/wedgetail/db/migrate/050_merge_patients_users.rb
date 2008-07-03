class MergePatientsUsers < ActiveRecord::Migration
  def self.up
      # mae users have all of Patients columns
      add_column :users, :known_as, :string
      add_column :users, :address_line, :string
      add_column :users, :town, :string
      add_column :users, :state, :string
      add_column :users, :postcode, :string
      add_column :users, :sex, :integer
      add_column :users, :created_at, :datetime
      add_column :users, :visibility, :boolean, :default=>true
      add_column :users, :medicare, :string
      add_column :users, :dob, :date
      # add a few more while we're here
      add_column :users, :dva, :string
      add_column :users, :crn, :string
      add_column :users, :prescriber, :string
      add_column :users, :provider, :string
      # remove this constraint as Teams don't have a first name
      change_column :users, :given_names, :string, :null=>true
      # now move across the data, oldest first (so new data updates over the old)
      Patient.find(:all,:order=>"created_at ASC").each do |pat|
        u = User.find_by_wedgetail(pat.wedgetail)
        u.sex = pat.sex
        u.postcode = pat.postcode
        u.state = pat.state
        u.town = pat.town
        u.known_as = pat.known_as
        u.medicare = pat.medicare
        u.visibility = pat.visibility
        u.created_at = pat.created_at
        u.address_line = pat.address_line
	u.dob = pat.dob
	u.save!
      end
      # drop patients table
      drop_table :patients
    end

    def self.down
      # doable, but I can't be bothered,
      raise ActiveRecord::IrreversibleMigration
    end
end
