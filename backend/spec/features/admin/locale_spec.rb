# frozen_string_literal: true

require 'spec_helper'

describe "setting locale", type: :feature do
  stub_authorization!

  before do
    # Rails 6.1: option moved from ActionView to I18n (rails/rails#31571); mirrors solidusio/solidus#4220
    Rails.application.config.i18n.raise_on_missing_translations = false
    I18n.locale = I18n.default_locale
    I18n.backend.store_translations(:fr,
      date: {
        month_names: []
      },
      spree: {
        i18n: { this_file_language: "Français" },
        admin: {
          tab: { orders: "Ordres" }
        },
        listing_orders: "Ordres"
      })
    stub_spree_preferences(Spree::Backend::Config, locale: "fr")
  end

  after do
    I18n.locale = I18n.default_locale
    Rails.application.config.i18n.raise_on_missing_translations = true
  end

  it "should be in french" do
    visit spree.admin_path
    expect(page).to have_content("Ordres")
  end
end
