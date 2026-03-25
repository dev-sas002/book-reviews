module ReviewFilters
  # `?rating=4` keeps only reviews with exactly that rating. Anything that is
  # not a whole number in 1..5 is ignored rather than rejected: a filter is a
  # refinement, not a command, and a garbage value should not 400 a read.
  class Rating
    def param_name
      :rating
    end

    def apply(scope, value)
      return scope if value.blank?

      # Base 10 explicitly: Integer("08") raises and Integer("010") would
      # otherwise be parsed as octal 8.
      rating = Integer(value.to_s.strip, 10)
      return scope unless Review::RATING_RANGE.cover?(rating)

      scope.where(rating: rating)
    rescue ArgumentError, TypeError
      scope
    end
  end
end
