class MakeSchema < ActiveRecord::Migration
  def self.up

    create_table "activities", :force => true do |t|
      t.string  "name"
      t.integer "agent_id"
      t.integer "timing"
    end
    
    create_table "activities_consultations", :id => false, :force => true do |t|
      t.integer "activity_id"
      t.integer "consultation_id"
    end
    
    create_table "agents", :force => true do |t|
      t.string "role"
    end
    
    create_table "audits", :id => false, :force => true do |t|
      t.string   "patient"
      t.string   "user_wedgetail"
      t.datetime "created_at"
    end
    
    create_table "claims", :force => true do |t|
      t.string   "wedgetail"
      t.integer  "item_number_id"
      t.date     "date"
      t.string   "code"
      t.datetime "created_at"
    end
    
    create_table "event_types", :force => true do |t|
      t.string "name"
    end
    
    create_table "firewalls", :id => false, :force => true do |t|
      t.string "patient_wedgetail"
      t.string "user_wedgetail"
    end
    
    create_table "interests", :id => false, :force => true do |t|
      t.string "patient"
      t.string "user"
    end
    
    create_table "item_numbers", :force => true do |t|
      t.integer "number"
      t.string  "name"
      t.string  "description"
      t.string  "code"
    end
    
    create_table "messages", :force => true do |t|
      t.string   "sender_id"
      t.string   "recipient_id"
      t.string   "subject"
      t.text     "content"
      t.datetime "created_at"
      t.integer  "thread"
      t.integer  "status"
      t.string   "re"
    end
    
    create_table "narrative_types", :force => true do |t|
      t.string "narrative_type_name"
    end
    
    create_table "narratives", :force => true do |t|
      t.string   "wedgetail"
      t.integer  "narrative_type_id"
      t.string   "title"
      t.text     "content"
      t.date     "narrative_date"
      t.string   "created_by"
      t.datetime "created_at"
      t.string   "content_type"
      t.text     "plaintext"
      t.boolean  "awaiting_pickup",   :default => false
      t.string   "hl7_id"
      t.string   "hl7_reply_id"
    end
    
    create_table "outgoing_messages", :force => true do |t|
      t.string   "acktype"
      t.text     "ack"
      t.datetime "acked_at"
      t.integer  "narrative_id"
      t.integer  "status",       :default => 0
      t.string   "recipient_id"
      t.datetime "last_sent"
    end
    
    create_table "prefs", :force => true do |t|
      t.string "name"
      t.string "value"
    end
    
    create_table "users", :force => true do |t|
      t.string   "username"
      t.string   "family_name",     :default => "",   :null => false
      t.string   "given_names",     :default => ""
      t.string   "email"
      t.string   "designation"
      t.string   "hashed_password"
      t.string   "salt"
      t.integer  "role"
      t.integer  "access"
      t.string   "wedgetail"
      t.integer  "patient_post",    :default => 0
      t.integer  "crypto_pref"
      t.string   "cert"
      t.string   "known_as"
      t.string   "address_line"
      t.string   "town"
      t.string   "state"
      t.string   "postcode"
      t.integer  "sex"
      t.datetime "created_at"
      t.boolean  "visibility",      :default => true
      t.string   "medicare"
      t.date     "dob"
      t.string   "dva"
      t.string   "crn"
      t.string   "prescriber"
      t.string   "provider"
      t.string   "team"
    end
  end

  def self.down
    drop_table :activities
    drop_table :activities_consultations
    drop_table :agents
    drop_table :audits
    drop_table :claims
    drop_table :event_types
    drop_table :firewalls
    drop_table :interests
    drop_table :item_numbers
    drop_table :messages
    drop_table :narrative_types
    drop_table :narratives
    drop_table :outgoing_messages
    drop_table :prefs
    drop_table :users
  end
end
