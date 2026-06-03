# frozen_string_literal: true

require 'spec_helper'

describe Spree::Admin::ShippingMethodsController, type: :controller do
  stub_authorization!

  # Regression test for https://github.com/spree/spree/issues/1240
  it "should not hard-delete shipping methods" do
    # Rails 7.1: discard + stub_model no longer round-trips through reload;
    # use a persisted record. Mirrors solidusio/solidus#4220.
    shipping_method = create(:shipping_method)

    delete :destroy, params: { id: shipping_method.id }

    expect(shipping_method.reload.deleted_at).not_to be_nil
  end
end
