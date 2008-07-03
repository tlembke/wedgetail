class NarrativeType < ActiveRecord::Base
 has_many  :narratives,
           :order => "created_at DESC"
end
