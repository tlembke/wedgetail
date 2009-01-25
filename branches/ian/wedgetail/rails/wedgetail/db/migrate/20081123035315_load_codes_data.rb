class LoadCodesData < ActiveRecord::Migration
  def self.up
    Code.load_codes
  end

  def self.down
    Code.delete_all
  end
end
