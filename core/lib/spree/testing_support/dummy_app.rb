# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'
ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = '1'

require 'rails'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'

Rails.env = 'test'

require 'solidus_core'

RAILS_6_OR_ABOVE = Rails.gem_version >= Gem::Version.new('6.0')

# @private
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end

# @private
class ApplicationRecord < ActiveRecord::Base
end

# @private
class ApplicationMailer < ActionMailer::Base
end

# @private
module ApplicationHelper
end

# @private
module DummyApp
  def self.setup(gem_root:, lib_name:, auto_migrate: true)
    ENV["LIB_NAME"] = lib_name
    # Sprockets 4: a manifest file is required to boot; mirrors solidusio/solidus#3379
    root = Pathname(gem_root).join('spec/dummy')
    root.join("app/assets/config").mkpath
    root.join("app/assets/config/manifest.js").write("// Intentionally empty\n")

    DummyApp::Application.config.root = root

    DummyApp::Application.initialize!

    if auto_migrate
      DummyApp::Migrations.auto_migrate
    end
  end

  class Application < ::Rails::Application
    # HashWithIndifferentAccess: promotion rule preferences arrive from params
    # and are stored in serialized YAML preference columns (mirrors solidusio/solidus#4451).
    config.active_record.yaml_column_permitted_classes = [BigDecimal, Date, Symbol, Time, ActiveSupport::HashWithIndifferentAccess]
    config.after_initialize { ActiveRecord.yaml_column_permitted_classes |= [Spree::Role] }
    config.has_many_inverse = true
    config.eager_load = false
    config.cache_classes = true
    config.cache_store = :memory_store
    config.serve_static_assets = true
    config.public_file_server.headers = { 'Cache-Control' => 'public, max-age=3600' }
    config.whiny_nils = true
    config.consider_all_requests_local = true
    config.action_controller.allow_forgery_protection = false
    config.action_controller.default_protect_from_forgery = false
    config.action_controller.perform_caching = false
    # Rails 7.1: show_exceptions takes a symbol; :none re-raises (false no
    # longer does), which specs rely on to assert routing errors. Mirrors
    # solidusio/solidus#4451 dummy_app changes.
    config.action_dispatch.show_exceptions = Rails.gem_version >= Gem::Version.new("7.1") ? :none : false
    config.active_support.deprecation = :stderr
    config.action_mailer.delivery_method = :test
    config.active_support.deprecation = :stderr
    config.secret_key_base = 'SECRET_TOKEN'

    config.action_mailer.delivery_job = "ActionMailer::MailDeliveryJob" if RAILS_6_OR_ABOVE
    # Rails 7.1: preview_path renamed to preview_paths (matches Solidus 4.5)
    config.action_mailer.preview_paths = [File.expand_path('dummy_app/mailer_previews', __dir__)]
    config.active_record.sqlite3.represent_boolean_as_integer = true unless RAILS_6_OR_ABOVE

    config.storage_path = Rails.root.join('tmp', 'storage')

    if ENV['ENABLE_ACTIVE_STORAGE']
      initializer 'solidus.active_storage' do
        config.active_storage.service_configurations = {
          test: {
            service: 'Disk',
            root: config.storage_path
          }
        }
        config.active_storage.service = :test
        config.active_storage.variant_processor = ENV.fetch('ACTIVE_STORAGE_VARIANT_PROCESSOR', :mini_magick).to_sym
      end
    end

    # Avoid issues if an old spec/dummy still exists
    config.paths['config/initializers'] = []
    config.paths['config/environments'] = []

    migration_dirs = Rails.application.migration_railties.flat_map do |engine|
      if engine.respond_to?(:paths)
        engine.paths['db/migrate'].to_a
      else
        []
      end
    end
    config.paths['db/migrate'] = migration_dirs
    ActiveRecord::Migrator.migrations_paths = migration_dirs

    config.action_controller.include_all_helpers = false

    if config.respond_to?(:assets)
      config.assets.paths << File.expand_path('dummy_app/assets/javascripts', __dir__)
      config.assets.paths << File.expand_path('dummy_app/assets/stylesheets', __dir__)
    end

    config.paths["config/database"] = File.expand_path('dummy_app/database.yml', __dir__)
    config.paths['app/views'] = File.expand_path('dummy_app/views', __dir__)
    config.paths['config/routes.rb'] = File.expand_path('dummy_app/routes.rb', __dir__)

    ActionMailer::Base.default from: "store@example.com"
  end
end

require 'spree/testing_support/dummy_app/migrations'

ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: [:json]
end

Spree.user_class = 'Spree::LegacyUser'
Spree.config do |config|
  config.use_legacy_address_state_validator = false
  config.mails_from = "store@example.com"
  config.raise_with_invalid_currency = false
  config.redirect_back_on_unauthorized = true
  config.run_order_validations_on_order_updater = true
  config.use_combined_first_and_last_name_in_address = true
  config.use_legacy_order_state_machine = false
  config.use_custom_cancancan_actions = false
  config.consider_actionless_promotion_active = false
  config.use_legacy_store_credit_reimbursement_category_name = false

  if ENV['ENABLE_ACTIVE_STORAGE']
    config.image_attachment_module = 'Spree::Image::ActiveStorageAttachment'
    config.taxon_attachment_module = 'Spree::Taxon::ActiveStorageAttachment'
  end
end

# Raise on deprecation warnings
if ENV['SOLIDUS_RAISE_DEPRECATIONS'].present?
  Spree::Deprecation.behavior = :raise
end
