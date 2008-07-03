class Event < ActiveRecord::Base
  belongs_to :event_types
  belongs_to :agent
end
