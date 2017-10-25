Sequel.migration do
  up do
    create_table(:auths) do
      primary_key :id
      String    :tag, null: false
      String    :datafield, null: false, unique: true
      String    :type
      String    :source
      String    :heading, null: false
      String    :query
      Integer   :matches
      String    :uri
      TrueClass :ils, default: 0
      TrueClass :valid
      String    :record, text: true
    end

    create_table(:bibs) do
      primary_key :id
      String :bib_number, null: false, unique: true
      String :title, null: false
    end

    create_table(:auths_bibs) do
      foreign_key :auth_id, :auths, null: false
      foreign_key :bib_id,  :bibs,  null: false
      primary_key [:auth_id, :bib_id]
      index [:auth_id, :bib_id]
    end
  end

  down do
    drop_table(:auths_bibs)
    drop_table(:auths)
    drop_table(:bibs)
  end
end
