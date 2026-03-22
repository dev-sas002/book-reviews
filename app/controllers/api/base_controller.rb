module API
  # Shared CRUD for the three plain resources (authors, books, users).
  #
  # The subclasses declare *what* they operate on — a model, a serializer and a
  # parameter whitelist — and inherit *how* it is done. Anything with its own
  # behaviour, such as reviews, does not inherit from here.
  class BaseController < ApplicationController
    def index
      page = paginate(resource_scope)

      render json: serializer_class.many(page.records), status: :ok
    end

    def show
      render json: serializer_class.one(find_resource), status: :ok
    end

    def create
      resource = resource_class.new(allowed_params)

      if resource.save
        render json: serializer_class.one(resource), status: :created
      else
        render_errors(resource.errors.full_messages)
      end
    end

    def update
      resource = find_resource

      if resource.update(allowed_params)
        render json: serializer_class.one(resource), status: :ok
      else
        render_errors(resource.errors.full_messages)
      end
    end

    private

    # Ordered by id so that paging is deterministic; without an ORDER BY,
    # Postgres is free to return rows differently on each call and page 2 may
    # repeat or skip rows from page 1. Subclasses override to eager load.
    def resource_scope
      resource_class.order(:id)
    end

    def find_resource
      resource_scope.find(params[:id])
    end

    def resource_class
      raise NotImplementedError, "#{self.class} must implement #resource_class"
    end

    def serializer_class
      raise NotImplementedError, "#{self.class} must implement #serializer_class"
    end

    def allowed_params
      raise NotImplementedError, "#{self.class} must implement #allowed_params"
    end
  end
end
