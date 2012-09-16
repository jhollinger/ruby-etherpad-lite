require 'uri'
require 'json'
require 'delegate'

require 'rest_client'

require 'etherpad-lite/api'

# Provides two interfaces to an EtherpadLite server's API; one low-level and one high.
# 
# Low level:
# 
#  client = EtherpadLite.client('http://localhost:9001', 'api key')
#  client.getText('padID')
#  => {:text => "Pad text"}
#  client.setText('padID', 'new pad text')
# 
# High level:
# 
#  ether = EtherpadLite.connect('http://localhost:9001', 'api key')
#  pad = ether.pad('padID')
#  puts pad.text
#  => 'Pad text'
#  pad.text = 'new pad text'
module EtherpadLite
  # An error returned by the server
  Error = Class.new(StandardError)

  # Returns a new EtherpadLite::Client.
  # 
  #  client = EtherpadLite.client('https://etherpad.yoursite.com[https://etherpad.yoursite.com]', 'your api key')
  # 
  #  client = EtherpadLite.client(9001, 'your api key') # Alias to http://localhost:9001
  def self.client(url_or_port, api_key_or_file, api_version=nil)
    Client.new(url_or_port, api_key_or_file, api_version)
  end

  # A thin wrapper around Etherpad Lite's HTTP JSON API.
  class Client < SimpleDelegator
    # HTTP API response codes
    CODE_OK, CODE_INVALID_PARAMETERS, CODE_INTERNAL_ERROR, CODE_INVALID_METHOD, CODE_INVALID_API_KEY = 0, 1, 2, 3, 4 # :nodoc:

    # A URI object containing the URL of the Etherpad Lite instance
    attr_reader :uri
    # The API key
    attr_reader :api_key

    # Instantiate a new Etherpad Lite Client. You may pass a full url or just a port number. The api key may be a string
    # or a File object. If you do not specify an API version, it will default to the latest version that is supported.
    def initialize(url_or_port, api_key_or_file, api_version=nil)
      url_or_port = "http://localhost:#{url_or_port}" if url_or_port.is_a? Fixnum
      @uri = URI.parse("#{url_or_port}/api")
      @api_key = api_key_or_file.is_a?(IO) ? api_key_or_file.read : api_key_or_file
      __setobj__ API.new(api_version || API::VERSIONS.last, self)
    end

    # Returns true if the connection to the Etherpad Lite instance is secured over HTTPS.
    def secure?
      @uri.port == 443
    end

    # Call an API method using HTTP GET
    def get(method, params={})
      call(method, params) { |url, params| RestClient.get(url, :params => params) }
    end

    # Call an API method using HTTP POST
    def post(method, params={})
      call(method, params) { |url, params| RestClient.post(url, params) }
    end

    private

    # Calls the EtherpadLite API and returns the :data portion of the response Hash.
    def call(api_method, params={}, &request)
      params[:apikey] = @api_key
      url = [@uri.to_s, self.version, api_method].compact.join('/')
      response = request.(url, params).to_s
      handle response
    end

    # Parses the JSON response from the server, returning the data object as a Hash with symbolized keys.
    # If the API response contains an error code, an exception is raised.
    def handle(response)
      response = JSON.parse(response, :symbolize_names => true)
      case response[:code]
        when CODE_OK then response[:data]
        when CODE_INVALID_PARAMETERS, CODE_INVALID_API_KEY, CODE_INVALID_METHOD then raise Error, response[:message]
        else raise Error, "An unknown error ocurrced while handling the API response: #{response.to_s}"
      end
    end
  end
end
