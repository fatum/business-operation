require "spec_helper"

RSpec.describe Business::Operation::Contract do
  class TestModel
    attr_reader :key

    def initialize
      @key = 1
    end
  end

  TestForm = Class.new

  let(:form) { spy(:form) }

  let(:operation) do
    Class.new(Business::Operation::Base) do
      step Business::Operation::Model, class: TestModel
      step Business::Operation::Contract, class: TestForm
    end
  end

  let(:params) { Hash[key: :value] }

  subject(:run_operation) { operation.(params) }

  before do
    allow(TestForm).to receive(:new).and_return(form)
    allow(form).to receive(:validate).and_return(true)
    allow(form).to receive(:save).and_return(true)
  end

  it "initializes state" do
    expect(run_operation).to be_successful
    expect(run_operation[:model]).to be_a(TestModel)
    expect(run_operation[:contract]).to eq(form)
  end

  it "calls validate and persist methods on contract" do
    run_operation

    expect(form).to have_received(:validate).with(params)
    expect(form).to have_received(:save)
  end

  context "when disabled validation" do
    let(:operation) do
      Class.new(Business::Operation::Base) do
        step Business::Operation::Model, class: TestModel
        step Business::Operation::Contract,
             class: TestForm,
             validate: false
      end
    end

    it "doesn't call validate and persist methods on contract" do
      expect(run_operation).to be_successful

      expect(form).to_not have_received(:validate).with(params)
      expect(form).to_not have_received(:save)
    end
  end
end
