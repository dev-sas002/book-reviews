# Builds the relation behind `GET /api/books/:id/reviews` (and the author
# equivalent) from untrusted query-string parameters.
#
# Filtering lives in ReviewFilters, ordering in the whitelist below, and paging
# in Pagination. Nothing here interpolates a parameter into SQL: sort columns
# and directions are looked up in frozen hashes, so an injected `sort_by` is
# simply not found and the default ordering applies.
class ReviewsQuery
  SORT_FIELDS = {
    'rating' => :rating,
    'created_at' => :created_at,
    'updated_at' => :updated_at
  }.freeze

  ORDER_DIRECTIONS = %w[asc desc].freeze
  DEFAULT_DIRECTION = 'asc'.freeze

  # `filters` is positional rather than a keyword argument on purpose: with a
  # keyword in the signature, Ruby 2.7 would swallow `new(book, rating: 4)`
  # into `filters` instead of `params`.
  def initialize(reviewable, params = {}, filters = ReviewFilters.registry)
    @reviewable = reviewable
    @params = normalize(params)
    @filters = filters
  end

  # Filtered and ordered, but not paged: the controller decides how much of it
  # to render, and Pagination needs the full scope to report a total.
  def relation
    @relation ||= sort(filter(base_scope))
  end

  # The sort that was actually applied, for documentation and debugging.
  def applied_sort
    [sort_column || :id, sort_column ? direction : DEFAULT_DIRECTION]
  end

  private

  attr_reader :params, :filters

  def base_scope
    # A review without its author's name is close to useless, so the serializer
    # renders the user; without this `includes` that is one SELECT per review.
    @reviewable.reviews.includes(:user)
  end

  def filter(scope)
    filters.reduce(scope) { |acc, filter| filter.apply(acc, params[filter.param_name]) }
  end

  def sort(scope)
    return scope.order(id: :asc) if sort_column.nil?

    # `id` breaks ties so that equal ratings or timestamps come back in a
    # stable order; without it Postgres may return rows differently on each
    # call and pagination silently duplicates or drops rows.
    scope.order(sort_column => direction, :id => :asc)
  end

  def sort_column
    return @sort_column if defined?(@sort_column)

    @sort_column = SORT_FIELDS[params[:sort_by].to_s]
  end

  def direction
    requested = params[:order].to_s.downcase
    ORDER_DIRECTIONS.include?(requested) ? requested : DEFAULT_DIRECTION
  end

  # Accepts ActionController::Parameters, a symbol-keyed hash or a
  # string-keyed hash so that specs can call the query object directly.
  def normalize(params)
    hash = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    hash.symbolize_keys
  end
end
