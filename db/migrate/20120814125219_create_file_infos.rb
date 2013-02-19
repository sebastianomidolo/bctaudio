# lastmod 20 agosto 2012
# lastmod 14 agosto 2012

class CreateFileInfos < ActiveRecord::Migration
  def change
    create_table :file_infos do |t|
      t.string :collocazione, :limit=>128
      t.string :filepath, :limit=>320
      t.string :drive, :limit=>48
      t.xml :mp3_tags
      t.integer :tracknum
    end
  end
end
