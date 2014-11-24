require 'spec_helper'
require 'rspec'

RSpec.shared_context 'scope' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
end

RSpec.shared_examples 'compile' do

end

RSpec.shared_examples 'take arguments' do

end
