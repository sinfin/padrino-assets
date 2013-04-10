# encoding: utf-8
namespace :assets do
  desc 'Deletes all compiled assets'
  task :clobber => :environment do
    Padrino::Assets.registered_apps.each { |app| app.sprockets_manifest.clobber }
  end
end
