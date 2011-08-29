require 'uri'
require 'net/http'
require 'net/https'
require 'json'

module EtherpadLite
  # Aliases to common Etherpad Lite hosts
  HOST_ALIASES = {:local => 'http://localhost:9001',
                  :public => 'http://beta.etherpad.org'}

  # Returns an EtherpadLite::Instance object.
  # 
  # ether1 = EtherpadLite.connect('https://etherpad.yoursite.com[https://etherpad.yoursite.com]', 'your api key')
  # 
  # ether2 = EtherpadLite.connect(:local, File.new('/file/path/to/APIKEY.txt'))
  # 
  # ether3 = EtherpadLite.connect(:public, "beta.etherpad.org's api key")
  def self.connect(host_or_alias, api_key_or_file)
    # Parse the host
    host = if host_or_alias.is_a? Symbol
      raise ArgumentError, %Q|Unknown host alias "#{host_or_alias}"| unless HOST_ALIASES.has_key? host_or_alias
      HOST_ALIASES[host_or_alias]
    else
      host_or_alias
    end
    # Parse the api key
    if api_key_or_file.is_a? File
      api_key = api_key_or_file.read
      api_key_or_file.close
    else
      api_key = api_key_or_file
    end
    Instance.new(host, api_key)
  end

  # A EtherpadLite::Instance object represents an installation or connection to a Etherpad Lite installation.
  class Instance
    include Padded

    API_ROOT = 'api'
    API_VERSION = 1
    CODE_OK = 0
    CODE_INVALID_PARAMETERS = 1
    CODE_INTERNAL_ERROR = 2
    CODE_INVALID_METHOD = 3
    CODE_INVALID_API_KEY = 4

    attr_reader :uri, :api_key

    # Path to the system's CA cert paths (for connecting over SSL)
    @@ca_path = nil

    # Get path to the system's CA certs
    def self.ca_path; @@ca_path; end

    # Manually set path to the system's CA certs. Use this if the location couldn't be determined automatically.
    def self.ca_path=(path); @@ca_path = path; end

    # Instantiate a new Etherpad Lite Instance. The url should include the protocol (i.e. http or https).
    def initialize(url, api_key)
      @uri = URI.parse(url)
      raise ArgumentError, "#{url} is not a valid url" unless @uri.host and @uri.port
      @api_key = api_key
      reconnect!
    end

    # Pad, Group, etc. all use this to send the HTTP API requests.
    def call(method, params={})
      # Build path
      params[:apikey] = @api_key
      params = params.map { |p| p.join('=') }.join('&').gsub(/\s/, '%20')
      path = [@uri.path, API_ROOT, API_VERSION, method].compact.join('/') << '?' << params
      # Send request
      get = Net::HTTP::Get.new(path)
      response = @http.request(get)
      parse response.body
    end

    # Returns, creating if necessary, a Group mapped to your foreign system's group
    def group(mapper)
      create_group(:mapper => mapper)
    end

    # Returns a Group with the given id (it is presumed to already exist).
    def get_group(id)
      Group.new self, id
    end

    # Creates a new Group. Optionally, you may pass the :mapper option your third party system's group id.
    # This will allow you to find your Group again later using the same identifier as your foreign system.
    # 
    # Options:
    # 
    #  mapper => your foreign group id
    def create_group(options={})
      Group.create self, options
    end

    # Returns, creating if necessary, a Author mapped to your foreign system's author
    # 
    # Options:
    # 
    #  name => the Author's name
    def author(mapper, options={})
      options[:mapper] = mapper
      create_author options
    end

    # Returns an Author with the given id (it is presumed to already exist).
    def get_author(id)
      Author.new self, id
    end

    # Creates a new Author. Optionally, you may pass the :mapper option your third party system's author id.
    # This will allow you to find the Author again later using the same identifier as your foreign system.
    # 
    # Options:
    # 
    #  mapper => your foreign author id
    # 
    #  name => the Author's name
    def create_author(options={})
      Author.create self, options
    end

    # Returns true if the connection to the Etherpad Lite instance is using SSL/HTTPS.
    def secure?
      @uri.port == 443
    end

    # (re)Initialize the HTTP connection object
    def reconnect!
      @http = Net::HTTP.new(@uri.host, @uri.port)
      if secure?
        @http.use_ssl = true
        if @@ca_path
          @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          @http.ca_path = @@ca_path
        else
          @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end
    end

    def instance; self; end

    private

    # Parses the JSON response from the server, returning the data object as a Hash with symbolized keys.
    # If the API response contains an error code, an exception is raised.
    def parse(response)
      response = JSON.parse(response, :symbolize_names => true)
      case response[:code]
        when CODE_OK then response[:data]
        when CODE_INVALID_PARAMETERS, CODE_INVALID_API_KEY, CODE_INVALID_METHOD
          raise ArgumentError, response[:message]
        else
          raise StandardError, "An unknown error ocurrced while handling the response: #{response.to_s}"
      end
    end
  end
end

# Try to find the system's CA certs
%w{/etc/ssl/certs /etc/ssl /usr/share/ssl /usr/lib/ssl /System/Library/OpenSSL /usr/local/ssl}.each do |path|
  EtherpadLite::Instance.ca_path = path and break if File.exists? path
end
$stderr.puts %q|WARNING Unable to find your CA Certificates; HTTPS connections will *not* be verified! You may remedy this with "EtherpadLite::Instance.ca_path = '/path/to/certs'"| unless EtherpadLite::Instance.ca_path
