# This file was generated by the `rspec --init` command. Given that it is always 
# loaded, you are encouraged to keep this file as light-weight as possible.

require './config/defaults'
require 'mongoid-rspec'

RSpec.configure do |config|
  config.include Mongoid::Matchers

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
