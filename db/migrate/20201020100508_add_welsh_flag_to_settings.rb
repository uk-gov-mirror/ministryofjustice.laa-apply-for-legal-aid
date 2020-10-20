class AddWelshFlagToSettings < ActiveRecord::Migration[6.0]
  def change
    add_column :settings, :welsh_translation, :boolean, null: false, default: false
  end
end
