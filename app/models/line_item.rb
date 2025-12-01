class LineItem < ApplicationRecord
  belongs_to :purchase
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }
end