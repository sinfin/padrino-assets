# encoding: utf-8
namespace :assets do
  desc 'Compiles all assets'
  task :precompile => :environment do
    Padrino::Assets.registered_apps.each do |app|
      manifest    = app.sprockets_manifest
      environment = app.sprockets_environment

      if app.compress_assets?
        environment.js_compressor  = Padrino::Assets.find_registered_compressor(:js,  app.js_compressor)
        environment.css_compressor = Padrino::Assets.find_registered_compressor(:css, app.css_compressor)
      end

      app.precompile_assets.each do |path|
        environment.each_logical_path.each do |logical_path|
          case path
          when Regexp
            next unless path.match(logical_path)
          when Proc
            next unless path.call(logical_path)
          else
            next unless File.fnmatch(path.to_s, logical_path)
          end

          manifest.compile(logical_path)
        end
      end
    end

    Rake::Task['assets:compress'].invoke
  end
end