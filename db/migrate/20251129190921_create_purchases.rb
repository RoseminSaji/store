class CreatePurchases < ActiveRecord::Migration[8.1]
  def change
    create_table :purchases do |t|
      t.references :customer, null: false, foreign_key: true
      t.decimal :total_without_tax, precision: 10, scale: 2
      t.decimal :total_tax, precision: 10, scale: 2
      t.decimal :net_amount, precision: 10, scale: 2
      t.integer :rounded_net_amount
      t.decimal :paid_amount, precision: 10, scale: 2
      t.decimal :balance_amount, precision: 10, scale: 2

      t.timestamps
    end
  end
end
