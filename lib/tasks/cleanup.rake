# encoding: utf-8
namespace :assets do
  desc 'Removes backups for existing assets'
  task :cleanup, [:keep] => :environment do |task, args|
    keep = args[:keep] || 2
    Padrino::Assets.registered_apps.each { |app| app.sprockets_manifest.clean(keep) }
  end
end
