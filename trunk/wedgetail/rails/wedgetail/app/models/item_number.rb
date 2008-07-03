class ItemNumber < ActiveRecord::Base
  has_and_belongs_to_many :consultations
  has_many :claims
end
