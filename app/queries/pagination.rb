# Keyset-free, limit/offset pagination for the API's collection endpoints.
#
# Every index endpoint is paginated. An unbounded `Model.all` is fine with the
# twelve rows a take-home is demonstrated with and is a memory incident with a
# million, so the cap is applied in one place rather than trusted to callers.
class Pagination
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  attr_reader :page, :per_page

  def initialize(scope, page: nil, per_page: nil)
    @scope = scope
    @page = coerce(page, default: 1, min: 1)
    @per_page = coerce(per_page, default: DEFAULT_PER_PAGE, min: 1, max: MAX_PER_PAGE)
  end

  def records
    @records ||= @scope.limit(per_page).offset((page - 1) * per_page)
  end

  # Counted on the filtered scope, before limit/offset are applied.
  def total
    @total ||= @scope.except(:includes, :order).count
  end

  def total_pages
    return 1 if total.zero?

    (total.to_f / per_page).ceil
  end

  def to_h
    {
      page: page,
      per_page: per_page,
      total: total,
      total_pages: total_pages
    }
  end

  private

  # Query strings are strings, and hostile ones at that: `?per_page=-1` must not
  # turn into an offset that Postgres rejects, and `?per_page=1000000` must not
  # turn into a full table scan.
  def coerce(value, default:, min:, max: nil)
    integer = Integer(value.to_s.strip, 10)
    integer = min if integer < min
    integer = max if max && integer > max
    integer
  rescue ArgumentError, TypeError
    default
  end
end
