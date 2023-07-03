# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolidusAdmin::MainNavItem do
  describe "#with_child" do
    it "returns a new instance" do
      item = described_class.new(key: "foo", route: :foo_path, position: 1)

      result = item.with_child(key: "bar", route: :bar_path, position: 1)

      aggregate_failures do
        expect(result).to be_a(described_class)
        expect(result).not_to be(item)
      end
    end

    it "keeps the item attributes" do
      item = described_class.new(key: "foo", route: :foo_path, position: 1, icon: "icon", top_level: true)

      result = item.with_child(key: "bar", route: :bar_path, position: 1)

      aggregate_failures do
        expect(result.key).to eq("foo")
        expect(result.route).to eq(:foo_path)
        expect(result.position).to eq(1)
        expect(result.icon).to eq("icon")
        expect(result.top_level).to be(true)
      end
    end

    it "adds a child to the item" do
      item = described_class.new(
        key: "foo", route: :foo_path, position: 1, children: [described_class.new(key: "bar", route: :bar_path, position: 1)]
      )

      result = item.with_child(key: "baz", route: :baz_path, position: 1)

      expect(result.children.count).to be(2)
    end

    it "sets child as not top level" do
      item = described_class.new(key: "foo", route: :foo_path, position: 1)

      result = item.with_child(key: "bar", route: :bar_path, position: 1)

      expect(result.children.first.top_level).to be(false)
    end
  end

  describe "#children?" do
    it "returns false when there are no children" do
      item = described_class.new(key: "foo", route: :foo_path, position: 1)

      expect(item.children?).to be(false)
    end

    it "returns true when there are children" do
      item = described_class.new(
        key: "foo", route: :foo_path, position: 1, children: [described_class.new(key: "bar", route: :bar_path, position: 1)]
      )

      expect(item.children?).to be(true)
    end
  end

  describe "#path" do
    context "when the route is a symbol" do
      it "calls that method on the url_helpers" do
        item = described_class.new(key: "foo", route: :foo_path, position: 1)
        url_helpers = Module.new do
          def self.foo_path
            "/foo"
          end
        end

        expect(item.path(url_helpers)).to eq("/foo")
      end
    end

    context "when the route is a Proc" do
      it "yields the url_helpers to it" do
        item = described_class.new(key: "foo", route: -> { _1.foo_path }, position: 1)
        url_helpers = Module.new do
          def self.foo_path
            "/foo"
          end
        end

        expect(item.path(url_helpers)).to eq("/foo")
      end
    end
  end
end