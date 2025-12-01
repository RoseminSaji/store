class ProductSerializer < ApplicationSerializer
  attributes :id, :name, :product_code, :stock, :unit_price, :tax_percentage
end
