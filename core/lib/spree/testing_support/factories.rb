# frozen_string_literal: true

require 'spree/testing_support/factory_bot'

# Rails 8: drop the String-callstack arg from Deprecation#warn (AS 8 requires backtrace Locations); matches Solidus 4.5
Spree::Deprecation.warn(
  "Please do not try to load factories directly. " \
  'Use factory_bot_rails and rely on the default configuration instead.'
)

Spree::TestingSupport::FactoryBot.check_version
Spree::TestingSupport::FactoryBot::PATHS.each { |path| require path }
