class UpdateHatches < ActiveRecord::Migration
  def self.up
    User.find(:all,:conditions=>["role=5"]).each do |pat|
          pat.hatched=0
          pat.hatched=1 if pat.wedgetail.at(0)=="H"
          pat.save!
    end
  end
end
