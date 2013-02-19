class AlterFileInfo < ActiveRecord::Migration
  def up
    add_column(:file_infos, :container, :string, :limit=>240)
  end

  def down
    remove_column(:file_infos, :container)
  end
end
