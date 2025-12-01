class Purchase < ApplicationRecord
  belongs_to :customer
  has_many :line_items, dependent: :destroy

  accepts_nested_attributes_for :line_items, allow_destroy: true
  validates :paid_amount, presence: true,
                          numericality: { greater_than_or_equal_to: 0 }
end
