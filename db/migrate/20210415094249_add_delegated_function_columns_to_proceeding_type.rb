class AddDelegatedFunctionColumnsToProceedingType < ActiveRecord::Migration[6.1]
  def up
    change_table :application_proceeding_types do |t|
      t.date :used_delegated_functions_on
      t.date :used_delegated_functions_reported_on
    end
    execute <<~END_OF_QUERY
      UPDATE application_proceeding_types a
        SET used_delegated_functions_on = l.used_delegated_functions_on, used_delegated_functions_reported_on = l.used_delegated_functions_reported_on
        FROM legal_aid_applications l
        WHERE a.legal_aid_application_id = l.id
    END_OF_QUERY
  end

  def down
    change_table :application_proceeding_types do |t|
      t.remove :used_delegated_functions_on, :used_delegated_functions_reported_on
    end
  end
end
