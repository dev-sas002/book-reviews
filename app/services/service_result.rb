# The value every service object in app/services returns.
#
# Services do not raise for expected failures and do not render: they hand the
# caller a value that says whether the operation succeeded, what it produced
# and, when it did not, the messages a client should see.
class ServiceResult
  attr_reader :value, :errors

  def self.success(value = nil)
    new(value: value, errors: [])
  end

  def self.failure(errors, value = nil)
    new(value: value, errors: Array(errors))
  end

  def initialize(value:, errors:)
    @value = value
    @errors = errors.freeze
    freeze
  end

  def success?
    errors.empty?
  end

  def failure?
    !success?
  end
end
