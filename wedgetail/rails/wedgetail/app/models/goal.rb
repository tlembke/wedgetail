class Goal < ActiveRecord::Base
  belongs_to :measure
  belongs_to :condition
  has_many :careroles
  
  attr_accessor :universal #do new goals apply to other patients or just the one open.
  
end
   