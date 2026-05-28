# frozen_string_literal: true

require 'rake/clean'

CLEAN.add(
  'lib/rapidyaml/rapidyaml.{bundle,so}',
  'lib/rapidyaml/[0-9].[0-9]',
  'pkg',
  'tmp'
)
