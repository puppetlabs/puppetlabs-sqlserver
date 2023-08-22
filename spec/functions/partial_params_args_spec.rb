# frozen_string_literal: true

require 'spec_helper'

describe 'sqlserver::partial_params_args' do
  let(:params) do
    {
      db_chaining: 'OFF',
      trustworthy: 'OFF',
      default_fulltext_language: 'English',
      default_language: 'us_english',
      two_digit_year_cutoff: 2049
    }
  end

  it { is_expected.to run.with_params(nil).and_raise_error(StandardError) }

  it 'contains NESTED_TRIGGERS when nested_triggers is passed' do
    params[:nested_triggers] = 'OFF'
    expected_results = "DB_CHAINING OFF,TRUSTWORTHY OFF,DEFAULT_FULLTEXT_LANGUAGE=[English]\n,DEFAULT_LANGUAGE = [us_english]\n,NESTED_TRIGGERS = OFF,TWO_DIGIT_YEAR_CUTOFF = 2049"
    expect(subject).to run.with_params(params.transform_keys(&:to_s)).and_return(expected_results)
  end

  it 'contains TRANSFORM_NOISE_WORDS when transform_noise_words is passed' do
    params[:transform_noise_words] = 'ON'
    expected_results = "DB_CHAINING OFF,TRUSTWORTHY OFF,DEFAULT_FULLTEXT_LANGUAGE=[English]\n,DEFAULT_LANGUAGE = [us_english]\n,TRANSFORM_NOISE_WORDS = ON,TWO_DIGIT_YEAR_CUTOFF = 2049"
    expect(subject).to run.with_params(params.transform_keys(&:to_s)).and_return(expected_results)
  end
end
