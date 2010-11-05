class Task < ActiveRecord::Base
  belongs_to :goal
  
  attr_accessor :universal #do new goals apply to other patients or just the one open.
end
