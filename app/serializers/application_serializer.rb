# Base class for the API's serializers.
#
# The API deliberately does not call `to_json` on Active Record objects. Doing
# so ties the wire format to the database schema, so every migration becomes a
# silent, untested change to the public contract. Each resource instead has an
# explicit serializer that lists the attributes it exposes.
class ApplicationSerializer
  # Serialize a single record. Returns nil for a nil record so that optional
  # associations serialize to `null` rather than blowing up.
  def self.one(record)
    return nil if record.nil?

    new(record).as_json
  end

  # Serialize a collection. The caller is responsible for eager loading
  # anything the serializer touches; see ReviewsQuery for an example.
  def self.many(records)
    records.map { |record| new(record).as_json }
  end

  def initialize(record)
    @record = record
  end

  def as_json
    raise NotImplementedError, "#{self.class} must implement #as_json"
  end

  private

  attr_reader :record
end
