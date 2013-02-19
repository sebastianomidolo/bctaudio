# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121108102643) do

  create_table "clavis_collocs", :id => false, :force => true do |t|
    t.string  "collocazione"
    t.integer "manifestation_id"
    t.integer "item_id"
  end

  create_table "file_infos", :force => true do |t|
    t.string  "collocazione", :limit => 128
    t.string  "filepath",     :limit => 320
    t.string  "drive",        :limit => 48
    t.xml     "mp3_tags"
    t.integer "tracknum"
    t.string  "container",    :limit => 240
    t.decimal "bfilesize",                   :precision => 15, :scale => 0
    t.string  "mime_type",    :limit => 24
  end

  create_table "mdb_items", :force => true do |t|
    t.string  "collocazione", :limit => 128
    t.text    "title"
    t.integer "record_id"
    t.string  "source",       :limit => 128
  end

end
