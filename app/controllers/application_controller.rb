class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  skip_before_action :verify_authenticity_token, only: :create

  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::ParameterMissing, with: :handle_bad_request
  rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error

  private
  
  def handle_not_found(error)
    render json: { error: error.message }, status: :not_found
  end

  def handle_validation_error(error)
    render json: { errors: error.record.errors.full_messages },
           status: :unprocessable_entity
  end

  def handle_bad_request(error)
    render json: { error: error.message }, status: :bad_request
  end

  def render_custom_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end

  def render_validation_error(record)
    render json: { errors: record.errors.full_messages },
           status: :unprocessable_entity
  end
end