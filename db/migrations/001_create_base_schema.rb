Sequel.migration do
  up do
    create_table(:bibs) do
      primary_key :id
      String :bib_number, null: false
    end

    create_table(:auths) do
      primary_key :id
      String  :heading, null: false
      String  :query
      Integer :matches
      String  :uri
      String  :identifier
      Boolean :ils, default: false
    end

    create_table(:bibs_auths) do
      foreign_key :bib_id,  :bibs,  null: false
      foreign_key :auth_id, :auths, null: false
      primary_key [:bib_id, :auth_id]
      index [:bib_id, :auth_id]
    end
  end

  down do
    drop_table(:bibs)
    drop_table(:auths)
  end
end