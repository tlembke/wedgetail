class Audit < ActiveRecord::Base
  def user
    @user=User.find_by_wedgetail(self.user_wedgetail)
  end
end
