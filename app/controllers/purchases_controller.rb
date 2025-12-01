class PurchasesController < ApplicationController
  def index
    redirect_to new_purchase_path
  end

  # GET /purchases/new
  def new
    @purchase = Purchase.new
    @products = Product.order(:name)
    @denoms   = [2000, 500, 200, 100, 50, 20, 10, 5, 2, 1]
  end

  # POST /purchases
  def create
    ActiveRecord::Base.transaction do
      # 1. Find or create customer
      customer = Customer.find_or_create_by!(email: purchase_params[:customer_email])

      # 2. Build purchase
      @purchase = customer.purchases.new(
        paid_amount: purchase_params[:paid_amount]
      )

      # 3. Build line items from params
      build_line_items(@purchase, purchase_params[:line_items])

      if @purchase.line_items.empty?
        return handle_simple_error("At least one line item is required")
      end

      # 4. Calculate totals & balance
      calculate_totals(@purchase)

      if @purchase.balance_amount < 0
        return handle_simple_error("Paid amount is less than bill amount")
      end

      # 5. Stock check (before saving)
      @purchase.line_items.each do |li|
        if li.quantity > li.product.stock
          msg = "Insufficient stock for #{li.product.name}. Available: #{li.product.stock}"
          raise ActiveRecord::RecordInvalid.new(li.product), msg
        end
      end

      # 6. Save purchase (once)
      unless @purchase.save
        return handle_simple_error(@purchase.errors.full_messages.to_sentence)
      end

      # 7. Stock deduction
      @purchase.line_items.each do |li|
        product = li.product
        product.update!(stock: product.stock - li.quantity)
      end

      # 8. Calculate change denominations
      change_denoms = calculate_change_denominations(
        @purchase.balance_amount.to_i,
        permitted_denominations
      )

      # 9. Email (if you have mailer ready)
      PurchaseMailer.invoice_email(@purchase).deliver_later

      respond_to do |format|
        format.html do
          redirect_to @purchase, notice: "Purchase created successfully."
        end

        format.json do
          render json: {
            purchase:             serialize_purchase(@purchase),
            change_denominations: change_denoms
          }, status: :created
        end
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    if request.format.json?
      render_validation_error(e.record)
    else
      handle_simple_error(e.record.errors.full_messages.to_sentence)
    end
  end

  # GET /purchases/:id
  def show
    @purchase = Purchase.includes(:customer, line_items: :product).find(params[:id])

    respond_to do |format|
      format.html # renders show.html.erb
      format.json { render json: serialize_purchase(@purchase) }
    end
  end

  private

  # Strong params
  def purchase_params
    params.require(:purchase).permit(
      :customer_email,
      :paid_amount,
      { denominations: {} },              # {"2000"=>"3", "500"=>"2", ...}
      { line_items: %i[product_id quantity] } # [{"product_id"=>"3","quantity"=>"1"}, ...]
    )
  end

  # Build line_items manually from params
  def build_line_items(purchase, line_items_param)
    Array(line_items_param).each do |li|
      product_id = li[:product_id] || li["product_id"]
      quantity   = li[:quantity]   || li["quantity"]

      next if quantity.to_i <= 0 || product_id.blank?

      product          = Product.find(product_id)
      unit_price       = product.unit_price
      tax_percentage   = product.tax_percentage || 0
      qty              = quantity.to_i

      line_subtotal    = unit_price * qty
      tax_amount       = line_subtotal * tax_percentage / 100.0
      total_price      = line_subtotal + tax_amount

      purchase.line_items.build(
        product:         product,
        quantity:        qty,
        unit_price:      unit_price,
        tax_percentage:  tax_percentage,
        tax_amount:      tax_amount,
        total_price:     total_price
      )
    end
  end

  # ⚠️ your original had `def calculate_totals(@purchase)` which is invalid
  def calculate_totals(purchase)
    total_without_tax = purchase.line_items.sum { |li| li.unit_price * li.quantity }
    total_tax         = purchase.line_items.sum(&:tax_amount)
    net_amount        = total_without_tax + total_tax

    purchase.total_without_tax  = total_without_tax
    purchase.total_tax          = total_tax
    purchase.net_amount         = net_amount
    purchase.rounded_net_amount = net_amount.floor
    # balance = paid - bill (negative means underpaid)
    purchase.balance_amount     = purchase.paid_amount.to_i - purchase.rounded_net_amount
  end

  # Turn the denominations param into a clean hash of {denom_integer => count_integer}
  def permitted_denominations
    raw = purchase_params[:denominations] || {}
    raw.to_h.transform_keys(&:to_i).transform_values { |v| v.to_i }
  end

  # Greedy change algorithm using available denominations
  # amount: Integer (e.g., 350)
  # available: { 2000=>3, 500=>4, 100=>2, ... }
  def calculate_change_denominations(amount, available)
    remaining = amount
    result    = {}

    available.keys.sort.reverse.each do |denom|
      break if remaining <= 0

      max_needed = remaining / denom
      next if max_needed <= 0

      use = [max_needed, available[denom]].min
      next if use <= 0

      result[denom] = use
      remaining    -= use * denom
    end

    # If we can't fully satisfy the amount, you can decide what to do.
    # For now we just return whatever we could compute.
    result
  end

  # JSON helpers
  def serialize_purchase(purchase)
    {
      id:                  purchase.id,
      customer_email:      purchase.customer&.email,
      paid_amount:         purchase.paid_amount,
      total_without_tax:   purchase.total_without_tax,
      total_tax:           purchase.total_tax,
      net_amount:          purchase.net_amount,
      rounded_net_amount:  purchase.rounded_net_amount,
      balance_amount:      purchase.balance_amount,
      line_items: purchase.line_items.map do |li|
        {
          product_id:   li.product_id,
          product_name: li.product.name,
          quantity:     li.quantity,
          unit_price:   li.unit_price,
          tax_amount:   li.tax_amount,
          line_total:   li.unit_price * li.quantity + li.tax_amount
        }
      end
    }
  end

  def render_custom_error(message, status)
    render json: { error: message }, status: status
  end

  def render_validation_error(record)
    render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
  end

  # For HTML: re-render the form with an error.
  def handle_simple_error(message)
    if request.format.json?
      render_custom_error(message, :unprocessable_entity)
    else
      flash.now[:alert] = message
      @products = Product.order(:name)
      @denoms   = [2000, 500, 200, 100, 50, 20, 10, 5, 2, 1]
      render :new, status: :unprocessable_entity
    end
    nil
  end
end
