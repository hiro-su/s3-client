require 'settingslogic'

module S3
  class Settings < Settingslogic
    source File.expand_path("../../../config/settings.yml", __FILE__)
    namespace ENV['S3_CLIENT_ENV'] || 'defaults'
    load!
  end
end
