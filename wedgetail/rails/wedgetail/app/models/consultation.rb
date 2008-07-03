class Consultation < ActiveRecord::Base
  validates_inclusion_of :month,
                         :in =>1..12,
                         :message=>"Month must be numeral in range 1 -12"
                         
  validates_presence_of  :code  
  belongs_to :conditions
  has_and_belongs_to_many :activities
  has_and_belongs_to_many :item_numbers
  

end
