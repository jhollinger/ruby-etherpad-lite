require 'uri'
require 'net/http'
require 'json'

module EtherpadLite
  # Returns an EtherpadLite::Instance object.
  # 
  # eth = EtherpadLite.connect('https://etherpad.example.com', 'sdkjghJG73ksja8')
  def self.connect(url, api_key, options={})
    Instance.new url, api_key, options
  end

  # A EtherpadLite::Instance object represents an installation or connection to a Etherpad Lite instance.
  # 
  # eth = EtherpadLite::Instance('http://etherpad.example.com', 'sdkjghJG73ksja8')
  # eth.secure?
  # => false
  class Instance
    include Padded

    API_ROOT = 'api'
    API_VERSION = 1
    CODE_OK = 0;
    CODE_INVALID_PARAMETERS = 1
    CODE_INTERNAL_ERROR = 2
    CODE_INVALID_METHOD = 3
    CODE_INVALID_API_KEY = 4

    attr_reader :api_key
    attr_reader :uri

    # Instantiate a new Etherpad Lite Instance. The url should include the protocol (i.e. http or https).
    # If you are connecting to EtherpadLite on a different domain, you should usually use jsonp.
    # 
    # Options:
    #  jsonp => true|false (default false)
    def initialize(url, api_key, options={})
      @uri = URI.parse(url)
      raise ArgumentError, "#{url} is not a valid url" unless @uri.host and @uri.port
      @api_key = api_key
      @jsonp = options[:jsonp] if options.has_key? :jsonp
    end

    # Pad, Group, etc. all use this to send the HTTP API requests. The method is a URI under /api/VERSION/, and the options are URL parameters.
    def call(method, options={})
      # Parse options
      options = {:apikey => api_key}.merge(options)
      options[:jsonp] = '?' if @jsonp == true
      params = options.map { |a| a.join('=') }.join('&').gsub(/\s/, '%20') # Surely Net::HTTP can do a better job of this...
      # Make request
      get = Net::HTTP::Get.new("/#{API_ROOT}/#{API_VERSION}/#{method}?#{params}")
      resp = Net::HTTP::start(@uri.host, @uri.port) { |http| http.request(get) }
      parse resp.body
    end

    # Returns a Group with the given id (it is presumed to already exist).
    def group(id)
      Group.new self, id
    end

    # Returns, creating if necessary, a Group for your given mapper (foreign system's group id).
    def group_mapped_to(mapper)
      create_group(:mapper => mapper)
    end

    # Creates a new Group. Optionally, you may pass the :mapper option your third party system's group id.
    # This will allow you to find your Group again later using the same identifier as your foreign system.
    # 
    # Options:
    #  mapper => your foreign group id
    def create_group(options={})
      Group.create self, options
    end

    # Returns true if the connection to the Etherpad Lite instance is using SSL/HTTPS.
    def secure?
      @uri.port == 443
    end

    private

    def instance
      self
    end

    # Parses the JSON response from the server, returning the data object as a Hash with symbolized keys.
    # If the API response contains an error code, an exception is raised.
    def parse(response)
      response = JSON.parse(response, :symbolize_names => true)
      case response[:code]
        when CODE_OK then response[:data]
        when CODE_INVALID_PARAMETERS
          raise ArgumentError, response[:message]
        when CODE_INVALID_API_KEY
          raise ArgumentError, response[:message]
        when CODE_INVALID_METHOD
          raise ArgumentError, response[:message]
        else
          raise StandardError, "An unknown error ocurrced while handling the response: #{response.to_s}"
      end
    end
  end
end
