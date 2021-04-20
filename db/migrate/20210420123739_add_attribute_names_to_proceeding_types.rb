class AddAttributeNamesToProceedingTypes < ActiveRecord::Migration[6.1]
  def up
    add_column :proceeding_types, :name, :string
    ProceedingType.all.each do |pt|
      pt.update(name: pt.meaning.downcase.gsub(/[^a-z ]/i, '').strip.gsub(/\s+/, '_'))
    end
  end

  def down
    remove_column :proceeding_types, :name, :string
  end
end
