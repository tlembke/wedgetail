class Team < ActiveRecord::Base
  belongs_to :craft
  
  def self.confirmed?(patient, member)
    confirmed=2  # no team ??
    if @team=Team.find(:first,:conditions=>["patient=? and member=?",patient,member])
      confirmed=@team.confirmed
    end
    return confirmed
  end

end
