# frozen_string_literal: true

require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'sqlserver_install_context.rb'))

RSpec.describe Puppet::Type.type(:sqlserver_features) do
  let(:error_class) { Puppet::Error }

  describe 'features' do
    ['Tools'].each do |feature_name|
      it "raises deprecation warning with super feature #{feature_name}" do
        args = {
          name: 'Generic Features',
          ensure: 'present',
          features: [feature_name]
        }
        expect(Puppet).to receive(:deprecation_warning).at_least(:once)
        Puppet::Type.type(:sqlserver_features).new(args)
      end
    end
  end
end
