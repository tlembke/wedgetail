class AddCmaType < ActiveRecord::Migration
  def self.up
     NarrativeType.create(:id=>'19',:narrative_type_name=>'CMA')
  end

  def self.down
    NarrativeType.delete(:id=>'19')
  end
end