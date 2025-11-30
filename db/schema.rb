# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_29_200645) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "updated_at", null: false
  end

  create_table "line_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.bigint "purchase_id", null: false
    t.integer "quantity"
    t.decimal "tax_amount", precision: 10, scale: 2
    t.decimal "tax_percentage", precision: 5, scale: 2
    t.decimal "total_price", precision: 10, scale: 2
    t.decimal "unit_price", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_line_items_on_product_id"
    t.index ["purchase_id"], name: "index_line_items_on_purchase_id"
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "product_code", null: false
    t.integer "stock", default: 0, null: false
    t.decimal "tax_percentage", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["product_code"], name: "index_products_on_product_code", unique: true
  end

  create_table "purchases", force: :cascade do |t|
    t.decimal "balance_amount", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.decimal "net_amount", precision: 10, scale: 2
    t.decimal "paid_amount", precision: 10, scale: 2
    t.integer "rounded_net_amount"
    t.decimal "total_tax", precision: 10, scale: 2
    t.decimal "total_without_tax", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_purchases_on_customer_id"
  end

  add_foreign_key "line_items", "products"
  add_foreign_key "line_items", "purchases"
  add_foreign_key "purchases", "customers"
end
