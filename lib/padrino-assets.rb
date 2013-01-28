# encoding: utf-8
require 'padrino-core'

FileSet.glob_require('padrino-assets/**/*.rb', __FILE__)

module Padrino
  module Assets
    class << self
      ###
      # Returns the list of default paths Sprockets will use in order to find assets used by the project
      #
      # @return [Array]
      #   List of assets paths
      #
      # @since 0.1.0
      # @api public
      def load_paths
        @_load_paths ||= %w(lib vendor).map do |directory|
          Dir[Padrino.root("#{directory}/assets/**")]
        end.flatten
      end

      ###
      # Returns the Padrino apps that are using Padrino::Assets
      #
      # @return [Array]
      #   Padrino::Application
      #
      #
      # @since 0.1.0
      # @api public
      def registered_apps
        @_apps ||= []
      end

      ###
      # Returns a list of available asset compressors
      #
      # @return [Hash]
      #   List of available asset compressors
      #
      # @since 0.3.0
      # @api public
      def compressors
        @_compressors ||= Hash.new { |k, v| k[v] = Hash.new }
      end

      ###
      # Registers an asset compressor for use with Sprockets
      #
      # @param [Symbol] type
      #   The type of compressor you are registering (:js, :css)
      #
      # @example
      #   Padrino::Assets.register_compressor :js,  :simple => 'SimpleCompressor'
      #   Padrino::Assets.register_compressor :css, :simple => 'SimpleCompressor'
      #
      # @since 0.3.0
      # @api public
      def register_compressor(type, compressor)
        compressors[type].merge!(compressor)
      end

      # @since 0.3.0
      # @api private
      def find_registered_compressor(type, compressor)
        return compressor unless compressor.is_a?(Symbol)

        if compressor = compressors[type][compressor]
           compressor = compressor.safe_constantize
        end

        compressor.respond_to?(:new) ? compressor.new : compressor
      end

      # @private
      def registered(app)
        registered_apps << app

        app.helpers Helpers
        app.set :assets_prefix,   '/assets'
        app.set :assets_version,  1.0
        app.set :assets_host,     nil
        app.set :compress_assets, true
        app.set :js_compressor,   Padrino::Assets.compressors[:js].keys.first
        app.set :css_compressor,  Padrino::Assets.compressors[:css].keys.first
        app.set :index_assets,    -> { app.environment == :production }
        app.set :manifest_file,   -> { File.join(app.public_folder, app.assets_prefix, 'manifest.json') }
        app.set :precompile_assets,  [ /^application\.(js|css)$/i ]

        Padrino.after_load do
          require 'sprockets'

          app.get("#{app.assets_prefix}/*") do
            env['PATH_INFO'].gsub!("#{app.assets_prefix}/", '')
            app.sprockets_environment.call(env)
          end

          environment = Sprockets::Environment.new(app.root)

          environment.logger  = app.logger
          environment.version = app.assets_version

          if defined?(Padrino::Cache)
            if app.respond_to?(:caching) && app.caching?
              environment.cache = app.cache
            end
          end

          (load_paths + Dir["#{app.root}/assets/**"]).flatten.each do |path|
            environment.append_path(path)
          end

          environment.context_class.class_eval do
            include Helpers
          end

          app.set :sprockets_environment,  app.index_assets ? environment.index : environment
          app.set :sprockets_manifest,     Sprockets::Manifest.new(environment, app.manifest_file)
        end

        Padrino::Tasks.files << Dir[File.dirname(__FILE__) + '/tasks/**/*.rake']
      end
    end

    register_compressor :css, :yui      => 'YUI::CssCompressor'
    register_compressor :js,  :yui      => 'YUI::JavaScriptCompressor'
    register_compressor :js,  :closure  => 'Closure::Compiler'
    register_compressor :js,  :uglifier => 'Uglifier'
  end # Assets
end # Padrino