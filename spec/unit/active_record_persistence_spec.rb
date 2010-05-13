require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'aasm')

begin
  require 'rubygems'
  require 'active_record'

  # A dummy class for mocking the activerecord connection class
  class Connection
  end

  class FooBar < ActiveRecord::Base
    include AASM

    # Fake this column for testing purposes
    attr_accessor :aasm_state

    aasm_state :open
    aasm_state :closed

    aasm_event :view do
      transitions :to => :read, :from => [:needs_attention]
    end
  end

  class Fi < ActiveRecord::Base
    def aasm_read_state
      "fi"
    end
    include AASM
  end

  class Fo < ActiveRecord::Base
    def aasm_write_state(state)
      "fo"
    end
    include AASM
  end

  class Fum < ActiveRecord::Base
    def aasm_write_state_without_persistence(state)
      "fum"
    end
    include AASM
  end

  class June < ActiveRecord::Base
    include AASM
    aasm_column :status
  end

  class Beaver < June
  end

  class Thief < ActiveRecord::Base
    include AASM
    aasm_initial_state  Proc.new { |thief| thief.skilled ? :rich : :jailed }
    aasm_state          :rich
    aasm_state          :jailed
    attr_accessor :skilled, :aasm_state
  end

  class Doomed < ActiveRecord::Base
    include AASM

    aasm_initial_state :alive
    aasm_state :alive
    aasm_state :dead

    aasm_event :die do
      transitions :to => :dead, :from => :alive
    end

    def aasm_state
      read_attribute(:aasm_state)
    end

    def aasm_state=(state)
      write_attribute(:aasm_state, state)
    end

    validate :failing_validation

    def failing_validation
      errors.add_to_base('Hi Mom!')
      errors.add_to_base('Dad, you suck')
    end

    # We don't have a db connection so mimic ActiveRecord behaviour
    def save
      valid?
    end
  end

  describe "aasm model", :shared => true do
    it "should include AASM::Persistence::ActiveRecordPersistence" do
      @klass.included_modules.should be_include(AASM::Persistence::ActiveRecordPersistence)
    end
    it "should include AASM::Persistence::ActiveRecordPersistence::InstanceMethods" do
      @klass.included_modules.should be_include(AASM::Persistence::ActiveRecordPersistence::InstanceMethods)
    end

    it "should respond to aasm_raise_on_persistence_failure" do
      @klass.should respond_to(:aasm_raise_on_persistence_failure)
    end
  end

  describe FooBar, "class methods" do
    before(:each) do
      @klass = FooBar
    end
    it_should_behave_like "aasm model"
    it "should include AASM::Persistence::ActiveRecordPersistence::ReadState" do
      @klass.included_modules.should be_include(AASM::Persistence::ActiveRecordPersistence::ReadState)
    end
    it "should include AASM::Persistence::ActiveRecordPersistence::WriteState" do
      @klass.included_modules.should be_include(AASM::Persistence::ActiveRecordPersistence::WriteState)
    end
    it "should include AASM::Persistence::ActiveRecordPersistence::WriteStateWithoutPersistence" do
      @klass.included_modules.should be_include(AASM::Persistence::ActiveRecordPersistence::WriteStateWithoutPersistence)
    end
  end

  describe Fi, "class methods" do
    before(:each) do
      @klass = Fi
    end
    it_should_behave_like "aasm model"
    it "should not include AASM::Persistence::ActiveRecordPersistence::ReadState" do
      @klass.included_modules.should_not be_include(AASM::Persistence::ActiveRecordPersistence::ReadState)
    end
    it "should include AASM::Persistence::ActiveRecordPersistence::WriteState" do
      @klass.included_modules.should be_include(AASM::Persistence::ActiveRecordPersistence::WriteState)
    end
    it "should include AASM::Persistence::ActiveRecordPersistence::WriteStateWithoutPersistence" do
      @klass.included_modules.should be_include(AASM::Persistence::ActiveRecordPersistence::WriteStateWithoutPersistence)
    end
  end

  describe Fo, "class methods" do
    before(:each) do
      @klass = Fo
    end
    it_should_behave_like "aasm model"
    it "should include AASM::Persistence::ActiveRecordPersistence::ReadState" do
      @klass.included_modules.should be_include(AASM::Persistence::ActiveRecordPersistence::ReadState)
    end
    it "should not include AASM::Persistence::ActiveRecordPersistence::WriteState" do
      @klass.included_modules.should_not be_include(AASM::Persistence::ActiveRecordPersistence::WriteState)
    end
    it "should include AASM::Persistence::ActiveRecordPersistence::WriteStateWithoutPersistence" do
      @klass.included_modules.should be_include(AASM::Persistence::ActiveRecordPersistence::WriteStateWithoutPersistence)
    end
  end

  describe Fum, "class methods" do
    before(:each) do
      @klass = Fum
    end
    it_should_behave_like "aasm model"
    it "should include AASM::Persistence::ActiveRecordPersistence::ReadState" do
      @klass.included_modules.should be_include(AASM::Persistence::ActiveRecordPersistence::ReadState)
    end
    it "should include AASM::Persistence::ActiveRecordPersistence::WriteState" do
      @klass.included_modules.should be_include(AASM::Persistence::ActiveRecordPersistence::WriteState)
    end
    it "should not include AASM::Persistence::ActiveRecordPersistence::WriteStateWithoutPersistence" do
      @klass.included_modules.should_not be_include(AASM::Persistence::ActiveRecordPersistence::WriteStateWithoutPersistence)
    end
  end

  describe "a fake model", :shared => true do
    before(:each) do
      connection = mock(Connection, :columns => [])
      klass.stub!(:connection).and_return(connection)
    end
  end

  describe FooBar, "instance methods" do
    it_should_behave_like "a fake model"

    def klass
      FooBar
    end

    it "should respond to aasm read state when not previously defined" do
      FooBar.new.should respond_to(:aasm_read_state)
    end

    it "should respond to aasm write state when not previously defined" do
      FooBar.new.should respond_to(:aasm_write_state)
    end

    it "should respond to aasm write state without persistence when not previously defined" do
      FooBar.new.should respond_to(:aasm_write_state_without_persistence)
    end

    it "should return the initial state when new and the aasm field is nil" do
      FooBar.new.aasm_current_state.should == :open
    end

    it "should return the aasm column when new and the aasm field is not nil" do
      foo = FooBar.new
      foo.aasm_state = "closed"
      foo.aasm_current_state.should == :closed
    end

    it "should return the aasm column when not new and the aasm_column is not nil" do
      foo = FooBar.new
      foo.stub!(:new_record?).and_return(false)
      foo.aasm_state = "state"
      foo.aasm_current_state.should == :state
    end

    it "should allow a nil state" do
      foo = FooBar.new
      foo.stub!(:new_record?).and_return(false)
      foo.aasm_state = nil
      foo.aasm_current_state.should be_nil
    end

    it "should have aasm_ensure_initial_state" do
      foo = FooBar.new
      foo.send :aasm_ensure_initial_state
    end

    it "should call aasm_ensure_initial_state on validation before create" do
      foo = FooBar.new
      foo.should_receive(:aasm_ensure_initial_state).and_return(true)
      foo.valid?
    end

    it "should call aasm_ensure_initial_state on validation before create" do
      foo = FooBar.new
      foo.stub!(:new_record?).and_return(false)
      foo.should_not_receive(:aasm_ensure_initial_state)
      foo.valid?
    end
  end


  describe Doomed, "- when persisting with error raising" do
    it_should_behave_like "a fake model"

    def klass
      Doomed
    end

    before(:each) do
      @doomed = Doomed.new
    end

    it "should default to not raising errors" do
      FooBar.aasm_raise_on_persistence_failure.should be_false
      expect { @doomed.die! }.should_not raise_error
    end

    it "should not raise an error if raising is explicitly disabled" do
      FooBar.aasm_raise_on_persistence_failure false
      expect { @doomed.die! }.should_not raise_error
    end

    it "should raise an error if raising is enabled" do
      Doomed.aasm_raise_on_persistence_failure true
      expect { @doomed.die! }.should raise_error(AASM::PersistenceError)
    end

    it "should raise an error with an accessor for the invalid model instance" do
      Doomed.aasm_raise_on_persistence_failure true

      begin
        @doomed.die!
      rescue AASM::PersistenceError => e
        e.model.errors.on(:base).sort.should == ['Hi Mom!', 'Dad, you suck'].sort
      end
    end

    it "should give a detailed message about the sate transition that failed for new records" do
      Doomed.aasm_raise_on_persistence_failure true
      @doomed.aasm_state = :alive

      begin
        @doomed.die!
      rescue AASM::PersistenceError => e
        e.message.should == "Failed to transition Doomed(new record) from state 'alive' to 'dead': 'Hi Mom!', 'Dad, you suck'"
      end
    end

    it "should give a detailed message about the sate transition that failed for existing records" do
      Doomed.aasm_raise_on_persistence_failure true
      @doomed.aasm_state = :alive

      class << @doomed
        def new_record?
          false
        end

        def id
          69
        end
      end

      begin
        @doomed.die!
      rescue AASM::PersistenceError => e
        e.message.should == "Failed to transition Doomed(69) from state 'alive' to 'dead': 'Hi Mom!', 'Dad, you suck'"
      end
    end

    it "should not rollback the state if save fails" do
      Doomed.aasm_raise_on_persistence_failure true
      begin
        @doomed.aasm_state = :alive
        @doomed.die!
      rescue AASM::PersistenceError => e
        @doomed.aasm_state.should == 'dead'
      end
    end
  end


  describe 'Beavers' do
    it "should have the same states as it's parent" do
      Beaver.aasm_states.should == June.aasm_states
    end

    it "should have the same events as it's parent" do
      Beaver.aasm_events.should == June.aasm_events
    end

    it "should have the same column as it's parent" do
      Beaver.aasm_column.should == :status
    end
  end

  describe AASM::Persistence::ActiveRecordPersistence::NamedScopeMethods do
    class NamedScopeExample < ActiveRecord::Base
      include AASM
    end

    context "Does not already respond_to? the scope name" do
      it "should add a named_scope" do
        NamedScopeExample.should_receive(:named_scope)
        NamedScopeExample.aasm_state :unknown_scope
      end
    end

    context "Already respond_to? the scope name" do
      it "should not add a named_scope" do
        NamedScopeExample.should_not_receive(:named_scope)
        NamedScopeExample.aasm_state :new
      end
    end
  end

  describe 'Thieves' do
    before(:each) do
      connection = mock(Connection, :columns => [])
      Thief.stub!(:connection).and_return(connection)
    end

    it 'should be rich if they\'re skilled' do
      Thief.new(:skilled => true).aasm_current_state.should == :rich
    end

    it 'should be jailed if they\'re unskilled' do
      Thief.new(:skilled => false).aasm_current_state.should == :jailed
    end
  end

  # TODO: figure out how to test ActiveRecord reload! without a database

rescue LoadError => e
  if e.message == "no such file to load -- active_record"
    puts "You must install active record to run this spec.  Install with sudo gem install activerecord"
  else
    raise
  end
end
