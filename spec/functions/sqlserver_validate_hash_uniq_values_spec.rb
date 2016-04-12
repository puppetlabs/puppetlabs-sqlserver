require 'spec_helper'

describe "the sqlserver_validate_hash_uniq_values" do
  it "should exist" do
    expect(Puppet::Parser::Functions.function("sqlserver_validate_hash_uniq_values")).to eq("function_sqlserver_validate_hash_uniq_values")
  end

  it "should accept mixed value types of string and string[]" do
    expect {
      scope.function_sqlserver_validate_hash_uniq_values([{'test' => 'this', 'and' => ['test', 'this']}])
    }.to raise_error
  end

  it "should pass validation" do
    expect {
      scope.function_sqlserver_validate_hash_uniq_values([{'test' => 'this', 'and' => ['test', 'another']}])
    }.to_not raise_error
  end

  it "should require a hash" do
    expect {
      scope.function_sqlserver_validate_hash_uniq_values(["MyString"])
    }.to raise_error
  end
end
