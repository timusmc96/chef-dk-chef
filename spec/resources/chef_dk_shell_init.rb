# encoding: utf-8
# frozen_string_literal: true

require_relative '../resources'

shared_context 'resources::chef_dk_shell_init' do
  include_context 'resources'

  let(:resource) { 'chef_dk_shell_init' }
  let(:properties) { {} }
  let(:name) { nil }

  let(:root_bashrc) { nil }
  let(:user_bashrc) { nil }
  let(:exist?) { true }
  let(:enabled?) { false }

  before(:each) do
    content = <<-EOH.gsub(/^ +/, '').strip
      # Here is a
      # bashrc
    EOH
    content = "#{content}\neval \"$(chef shell-init bash)\"" if enabled?
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(
      name == 'root' ? root_bashrc : user_bashrc
    ).and_return(exist?)
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(
      name == 'root' ? root_bashrc : user_bashrc
    ).and_return(content)
  end

  shared_examples_for 'any supported platform' do
    context 'the default action (:enable)' do
      context 'the root user' do
        let(:name) { 'root' }

        context 'disabled' do
          it 'writes the expected content to the bashrc' do
            expected = <<-EOH.gsub(/^ +/, '').strip
              # Here is a
              # bashrc
              eval "$(chef shell-init bash)"
            EOH
            expect(chef_run).to create_file(root_bashrc).with(content: expected)
          end
        end

        context 'already enabled' do
          let(:enabled?) { true }

          it 'writes the expected content to the bashrc' do
            expected = <<-EOH.gsub(/^ +/, '').strip
              # Here is a
              # bashrc
              eval "$(chef shell-init bash)"
            EOH
            expect(chef_run).to create_file(root_bashrc).with(content: expected)
          end
        end
      end

      context 'a non-root user' do
        let(:name) { 'fauxhai' }

        context 'disabled' do
          it 'writes the expected content to the bashrc' do
            expected = <<-EOH.gsub(/^ +/, '').strip
              # Here is a
              # bashrc
              eval "$(chef shell-init bash)"
            EOH
            expect(chef_run).to create_file(user_bashrc).with(content: expected)
          end
        end

        context 'already enabled' do
          let(:enabled?) { true }

          it 'writes the expected content to the bashrc' do
            expected = <<-EOH.gsub(/^ +/, '').strip
              # Here is a
              # bashrc
              eval "$(chef shell-init bash)"
            EOH
            expect(chef_run).to create_file(user_bashrc).with(content: expected)
          end
        end
      end
    end

    context 'the :disable action' do
      let(:action) { :disable }

      context 'the root user' do
        let(:name) { 'root' }

        context 'enabled' do
          let(:enabled?) { true }

          it 'writes the expected content to the bashrc' do
            expected = <<-EOH.gsub(/^ +/, '').strip
              # Here is a
              # bashrc
            EOH
            expect(chef_run).to create_file(root_bashrc).with(content: expected)
          end
        end

        context 'already disabled' do
          it 'writes the expected content to the bashrc' do
            expected = <<-EOH.gsub(/^ +/, '').strip
              # Here is a
              # bashrc
            EOH
            expect(chef_run).to create_file(root_bashrc).with(content: expected)
          end
        end
      end

      context 'a non-root user' do
        let(:name) { 'fauxhai' }

        context 'enabled' do
          let(:enabled?) { true }

          it 'writes the expected content to the bashrc' do
            expected = <<-EOH.gsub(/^ +/, '').strip
              # Here is a
              # bashrc
            EOH
            expect(chef_run).to create_file(user_bashrc).with(content: expected)
          end
        end

        context 'already disabled' do
          it 'writes the expected content to the bashrc' do
            expected = <<-EOH.gsub(/^ +/, '').strip
              # Here is a
              # bashrc
            EOH
            expect(chef_run).to create_file(user_bashrc).with(content: expected)
          end
        end
      end

      context 'a user who has no bashrc' do
        let(:name) { 'fauxhai' }
        let(:exist?) { false }

        it 'does not write the bashrc file' do
          expect(chef_run).to_not create_file(user_bashrc)
        end
      end
    end
  end
end
