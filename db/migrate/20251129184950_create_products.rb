class CreateProducts < ActiveRecord::Migration[7.1] # or 8.x
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :product_code, null: false
      t.integer :stock, null: false, default: 0
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :tax_percentage, precision: 5, scale: 2, null: false, default: 0

      t.timestamps
    end

    add_index :products, :product_code, unique: true
  end
end