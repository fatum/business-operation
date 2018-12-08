# Business operation framework

## The main purpose of building this library was creating simple and composable business-logic framework

The framework is a relatively small and simple (~450 LOC) and has a great test coverage

## Main features

* Simple and concise API using conventions to define handlers
* We use only keywords for State's keys (it's more convinient). String keys are raising exception
* You can specify required state's keys for operation
* Great traceability: you can trace all your nested execution and see whole execution tree with options and state
* Simple integration with `dry-container` gem
* Handler is a simple class inherited from `Business::Operation::Base` or any callable. No more `Wrap`, `Nested(Operation, input: Input)` from Trailblazer

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'business-operation'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install business-operation

## Usage example

### Operation creates a new user

```ruby
require "business/operation"
require "business/operation/active_record_transaction"
require "dry-container"

module Operation
  Model = Business::Operation::Model
  Contract = Business::Operation::Contract
  Transaction = Business::Operation::ActiveRecordTransaction
end

Container = Dry::Container.new

class CreateUser < Business::Operation::Base
  container Container

  step Operation::Model, class: User
  step Operation::Contract,
       class: UserForm,
       key: :resource

  depends_on :state, %i[model contract]

  wrap Operation::Transaction do
    step CreateSubscription
    step ScheduleEmail
    step "container.global"
  end

  step Notifications::NewUser, fail: false

  failure :log_errors

  private

  def log_errors
    Rails.logger.error(helper.format)
  end

  def helper
    @helper ||= ConstractErrorFormatter.new(state[:contract])
  end
end
```

### What handlers you can define

Defining step you can choose between 3 types of handlers

* Another operation class (inherited from `Business::Operation::Base`)
* Current operation's method (using symbol – `step :call_method`)
* Operation class registered in dry-container (using string argument – `step "users.create"`)
* Any Proc – `step { |state| state[:key] = "value" }`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fatum/business-operation. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Business::Operation project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/fatum/business-operation/blob/master/CODE_OF_CONDUCT.md).
