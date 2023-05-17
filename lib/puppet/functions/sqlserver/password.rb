# frozen_string_literal: true

# @summary This function exists for usage of a role password that is a deferred function
Puppet::Functions.create_function(:'sqlserver::password') do
  dispatch :password do
    optional_param 'Any', :pass
    return_type 'Any'
  end

  # the function below is called by puppet and and must match
  # the name of the puppet function above. You can set your
  def password(pass)
    pass
  end
end
