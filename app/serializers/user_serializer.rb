class UserSerializer < ApplicationSerializer
  # Compact form embedded inside other resources. Reviews are far more useful
  # with a name attached than with a bare `user_id`, but they have no business
  # carrying the user's full record around.
  def self.summary(user)
    return nil if user.nil?

    {
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name
    }
  end

  def as_json
    {
      id: record.id,
      first_name: record.first_name,
      last_name: record.last_name,
      created_at: record.created_at,
      updated_at: record.updated_at
    }
  end
end
