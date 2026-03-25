module ReviewFilters
  # `?description_only=true` keeps only reviews that actually say something.
  # Blank descriptions are normalised to NULL on write (see Review), so the
  # scope only has to exclude NULL and the empty string.
  class DescriptionOnly
    def param_name
      :description_only
    end

    def apply(scope, value)
      return scope unless ActiveModel::Type::Boolean.new.cast(value)

      scope.descriptive_only
    end
  end
end
