# frozen_string_literal: true

module Spree
  class LogEntry < Spree::Base
    # Ruby 3.1+: YAML.load defaults to safe_load, which rejects arbitrary
    # classes. Permit the classes that appear in serialized payment gateway
    # responses. Mirrors solidusio/solidus#4366 (and the CORE_PERMITTED_CLASSES
    # list it later grew into).
    PERMITTED_CLASSES = [
      ActiveMerchant::Billing::Response,
      ActiveSupport::TimeWithZone,
      ActiveSupport::TimeZone,
      Time
    ].freeze

    belongs_to :source, polymorphic: true, optional: true

    def parsed_details
      @details ||= YAML.safe_load(details, permitted_classes: PERMITTED_CLASSES)
    end
  end
end
