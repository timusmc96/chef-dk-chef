# Encoding: UTF-8
#
# Cookbook Name:: chef-dk
# Library:: provider/chef_dk
#
# Copyright 2014, Jonathan Hartman
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/provider'
require 'chef/provider/package/dpkg'
require 'chef/provider/package/rpm'
require_relative '../resource/chef_dk'

class Chef
  class Provider
    # A Chef provider for the Chef-DK packages
    #
    # @author Jonathan Hartman <j@p4nt5.com>
    class ChefDk < Provider
      PACKAGE_NAME = 'chefdk'
      LATEST_VERSION = '0.1.0-1'
      BASE_URL = 'https://opscode-omnibus-packages.s3.amazonaws.com'

      #
      # WhyRun is supported by this provider
      #
      # @return [TrueClass, FalseClass]
      #
      def whyrun_supported?
        true
      end

      #
      # Load and return the current resource
      #
      # @return [Chef::Resource::ChefDk]
      #
      def load_current_resource
        @current_resource ||= Resource::ChefDk.new(new_resource.name)
      end

      #
      # Download and install the ChefDk package
      #
      def action_install
        remote_file.run_action(:create)
        package.run_action(:install)
        new_resource.installed = true
      end

      #
      # Uninstall the ChefDk package and delete the cached file
      #
      def action_uninstall
        package.run_action(:uninstall)
        remote_file.run_action(:delete)
        new_resource.installed = false
      end

      private

      #
      # The Package resource for the package
      #
      # @return [Chef::Resource::Package]
      #
      def package
        @package ||= Resource::Package.new(local_package_path, run_context)
        @package.provider(
          case node['platform_family']
          when 'debian' then Provider::Package::Dpkg
          when 'rhel' then Provider::Package::Rpm
          end
        )
        @package.version(version)
        @package
      end

      #
      # The package version string
      #
      # @return [String]
      #
      def version
        @version ||= case new_resource.version.to_s
                     when '', 'latest'
                       LATEST_VERSION
                     else
                       new_resource.version
                     end
      end

      #
      # The RemoteFile resource for the package
      #
      # @return [Chef::Resource::RemoteFile]
      #
      def remote_file
        @remote_file ||= Resource::RemoteFile.new(local_package_path,
                                                  run_context)
        @remote_file.source(package_url)
        @remote_file
      end

      #
      # Construct the URL of the package to download for this system
      #
      # @return [String]
      #
      def package_url
        ::File.join(BASE_URL,
                    platform,
                    platform_version,
                    node['kernel']['machine'],
                    package_file)
      end

      #
      # Determine the platform name used in the package URL
      # (Red Hat-based distros are all under the generic "el" name)
      #
      # @return [String]
      #
      def platform
        case node['platform_family']
        when 'rhel'
          'el'
        else
          node['platform']
        end
      end

      #
      # Determine the platform version used in the package URL
      # (Red Hat-based systems use the major piece of the version string only
      # and OS X systems use major + minor but not patch)
      #
      # @return [String]
      #
      def platform_version
        case node['platform_family']
        when 'rhel'
          node['platform_version'].to_i.to_s
        # when 'mac_os_x'
        #   node['platform_version'].split('.')[0..1].join('.')
        else
          node['platform_version']
        end
      end

      #
      # The local filesystem path to download the package to
      #
      # @return [String]
      #
      def local_package_path
        ::File.join(Chef::Config[:file_cache_path], package_file)
      end

      #
      # Construct the file name of the package for this system
      #
      # @return [String]
      #
      def package_file
        elements = [PACKAGE_NAME]
        case node['platform_family']
        when 'rhel'
          elements << "#{version}.#{platform}" \
                      "#{platform_version}.#{node['kernel']['machine']}"
        else
          elements << version
        end
        elements << 'amd64' if node['platform'] == 'ubuntu'
        elements.join(package_file_separator) << package_file_extension
      end

      #
      # The character separator used in package filenames for this platform
      #
      # @return [String]
      #
      def package_file_separator
        node['platform'] == 'ubuntu' ? '_' : '-'
      end

      #
      # Return the extension of package files used by this system
      #
      # @return [String]
      #
      def package_file_extension
        case node['platform_family']
        when 'debian'
          '.deb'
        when 'rhel'
          '.rpm'
          # when 'mac_os_x'
          #   '.dmg'
        end
      end
    end
  end
end
