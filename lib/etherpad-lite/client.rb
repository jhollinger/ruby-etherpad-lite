require 'uri'
require 'json'
require 'rest_client'

# A client library for Etherpad Lite's JSON API. 
# 
# A thin wrapper around the HTTP API. See the API documentation at https://github.com/Pita/etherpad-lite/wiki/HTTP-API.
# 
#  client = EtherpadLite.client('http://localhost:9001', 'api key', '1.1')
#  client.getText(:padID => 'foo')
#  => {:text => "Pad text"}
#  client.setText(:padID => 'padID', :text => 'new pad text')
# 
# A higher-level interface to the API:
# 
#  ether = EtherpadLite.connect('http://localhost:9001', 'api key', '1.1')
#  pad = ether.pad('padID')
#  puts pad.text
#  => 'Pad text'
#  pad.text = 'new pad text'
module EtherpadLite
  # An error returned by the server
  Error = Class.new(StandardError)

  # Returns a new EtherpadLite::Client.
  # 
  #  client = EtherpadLite.client('https://etherpad.yoursite.com', 'your api key', '1.1')
  # 
  #  client = EtherpadLite.client(9001, 'your api key', '1.1') # Alias to http://localhost:9001
  def self.client(url_or_port, api_key_or_file, api_version=1)
    Client.new(url_or_port, api_key_or_file, api_version)
  end

  # A thin wrapper around Etherpad Lite's HTTP JSON API. See the API documentation at https://github.com/Pita/etherpad-lite/wiki/HTTP-API.
  class Client
    # A URI object containing the URL of the Etherpad Lite instance
    attr_reader :uri
    # The API key
    attr_reader :api_key
    # The API version string
    attr_reader :api_version

    # Instantiate a new Etherpad Lite Client. You may pass a full url or just a port number. The api key may be a string
    # or a File object. If you do not specify an API version, it will default to the latest version that is supported.
    def initialize(url_or_port, api_key_or_file, api_version=1)
      url_or_port = "http://localhost:#{url_or_port}" if url_or_port.is_a? Integer
      @uri = URI.parse(url_or_port)
      @api_key = api_key_or_file.is_a?(IO) ? api_key_or_file.read : api_key_or_file
      @api_version = api_version.to_s
    end

    # Call an API method
    def method_missing(method, params={})
      request = method =~ /^(set|create|delete)/ \
        ? ->(url, params) { RestClient.post(url, params) } \
        : ->(url, params) { RestClient.get(url, :params => params) }
      call(method, params, &request)
    end

    private

    # Calls the EtherpadLite API and returns the :data portion of the response Hash.
    # If the API response contains an error code, an exception is raised.
    def call(api_method, params={}, &request)
      params[:apikey] = @api_key
      url = [@uri.to_s, 'api', self.api_version, api_method].compact.join('/')
      json = request.(url, params).to_s
      response = JSON.parse(json, :symbolize_names => true)

      case response[:code]
        when 0 then response[:data]
        when (1..4) then raise Error, response[:message]
        else raise Error, "An unknown error ocurrced while handling the API response: #{response.to_s}"
      end
    end
  end
end
