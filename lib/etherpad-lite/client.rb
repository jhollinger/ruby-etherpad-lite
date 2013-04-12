require 'uri'
require 'json'
require 'rest_client'

# A client library for Etherpad Lite's JSON API. 
# 
# A thin wrapper around the HTTP API. See the API documentation at http://etherpad.org/doc/v1.2.0/#index_api_methods.
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
  def self.client(url_or_port, api_key_or_file, api_version=nil)
    Client.new(url_or_port, api_key_or_file, api_version)
  end

  # A thin wrapper around Etherpad Lite's HTTP JSON API. See the API documentation at http://etherpad.org/doc/v1.2.0/#index_api_methods.
  class Client
    # A URI object containing the URL of the Etherpad Lite instance
    attr_reader :uri
    # The API key
    attr_reader :api_key
    # The API version string
    attr_reader :api_version

    # Instantiate a new Etherpad Lite Client. You may pass a full url or just a port number. The api key may be a string
    # or a File object. If you do not specify an API version, it will default to the latest version.
    def initialize(url_or_port, api_key_or_file, api_version=nil)
      url_or_port = "http://localhost:#{url_or_port}" if url_or_port.is_a? Integer
      @uri = URI.parse(url_or_port)
      @api_key = api_key_or_file.is_a?(IO) ? api_key_or_file.read : api_key_or_file
      @api_version = api_version ? api_version.to_s : current_api_version.to_s
    end

    # Call an API method
    def method_missing(method, params={})
      call(method, params)
    end

    private

    # Returns the latest api version. Defaults to "1" if anything goes wrong.
    def current_api_version
      JSON.parse(get('/api').to_s)['currentVersion'] rescue 1
    end

    # Calls the EtherpadLite API and returns the :data portion of the response Hash.
    # If the API response contains an error code, an exception is raised.
    def call(api_method, params={}, &request)
      path = "/api/#{api_version}/#{api_method}"

      begin
        result = api_method =~ /^(set|create|delete)/ ? post(path, params) : get(path, params)
        response = JSON.parse(result.to_s, :symbolize_names => true)
      rescue JSON::ParserError => e
        raise Error, "Unable to parse JSON response: #{json}"
      end

      case response[:code]
        when 0 then response[:data]
        when (1..4) then raise Error, response[:message]
        else raise Error, "An unknown error ocurrced while handling the API response: #{response.to_s}"
      end
    end

    # Makes a GET request
    def get(path, params={})
      params[:apikey] = self.api_key
      RestClient.get("#{self.uri}#{path}", :params => params)
    end

    # Makes a POST request
    def post(path, params={})
      params[:apikey] = self.api_key
      RestClient.post("#{self.uri}#{path}", params)
    end
  end
end
