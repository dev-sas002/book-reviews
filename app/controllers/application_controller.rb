class ApplicationController < ActionController::API
  include Paginated

  # The error contract: every non-2xx response this API produces has the same
  # body, `{"errors": ["..."]}`, so a client needs one branch rather than one
  # per status code.
  #
  #   404 unknown or missing record
  #   400 malformed request (a required parameter is absent, or the body is
  #       not valid JSON)
  #   422 the request was understood and rejected by a validation
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_unparseable_body

  private

  def render_not_found
    render json: { errors: ['Resource not found'] }, status: :not_found
  end

  def render_bad_request(exception)
    render json: { errors: [exception.message] }, status: :bad_request
  end

  # The parser's own message quotes the body back, so it is not echoed.
  def render_unparseable_body
    render json: { errors: ['Request body is not valid JSON'] }, status: :bad_request
  end

  def render_errors(messages, status: :unprocessable_content)
    render json: { errors: Array(messages) }, status: status
  end
end
