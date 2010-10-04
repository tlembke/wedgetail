class Craft < ActiveRecord::Base
  has_many :users
  has_many :careroles
  has_many :teams
  
  
  def self.get_crafts
    @crafts = Craft.find(:all, :order => "name").map {|u| [u.name, u.id] }
  end
  
  
  def self.get_craftgroups
    @cg = [ 'Doctor', 'Allied Health', 'Nursing', 'Admin' ]
    @option_string=""
    count=1
    @cg.each do |option|
      @option_string=@option_string+"<option value='" + count.to_s
      @option_string=@option_string +"'>"+ option +"</option>"
      count=count+1
    end  
    return @option_string
  end
  
end
