Rails::Pretty::Logger.configure do |config|
  # The hook runs inside the Rails Pretty Logger engine controller.
  # Example for apps that expose authenticate_user!:
  # config.authenticate_with = -> { authenticate_user! }
  config.authenticate_with = nil

  # Production dashboards should usually be read-only unless clearing logs is explicitly desired.
  config.read_only = Rails.env.production?

  # Set to nil to allow any log file size.
  config.max_file_size = 50.megabytes

  # Number of lines shown by the tail view.
  config.tail_lines = 500
end
