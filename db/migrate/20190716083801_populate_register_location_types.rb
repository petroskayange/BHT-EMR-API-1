class PopulateRegisterLocationTypes < ActiveRecord::Migration[5.2]
  def up
    ActiveRecord::Base.connection.execute(
      <<~SQL
        INSERT INTO register_location_types
        VALUES (1, 'Health Facility', CURRENT_TIMESTAMP()),
               (2, 'Community', CURRENT_TIMESTAMP()),
               (3, 'Standalone', CURRENT_TIMESTAMP())
      SQL
    )
  end

  def down
    ActiveRecord::Base.connection.execute(
      <<~SQL
        DELETE FROM register_location_types
        WHERE (id = 1 AND name LIKE 'Health Facility')
          OR (id = 2 AND name LIKE 'Community')
          OR (id = 3 AND name LIKE 'Standalone')
      SQL
    )
  end
end
