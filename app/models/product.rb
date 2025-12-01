class Product < ApplicationRecord
  has_many :line_items

  validates :name, :product_code, :unit_price, :tax_percentage, presence: true
  validates :product_code, uniqueness: true
  validates :stock, numericality: { greater_than_or_equal_to: 0 }
  validates :unit_price, numericality: { greater_than: 0 }
  validates :tax_percentage, numericality: { greater_than_or_equal_to: 0 }
end