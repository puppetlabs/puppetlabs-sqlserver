# frozen_string_literal: true

require 'spec_helper'

describe 'sqlserver::password' do
  it { is_expected.to run.with_params('password').and_return('password') }
  it { is_expected.to run.with_params(nil).and_return(nil) }
end
