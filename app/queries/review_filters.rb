# Registry of the filters the reviews index understands.
#
# This is the extension seam of the API. A new filter is a class with
# `#param_name` and `#apply(scope, value)`; registering it makes it available
# on every reviews endpoint, and nothing in the controller or the query object
# has to change. That keeps ReviewsQuery closed for modification while the set
# of supported query parameters stays open for extension.
#
#   ReviewFilters.register(ReviewFilters::MinimumRating.new)
module ReviewFilters
  class << self
    def registry
      @registry ||= default_filters
    end

    def register(filter)
      raise ArgumentError, 'filter must respond to #param_name' unless filter.respond_to?(:param_name)
      raise ArgumentError, 'filter must respond to #apply' unless filter.respond_to?(:apply)

      registry << filter
      filter
    end

    def param_names
      registry.map(&:param_name)
    end

    # Restores the built-in filters. Intended for tests that register one.
    def reset!
      @registry = nil
    end

    private

    # Resolved lazily so the constants are autoloaded on first use rather than
    # while this file is still being loaded.
    def default_filters
      [DescriptionOnly.new, Rating.new]
    end
  end
end
