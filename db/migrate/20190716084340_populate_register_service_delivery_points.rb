class PopulateRegisterServiceDeliveryPoints < ActiveRecord::Migration[5.2]
  def up
    ActiveRecord::Base.connection.execute(
      <<~SQL
        INSERT INTO register_service_delivery_points
        VALUES (10, 'ANC', CURRENT_TIMESTAMP()),
               (11, 'Inpatient', CURRENT_TIMESTAMP()),
               (12, 'Malnutrition', CURRENT_TIMESTAMP()),
               (13, 'Maternity', CURRENT_TIMESTAMP()),
               (14, 'Mobile', CURRENT_TIMESTAMP()),
               (15, 'OPD', CURRENT_TIMESTAMP()),
               (16, 'Pediatric', CURRENT_TIMESTAMP()),
               (17, 'STI', CURRENT_TIMESTAMP()),
               (18, 'TB', CURRENT_TIMESTAMP()),
               (19, 'VCT/Other', CURRENT_TIMESTAMP()),
               (20, 'VMMC', CURRENT_TIMESTAMP())
      SQL
    )
  end

  def down
    ActiveRecord::Base.connection.execute(
      <<~SQL
        DELETE FROM register_service_delivery_points
        WHERE (id = 10 AND name LIKE 'ANC')
              OR (id = 11 AND name LIKE 'Inpatient')
              OR (id = 12 AND name LIKE 'Malnutrition')
              OR (id = 13 AND name LIKE 'Maternity')
              OR (id = 14 AND name LIKE 'Mobile')
              OR (id = 15 AND name LIKE 'OPD')
              OR (id = 16 AND name LIKE 'Pediatric')
              OR (id = 17 AND name LIKE 'STI')
              OR (id = 18 AND name LIKE 'TB')
              OR (id = 19 AND name LIKE 'VCT/Other')
              OR (id = 20 AND name LIKE 'VMMC')
      SQL
    )
  end
end
