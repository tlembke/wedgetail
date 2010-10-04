class Carerole < ActiveRecord::Base
  belongs_to :craft
  belongs_to :goal
  belongs_to :patient
end
