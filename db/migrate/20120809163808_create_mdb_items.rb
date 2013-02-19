# lastmod 10 agosto 2012
# lastmod  9 agosto 2012

class CreateMdbItems < ActiveRecord::Migration
  def change
    create_table :mdb_items do |t|
      t.string :collocazione, :limit=>128
      t.text :title
      t.integer :record_id
      t.string :source, :limit=>128
    end
  end
end
