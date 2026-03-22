# Turns a relation into a page and advertises the paging on the response.
#
# Pagination metadata travels in headers so that collection endpoints can keep
# returning a plain JSON array; the reviews endpoint, whose body is already an
# object, repeats it as `meta` for convenience.
module Paginated
  extend ActiveSupport::Concern

  private

  def paginate(scope)
    pagination = Pagination.new(
      scope,
      page: params[:page],
      per_page: params[:per_page]
    )
    assign_pagination_headers(pagination)
    pagination
  end

  def assign_pagination_headers(pagination)
    response.set_header('X-Page', pagination.page.to_s)
    response.set_header('X-Per-Page', pagination.per_page.to_s)
    response.set_header('X-Total-Count', pagination.total.to_s)
    response.set_header('X-Total-Pages', pagination.total_pages.to_s)
  end
end
