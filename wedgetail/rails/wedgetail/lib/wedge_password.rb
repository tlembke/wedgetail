class WedgePassword
  def self.make(prefix="")
    finished=1
    while finished!=nil
      wedgetail_number=prefix+Pref.server+random_password(5)
      # see if it is unique - will be not nil
      finished=User.find_by_wedgetail(wedgetail_number)
    end
    return wedgetail_number
  end

  def self.random_password(size = 8)
    chars = (('a'..'z').to_a + ('0'..'9').to_a) - %w(i o 0 1 l 0)
    (1..size).collect{|a| chars[rand(chars.size)] }.join
  end
  
  def self.username_make(prefix="")
    finished=1
    while finished!=nil
      username=prefix+random_password(5)
      # see if it is unique - will be not nil
      finished=User.find_by_username(username)
    end
    return username
  end
end