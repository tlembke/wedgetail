class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column :username,        :string
      t.column :family_name,     :string
      t.column :given_names,     :string
      t.column :email,           :string
      t.column :designation,     :string
      t.column :hashed_password, :string
      t.column :salt,            :string
    end
  end

  def self.down
    drop_table :users
  end
end
