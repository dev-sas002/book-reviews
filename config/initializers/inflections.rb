# `app/controllers/api/` holds API::BooksController, not Api::BooksController.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym('API')
end
