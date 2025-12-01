class PurchaseMailer < ApplicationMailer
  def invoice_email(purchase)
    p "inside mailer"
    @purchase = purchase
    mail(to: @purchase.customer.email, subject: "Your Invoice ##{@purchase.id}")
  end
end
