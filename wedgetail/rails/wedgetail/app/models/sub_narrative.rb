class SubNarrative < ActiveRecord::Base
  belongs_to :narrative
  has_one :code

end
