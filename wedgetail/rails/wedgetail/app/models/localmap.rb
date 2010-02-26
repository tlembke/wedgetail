class Localmap < ActiveRecord::Base
  def self.get(user,localID)
      team=user.wedgetail
      team=user.team if user.team and user.team!=""
      localmap=Localmap.find(:first, :conditions=>["localID=? and team=?",localID, team], :order=>"created_at DESC") 
      return localmap
  end
  
  def self.checkWedge(user,wedgetail)
      team=user.wedgetail
      team=user.team if user.team !="" and user.team !='0' and user.team !=NULL
      localmap=Localmap.find(:first, :conditions=>["wedgetail=? and team=?",wedgetail, team], :order=>"created_at DESC") 
      return localmap
  end

end
