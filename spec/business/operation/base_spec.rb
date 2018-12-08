require "spec_helper"
require "dry-container"

RSpec.describe Business::Operation::Base do
  Tracker = Class.new

  let(:params) { {} }

  describe "Instruction structure" do
    class AnotherOperation < Business::Operation::Base
      step :step2
      step :step3
      step :step4
      step ->(state) { state[:lambda] = true }
    end

    let(:operation) do
      Class.new(Business::Operation::Base) do
        wrap :in_transaction do
          step :step1

          wrap :inner_transaction, lock: :none do
            step AnotherOperation, key: :value
          end
        end
      end
    end

    subject(:instructions) { operation.instructions.to_a }

    it "builds correct instructions tree" do
      first_wrap = instructions[0]

      expect(first_wrap).to be_a(Business::Operation::Instruction::Wrap)
      expect(first_wrap.type).to eq(:wrap)
      expect(first_wrap.handler).to eq(:in_transaction)
      expect(first_wrap.children.size).to eq(2)

      child11 = first_wrap.children[0]
      child12 = first_wrap.children[1]

      expect(child11).to be_a(Business::Operation::Instruction)
      expect(child11.type).to eq(:step)
      expect(child11.handler).to eq(:step1)
      expect(child11.children).to be_empty

      expect(child12).to be_a(Business::Operation::Instruction::Wrap)
      expect(child12.type).to eq(:wrap)
      expect(child12.handler).to eq(:inner_transaction)
      expect(child12.options).to eq(Hash[lock: :none])
      expect(child12.children.size).to eq(1)

      child21 = child12.children[0]
      expect(child21).to be_a(Business::Operation::Instruction)
      expect(child21.type).to eq(:step)
      expect(child21.handler).to eq(AnotherOperation)
      expect(child21.children).to be_empty
    end
  end

  describe "method handlers" do
    ContainerTracker = Class.new do
      def initialize(state)
        @state = state
      end

      def call
        Tracker.container_step
      end
    end

    Container = Dry::Container.new
    Container.register("operations.tracker", ContainerTracker)
    Container.register("operations.tracker_factory") { ContainerTracker }

    class TestOperation < Business::Operation::Base
      container Container

      step :step1
      step :step2
      step { |state| state[:lambda1] = true }
      step ->(state) { state[:lambda2] = true }
      step "operations.tracker"
      step "operations.tracker_factory"

      def step1
        Tracker.step1
      end

      def step2
        Tracker.step2
      end
    end

    before do
      allow(Tracker).to receive(:step1).and_return(true)
      allow(Tracker).to receive(:step2).and_return(true)
      allow(Tracker).to receive(:container_step).and_return(true)
    end

    subject(:run_operation) { TestOperation.(params) }

    it "calls all steps" do
      expect(run_operation[:lambda1]).to eq(true)
      expect(run_operation[:lambda2]).to eq(true)
      expect(Tracker).to have_received(:step1)
      expect(Tracker).to have_received(:step2)
      expect(Tracker).to have_received(:container_step).twice
    end

    context "when the first step result is false" do
      let(:value) { false }

      before do
        allow(Tracker).to receive(:step1).and_return(value)
      end

      it "doesn't call the second step" do
        run_operation

        expect(Tracker).not_to have_received(:step2)
      end

      context "and the returned value is nil" do
        let(:value) { nil }

        it "doesn't call the second step" do
          run_operation

          expect(Tracker).not_to have_received(:step2)
        end
      end
    end
  end

  describe "nested handlers" do
    NestedTracker = Class.new

    class TestCallableOperation < Business::Operation::Base
      step :step5

      wrap :in_3nd_block do
        step :step6
      end

      def in_3nd_block(&block)
        NestedTracker.wrap3
        block.call
      end

      def step5
        NestedTracker.step5
      end

      def step6
        NestedTracker.step6
      end
    end

    class TestNestedOperation < Business::Operation::Base
      wrap :in_block do
        step :step1
        step :step2

        wrap :in_2nd_block do
          step :step3
          step :step4
          step TestCallableOperation, option1: 1, option2: 2
        end
      end

      def in_block
        NestedTracker.wrap1
        yield
      end

      def in_2nd_block
        NestedTracker.wrap2
        yield
      end

      def step1
        NestedTracker.step1
      end

      def step2
        NestedTracker.step2
      end

      def step3
        NestedTracker.step3
      end

      def step4
        NestedTracker.step4
      end
    end

    before do
      allow(NestedTracker).to receive(:wrap1).and_return(true)
      allow(NestedTracker).to receive(:wrap2).and_return(true)
      allow(NestedTracker).to receive(:wrap3).and_return(true)
      allow(NestedTracker).to receive(:step1).and_return(true)
      allow(NestedTracker).to receive(:step2).and_return(true)
      allow(NestedTracker).to receive(:step3).and_return(true)
      allow(NestedTracker).to receive(:step4).and_return(true)
      allow(NestedTracker).to receive(:step5).and_return(true)
      allow(NestedTracker).to receive(:step6).and_return(true)
    end

    subject(:run_operation) { TestNestedOperation.(params) }

    it "calls wrapped step" do
      run_operation

      expect(NestedTracker).to have_received(:wrap1)
      expect(NestedTracker).to have_received(:wrap2)
      expect(NestedTracker).to have_received(:wrap3)
      expect(NestedTracker).to have_received(:step1)
      expect(NestedTracker).to have_received(:step2)
      expect(NestedTracker).to have_received(:step3)
      expect(NestedTracker).to have_received(:step4)
      expect(NestedTracker).to have_received(:step5)
      expect(NestedTracker).to have_received(:step6)
    end
  end

  describe "success steps" do
    let(:operation) do
      Class.new(Business::Operation::Base) do
        step :notify, fail: false

        def notify
          false
        end
      end
    end

    subject(:run_operation) { operation.() }

    it { is_expected.to be_successful }
  end

  describe "failures" do
    let(:notify) { false }
    let(:options) { {} }
    let(:operation) do
      Class.new(Business::Operation::Base) do
        step :notify
        failure :failure1, Tracker.failure1_options
        failure :failure2

        def notify
          Tracker.notify
        end

        def failure1
          Tracker.failure1
        end

        def failure2
          Tracker.failure2
        end
      end
    end

    before do
      allow(Tracker).to receive(:notify).and_return(notify)
      allow(Tracker).to receive(:failure1_options).and_return(options)
      allow(Tracker).to receive(:failure1)
      allow(Tracker).to receive(:failure2)
    end

    subject(:run_operation) { operation.() }

    it "calls failure handlers" do
      run_operation

      expect(Tracker).to have_received(:failure1)
      expect(Tracker).to have_received(:failure2)
    end

    context "when operation doesn't fail" do
      let(:notify) { true }

      it "doesn't call failure handlers" do
        run_operation

        expect(Tracker).to_not have_received(:failure1)
        expect(Tracker).to_not have_received(:failure2)
      end
    end

    context "when operation doesn't fail" do
      let(:options) { Hash[fail_fast: true] }

      it "doesn't call handlers after failed fast handler" do
        run_operation

        expect(Tracker).to have_received(:failure1)
        expect(Tracker).to_not have_received(:failure2)
      end
    end
  end
end
