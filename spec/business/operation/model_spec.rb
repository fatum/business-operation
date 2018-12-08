require "spec_helper"

RSpec.describe Business::Operation::Model do
  class TestModel
    def initialize
    end
  end

  before do
    allow(TestModel).to receive(:new).and_call_original
  end

  subject(:run_operation) { described_class.(class: TestModel) }

  shared_examples_for "initialize model" do
    it "initializes a model" do
      expect(run_operation).to be_successful
      expect(run_operation[:model]).to be_a(TestModel)
      expect(TestModel).to have_received(:new)
    end
  end

  include_examples "initialize model"

  context "when using inside pipeline" do
    let(:operation) do
      Class.new(Business::Operation::Base) do
        step Business::Operation::Model, class: TestModel
      end
    end

    subject(:run_operation) { operation.() }

    include_examples "initialize model"
  end
end
