require 'rails/generators/base'
require 'rails/generators/active_record'

module IntercomApp
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)

      class_option :app_key, type: :string, default: '<app_key>'
      class_option :app_secret, type: :string, default: '<app_secret>'
      class_option :oauth_modal, type: :boolean, default: false

      def create_intercom_app_initializer
        @app_key = options['app_key']
        @app_secret = options['app_secret']
        @oauth_modal = options['oauth_modal']

        template 'intercom_app.rb', 'config/initializers/intercom_app.rb'
      end

      def create_and_inject_into_omniauth_initializer
        unless File.exist? "config/initializers/omniauth.rb"
          copy_file 'omniauth.rb', 'config/initializers/omniauth.rb'
        end

        inject_into_file(
          'config/initializers/omniauth.rb',
          File.read(File.expand_path(find_in_source_paths('intercom_provider.rb'))),
          after: "Rails.application.config.middleware.use OmniAuth::Builder do\n"
        )
      end

      def create_intercom_session_repository_initializer
        copy_file 'intercom_session_repository.rb', 'config/initializers/intercom_session_repository.rb'
      end


      def inject_into_application_controller
        inject_into_class(
          "app/controllers/application_controller.rb",
          'ApplicationController',
          "  include IntercomApp::LoginProtection\n"
        )
      end

      def mount_engine
        route "mount IntercomApp::Engine, at: '/'"
      end

    end
  end
end
