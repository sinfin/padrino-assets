PADRINO_ENV = 'test'

require 'rspec'
require 'rspec-html-matchers'
require 'padrino-assets'

module TestHelpers
  def app
    @app ||= Sinatra.new(Padrino::Application) do
      register Padrino::Assets
      set :manifest_file, File.join(settings.root, 'fixtures', 'compiled_assets', 'manifest.json')
      set :logging, false
    end
  end

  def settings
    app.settings
  end

  def request
    @request ||= Sinatra::Request.new(nil.to_s)
  end

  def environment
    settings.sprockets_environment
  end

  def manifest
    settings.sprockets_manifest
  end
end

RSpec.configure do |config|
  config.include TestHelpers

  config.before(:each) do
    app # touch app so we have an after_load to run
    Padrino.after_load.each(&:call)
  end

  config.after(:each) do
    Padrino::Assets.registered_apps.clear
    Padrino.clear!
  end
end

Padrino::Assets.load_paths << File.dirname(__FILE__) + '/fixtures/assets'