# lastmod 20 settembre 2012

class CreateClavisCollocs < ActiveRecord::Migration
  def change
    create_table :clavis_collocs, :id=>false do |t|
      t.string :collocazione
      t.integer :manifestation_id
      t.integer :item_id
    end
  end
end
