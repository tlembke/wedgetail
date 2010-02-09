class ResultTicket < ActiveRecord::Base
  validates_uniqueness_of :request_set, 
                          :on => :create, 
                          :message => "is already being used"
  validates_uniqueness_of :ticket, 
                          :on => :create, 
                          :message => "is already being used"
end
