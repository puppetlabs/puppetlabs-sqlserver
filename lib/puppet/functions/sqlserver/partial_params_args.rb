# frozen_string_literal: true

# @summary this function populates and returns the string of arguments which later gets injected in template.
# arguments that return string holds is conditional and decided by the the input given to function.

Puppet::Functions.create_function(:'sqlserver::partial_params_args') do
  # @param args contains
  #   Enum['ON', 'OFF'] $db_chaining
  #   Enum['ON', 'OFF'] $trustworthy
  #   String[1] $default_fulltext_language
  #   String[1] $default_language
  #   Optional[Enum['ON', 'OFF']] $nested_triggers
  #   Optional[Enum['ON', 'OFF']] $transform_noise_words
  #   Integer[1753, 9999] $two_digit_year_cutoff
  #
  # @return String
  #   Generated on the basis of provided values.
  #
  # Sample Input Output
  #
  # Input
  # args = {
  #   db_chaining: 'OFF',
  #   trustworthy: 'OFF',
  #   default_fulltext_language: 'English',
  #   default_language: 'us_english',
  #   two_digit_year_cutoff: 2049,
  #   nested_triggers: 'OFF',
  # }
  #
  # Output
  # "DB_CHAINING OFF,TRUSTWORTHY OFF,DEFAULT_FULLTEXT_LANGUAGE=[English]\n,DEFAULT_LANGUAGE = [us_english]\n,NESTED_TRIGGERS = OFF,TWO_DIGIT_YEAR_CUTOFF = 2049"

  dispatch :partial_params_args do
    param 'Hash', :args
    return_type 'Variant[String]'
  end

  def partial_params_args(args)
    partial_params = []
    partial_params << "DB_CHAINING #{args['db_chaining']}" if args['db_chaining']
    partial_params << "TRUSTWORTHY #{args['trustworthy']}" if args['trustworthy']
    partial_params << "DEFAULT_FULLTEXT_LANGUAGE=[#{args['default_fulltext_language']}]\n" if args['default_fulltext_language']
    partial_params << "DEFAULT_LANGUAGE = [#{args['default_language']}]\n" if args['default_language']
    partial_params << "NESTED_TRIGGERS = #{args['nested_triggers']}" if args['nested_triggers']
    partial_params << "TRANSFORM_NOISE_WORDS = #{args['transform_noise_words']}" if args['transform_noise_words']
    partial_params << "TWO_DIGIT_YEAR_CUTOFF = #{args['two_digit_year_cutoff']}" if args['two_digit_year_cutoff']
    partial_params.join(',')
  end
end
