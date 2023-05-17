# frozen_string_literal: true

require 'spec_helper'

describe 'sqlserver::password' do
  # please note that these tests are examples only
  # you will need to replace the params and return value
  # with your expectations
  it { is_expected.to run.with_params('password').and_return('password') }
  it { is_expected.to run.with_params(nil).and_return(nil) }
end
