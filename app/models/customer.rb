class Customer < ApplicationRecord
  has_many :purchases, dependent: :destroy

  validates :email,
  presence: true,
  uniqueness: true,
  format: {
    with: URI::MailTo::EMAIL_REGEXP,
    message: "is not a valid email address"
  }
end