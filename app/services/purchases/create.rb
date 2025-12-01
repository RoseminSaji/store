# module Purchases
#   class Create
#     attr_reader :purchase, :change_denominations, :errors

#     def initialize(purchase_params:, denominations:)
#       @purchase_params = purchase_params
#       @denominations   = denominations || {}
#       @errors          = []
#     end

#     def call
#       ActiveRecord::Base.transaction do
#         build_purchase!
#         validate_stock!
#         calculate_totals!
#         @purchase.save!
#         deduct_stock!
#         calculate_change_denominations!
#       end

#       true
#     rescue ActiveRecord::RecordInvalid => e
#       @purchase ||= e.record
#       false
#     rescue StandardError => e
#       @errors << e.message
#       false
#     end

#     private

#     def build_purchase!
#       customer = Customer.find_or_create_by!(email: @purchase_params[:customer_email])

#       @purchase = Purchase.new(
#         customer:    customer,
#         paid_amount: @purchase_params[:paid_amount]
#       )

#       build_line_items!
#     end

    def build_line_items!
      items = @purchase_params[:line_items] || []
      items.each do |item|
        next if item[:product_id].blank? || item[:quantity].blank?

        product  = Product.find(item[:product_id])
        quantity = item[:quantity].to_i

        li = @purchase.line_items.build(
          product:        product,
          quantity:       quantity,
          unit_price:     product.unit_price,
          tax_percentage: product.tax_percentage
        )

        li.tax_amount  = (li.unit_price * li.quantity * li.tax_percentage / 100.0)
        li.total_price = (li.unit_price * li.quantity) + li.tax_amount
      end

      if @purchase.line_items.empty?
        raise StandardError, "At least one line item is required"
      end
    end

#     def validate_stock!
#       @purchase.line_items.each do |li|
#         if li.quantity > li.product.stock
#           raise StandardError,
#                 "Insufficient stock for #{li.product.name}. Available: #{li.product.stock}"
#         end
#       end
#     end

#     def calculate_totals!
#       total_without_tax = @purchase.line_items.sum { |li| li.unit_price * li.quantity }
#       total_tax         = @purchase.line_items.sum(&:tax_amount)
#       net_amount        = total_without_tax + total_tax

#       @purchase.total_without_tax  = total_without_tax
#       @purchase.total_tax          = total_tax
#       @purchase.net_amount         = net_amount
#       @purchase.rounded_net_amount = net_amount.floor
#       @purchase.balance_amount     = @purchase.paid_amount - @purchase.rounded_net_amount
#     end

#     def deduct_stock!
#       @purchase.line_items.each do |li|
#         product = li.product
#         product.update!(stock: product.stock - li.quantity)
#       end
#     end

#     def calculate_change_denominations!
#       balance   = @purchase.balance_amount.to_i
#       available = @denominations.transform_keys(&:to_i).transform_values(&:to_i)
#       remaining = balance
#       result    = {}

#       available.sort_by { |value, _| -value }.each do |value, count_available|
#         break if remaining <= 0

#         max_needed = remaining / value
#         use_count  = [max_needed, count_available].min
#         next if use_count <= 0

#         result[value] = use_count
#         remaining -= value * use_count
#       end

#       if remaining > 0
#         raise StandardError,
#               "Insufficient denominations to return exact change. Remaining: #{remaining}"
#       end

#       @change_denominations = result
#     end
#   end
# end