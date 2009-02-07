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

ActiveRecord::Schema.define(:version => 20081123035313) do

  create_table "audits", :force => true do |t|
    t.string   "patient"
    t.string   "user_wedgetail"
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

  create_table "firewalls", :id => false, :force => true do |t|
    t.string "patient_wedgetail"
    t.string "user_wedgetail"
  end

  create_table "interests", :id => false, :force => true do |t|
    t.string "patient"
    t.string "user"
  end

  create_table "messages", :force => true do |t|
    t.string   "sender_id"
    t.string   "recipient_id"
    t.string   "subject"
    t.text     "content"
    t.datetime "created_at"
    t.integer  "thread",       :limit => 11
    t.integer  "status",       :limit => 11
    t.string   "re"
  end

  create_table "narrative_types", :force => true do |t|
    t.string "narrative_type_name"
  end

  create_table "narratives", :force => true do |t|
    t.string   "wedgetail"
    t.integer  "narrative_type_id", :limit => 11
    t.string   "title"
    t.text     "content"
    t.date     "narrative_date"
    t.string   "created_by"
    t.datetime "created_at"
    t.string   "content_type"
    t.text     "plaintext"
    t.boolean  "awaiting_pickup",                 :default => false
    t.string   "hl7_id"
    t.string   "hl7_reply_id"
    t.string   "created_team"
  end

  create_table "outgoing_messages", :force => true do |t|
    t.string   "acktype"
    t.text     "ack"
    t.datetime "acked_at"
    t.integer  "narrative_id", :limit => 11
    t.integer  "status",       :limit => 11, :default => 0
    t.string   "recipient_id"
    t.datetime "last_sent"
  end

  create_table "prefs", :force => true do |t|
    t.string "name"
    t.string "value"
  end

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "family_name",                                     :null => false
    t.string   "given_names",                   :default => ""
    t.string   "email"
    t.string   "designation"
    t.string   "hashed_password"
    t.string   "salt"
    t.integer  "role",            :limit => 11
    t.integer  "access",          :limit => 11
    t.string   "wedgetail"
    t.integer  "patient_post",    :limit => 11, :default => 0
    t.integer  "crypto_pref",     :limit => 11, :default => 0
    t.string   "cert"
    t.string   "known_as"
    t.string   "address_line"
    t.string   "town"
    t.string   "state"
    t.string   "postcode"
    t.integer  "sex",             :limit => 11
    t.datetime "created_at"
    t.boolean  "visibility",                    :default => true
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
