class AuthorSerializer < ApplicationSerializer
  def as_json
    {
      id: record.id,
      first_name: record.first_name,
      last_name: record.last_name,
      website: record.website,
      genres: record.genres,
      description: record.description,
      created_at: record.created_at,
      updated_at: record.updated_at
    }
  end
end
