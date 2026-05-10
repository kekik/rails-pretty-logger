require "test_helper"
require "rails/generators"
require "rails/generators/test_case"
require "generators/rails_pretty_logger/install/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests RailsPrettyLogger::Generators::InstallGenerator
  destination Rails.root.join("tmp", "generators", "install")

  setup do
    prepare_destination
    FileUtils.mkdir_p(File.join(destination_root, "config"))
    File.write(File.join(destination_root, "config", "routes.rb"), <<~RUBY)
      Rails.application.routes.draw do
      end
    RUBY
  end

  test "creates initializer" do
    run_generator

    assert_file "config/initializers/rails_pretty_logger.rb" do |initializer|
      assert_includes initializer, "Rails::Pretty::Logger.configure"
      assert_includes initializer, "config.read_only = Rails.env.production?"
      assert_includes initializer, "config.max_file_size = 50.megabytes"
    end
  end

  test "mounts engine route" do
    run_generator

    assert_file "config/routes.rb", /mount Rails::Pretty::Logger::Engine => "\/rails-pretty-logger"/
  end
end
