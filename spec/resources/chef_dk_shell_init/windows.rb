# encoding: utf-8
# frozen_string_literal: true

require_relative '../chef_dk_shell_init'

shared_context 'resources::chef_dk_shell_init::windows' do
  include_context 'resources::chef_dk_shell_init'

  shared_examples_for 'any Windows platform' do
    it 'raises an error' do
      expect { chef_run }.to raise_error(NotImplementedError)
    end
  end
end
