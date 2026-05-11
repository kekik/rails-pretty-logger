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
    FileUtils.mkdir_p(File.join(destination_root, "app/assets/config"))
    File.write(File.join(destination_root, "config", "routes.rb"), <<~RUBY)
      Rails.application.routes.draw do
      end
    RUBY
    File.write(File.join(destination_root, "app/assets/config/manifest.js"), <<~JS)
      //= link_tree ../images
      //= link_directory ../stylesheets .css
    JS
  end

  test "creates initializer" do
    run_generator

    assert_file "config/initializers/rails_pretty_logger.rb" do |initializer|
      assert_includes initializer, "Rails::Pretty::Logger.configure"
      assert_includes initializer, "config.read_only = Rails.env.production?"
      assert_includes initializer, "config.max_file_size = 50.megabytes"
      assert_includes initializer, "config.tail_lines = 500"
      assert_includes initializer, "config.log_line_parser"
    end
  end

  test "mounts engine route" do
    run_generator

    assert_file "config/routes.rb", /mount Rails::Pretty::Logger::Engine => "\/rails-pretty-logger"/
  end

  test "links javascript asset in sprockets manifest" do
    run_generator

    assert_file "app/assets/config/manifest.js" do |manifest|
      assert_includes manifest, "//= link rails/pretty/logger/application.js"
    end
  end

  test "does not duplicate javascript asset link" do
    manifest_path = File.join(destination_root, "app/assets/config/manifest.js")
    File.write(manifest_path, "//= link rails/pretty/logger/application.js\n")

    run_generator

    assert_equal 1, File.read(manifest_path).scan("//= link rails/pretty/logger/application.js").count
  end
end
