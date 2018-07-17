# frozen_string_literal: true

require 'net/http'
require 'json'

# Config
settings = YAML.load_file(File.join(File.expand_path('./.'), 'config.yml'))
sentry_settings = settings['sentry']

# Job
sentry_settings['projects'].each do |_name, project|
  api_key = project['api_key']
  sentry_url = URI.parse("https://sentry.io/api/0/projects/#{project['organization']}/#{project['name']}/issues/?sort=freq&statsPeriod=24h&limit=5")
  req = Net::HTTP::Get.new(sentry_url.request_uri)
  req.add_field("Authorization", "Bearer #{api_key}")

  SCHEDULER.every '5s', :first_in => 0 do
    begin
      puts "#{sentry_url} - #{sentry_url.host} - #{sentry_url.port}"
      response = Net::HTTP.start(sentry_url.host, sentry_url.port, use_ssl: (sentry_url.scheme == 'https')) do |http|
        http.request(req)
      end

      errorList = JSON.parse(response.body)
      event_id = format('sentry_toperrors_%s', project['name'])
      send_event(event_id, errorList: errorList)
    end
  end
end
