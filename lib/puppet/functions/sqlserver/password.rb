# frozen_string_literal: true

# This function exists for usage of a role password that is a deferred function
Puppet::Functions.create_function(:'sqlserver::password') do
  dispatch :password do
    optional_param 'Any', :pass
    return_type 'Any'
  end

  def password(pass)
    pass
  end
end
