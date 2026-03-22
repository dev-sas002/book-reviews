# Partial matches: :passw also filters :password_confirmation, and so on.
Rails.application.config.filter_parameters += %i[
  passw email secret token _key crypt salt certificate otp ssn cvv cvc
]
