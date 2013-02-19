# lastmod 8 novembre 2012

class AlterFileInfo2 < ActiveRecord::Migration
  def up
    add_column(:file_infos, :bfilesize, :decimal, :precision=>15, :scale=>0)
    add_column(:file_infos, :mime_type, :string, :limit=>24)
  end

  def down
    remove_column(:file_infos, :bfilesize)
    remove_column(:file_infos, :mime_type)
  end
end
