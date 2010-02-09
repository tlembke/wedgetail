class Patient < ActiveRecord::Base
    has_many :results
    has_many :narratives
end
