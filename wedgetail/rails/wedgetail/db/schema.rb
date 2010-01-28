# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091201193558) do

  create_table "actions", :force => true do |t|
    t.string   "request_set"
    t.date     "test_date"
    t.string   "action_code"
    t.text     "comment"
    t.string   "wedgetail"
    t.boolean  "last_flag"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "identifier"
    t.string   "name"
    t.string   "created_by"
  end

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

  create_table "codes", :force => true do |t|
    t.string   "code"
    t.string   "name"
    t.text     "values"
    t.string   "type"
    t.boolean  "deleted",    :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "contacts", :force => true do |t|
    t.string   "team"
    t.string   "wedgetail"
    t.datetime "created_at"
    t.datetime "updated_at"
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

  create_table "localmaps", :force => true do |t|
    t.string   "team"
    t.string   "localID"
    t.string   "wedgetail"
    t.datetime "created_at"
    t.datetime "updated_at"
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

  create_table "result_tickets", :force => true do |t|
    t.string   "request_set"
    t.string   "ticket"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "results", :force => true do |t|
    t.string   "wedgetail"
    t.string   "surname"
    t.string   "given_name"
    t.date     "dob"
    t.date     "date"
    t.string   "name"
    t.string   "loinc"
    t.string   "value"
    t.string   "lab_text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "comment"
    t.string   "posted_by"
    t.datetime "ack"
    t.string   "action"
    t.string   "result_ref"
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
    t.string   "created_by"
    t.boolean  "hatched"
  end

end
