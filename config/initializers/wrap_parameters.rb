# Every controller permits top-level parameters and never reads the copy that
# ActionController::ParamsWrapper nests under the resource name. The wrapper
# also parses JSON bodies before `rescue_from` is in scope, which would send a
# malformed body past the API's error contract, so it is switched off.
ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: []
end
