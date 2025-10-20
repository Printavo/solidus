# frozen_string_literal: true

module Spree
  module Core
    module ControllerHelpers
      module CurrentHost
        extend ActiveSupport::Concern

        included do
          before_action do
            ActiveStorage::Current.url_options = { host: request.host }
          end
        end
      end
    end
  end
end
