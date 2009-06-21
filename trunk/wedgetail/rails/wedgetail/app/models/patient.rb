class Patient < ActiveRecord::Base
    has_many :results
end
