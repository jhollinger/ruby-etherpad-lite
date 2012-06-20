require 'uri'
require 'net/http'
require 'net/https'
require 'json'

# Ruby 1.8.x may not work, and I don't care
BAD_RUBY = RUBY_VERSION < '1.9.0' # :nodoc:

module EtherpadLite
  MAJOR_VERSION, MINOR_VERSION, TINY_VERSION, PRE_VERSION = 0, 1, 0, 'rc1' # :nodoc:
  # The client version
  VERSION = [MAJOR_VERSION, MINOR_VERSION, TINY_VERSION, PRE_VERSION].compact.join '.'

  # An error returned by the server
  class APIError < StandardError
    MESSAGE = "Error while talking to the API (%s). Make sure you are running the latest version of the Etherpad Lite server. If that is not possible, try rolling this client back to an earlier version."
  end

  # A thin wrapper around Etherpad Lite's HTTP JSON API
  # 
  #  client1 = EtherpadLite::Client.new('https://etherpad.yoursite.com[https://etherpad.yoursite.com]', 'your api key')
  # 
  #  # An alias for http://localhost:9001
  #  client2 = EtherpadLite::Client.new(:local, File.new('/path/to/APIKEY.txt'))
  # 
  #  # An alias for http://localhost:9001
  #  ether = EtherpadLite::Client.new(9001, File.new('/path/to/APIKEY.txt'))
  class Client
    # Aliases to common Etherpad Lite hosts
    HOST_ALIASES = {:local => 'http://localhost:9001',
                    :localhost => 'http://localhost:9001'}

    # The Etherpad Lite HTTP API version this library version targets
    API_VERSION = 1

    # HTTP API response code for okay
    CODE_OK = 0
    # HTTP API response code for invalid method parameters
    CODE_INVALID_PARAMETERS = 1
    # HTTP API response code for Etherpad Lite error
    CODE_INTERNAL_ERROR = 2
    # HTTP API response code for invalid api method
    CODE_INVALID_METHOD = 3
    # HTTP API response code for invalid api key
    CODE_INVALID_API_KEY = 4

    # A URI object containing the URL of the Etherpad Lite instance
    attr_reader :uri
    # The API key
    attr_reader :api_key

    class << self
      # Path to the system's CA certs (for connecting over SSL)
      attr_accessor :ca_path
    end

    # Instantiate a new Etherpad Lite Client.
    # 
    #  client1 = EtherpadLite::Client.new('https://etherpad.yoursite.com[https://etherpad.yoursite.com]', 'your api key')
    # 
    #  # An alias for http://localhost:9001
    #  client2 = EtherpadLite::Client.new(:local, File.new('/path/to/APIKEY.txt'))
    # 
    #  # An alias for http://localhost:9001
    #  client3 = EtherpadLite::Client.new(9001, File.new('/path/to/APIKEY.txt'))
    def initialize(host_or_alias, api_key_or_file)
      # Parse the host
      url = if host_or_alias.is_a? Symbol
        raise ArgumentError, %Q|Unknown host alias "#{host_or_alias}"| unless HOST_ALIASES.has_key? host_or_alias
        HOST_ALIASES[host_or_alias]
      elsif host_or_alias.is_a? Fixnum
        "http://localhost:#{host_or_alias}"
      else
        host_or_alias.clone
      end
      url << '/api' unless url =~ /\/api$/i
      @uri = URI.parse(url)
      raise ArgumentError, "#{url} does not contain a valid host and port" unless @uri.host and @uri.port

      # Parse the api key
      if api_key_or_file.is_a? File
        @api_key = begin
          api_key_or_file.read
        rescue IOError
          api_key_or_file.reopen(api_key_or_file.path, mode='r')
          api_key_or_file.read
        end
        api_key_or_file.close
      else
        @api_key = api_key_or_file
      end

      connect!
    end

    # Groups
    # Pads can belong to a group. There will always be public pads which don't belong to a group.

    # Creates a new Group
    def createGroup
      post :createGroup
    end

    # Creates a new Group for groupMapper if one doesn't already exist. Helps you map your application's groups to Etherpad Lite's groups.
    def createGroupIfNotExistsFor(groupMapper)
      post :createGroupIfNotExistsFor, :groupMapper => groupMapper
    end

    # Deletes a group
    def deleteGroup(groupID)
      post :deleteGroup, :groupID => groupID
    end

    # Returns all the Pads in the given Group
    def listPads(groupID)
      get :listPads, :groupID => groupID
    end

    # Creates a new Pad in the given Group
    def createGroupPad(groupID, padName, text=nil)
      params = {:groupID => groupID, :padName => padName}
      params[:text] = text unless text.nil?
      post :createGroupPad, params
    end

    # Authors
    # These authors are bound to the attributes the users choose (color and name).

    # Create a new Author
    def createAuthor(name=nil)
      params = {}
      params[:name] = name unless name.nil?
      post :createAuthor, params
    end

    # Creates a new Author for authorMapper if one doesn't already exist. Helps you map your application's authors to Etherpad Lite's authors.
    def createAuthorIfNotExistsFor(authorMapper, name=nil)
      params = {:authorMapper => authorMapper}
      params[:name] = name unless name.nil?
      post :createAuthorIfNotExistsFor, params
    end

    # Sessions
    # Sessions can be created between a group and an author. This allows
    # an author to access more than one group. The sessionID will be set as
    # a cookie to the client and is valid until a certian date.

    # Creates a new Session for the given Author in the given Group
    def createSession(groupID, authorID, validUntil)
      post :createSession, :groupID => groupID, :authorID => authorID, :validUntil => validUntil
    end

    # Deletes the given Session
    def deleteSession(sessionID)
      post :deleteSession, :sessionID => sessionID
    end

    # Returns information about the Session
    def getSessionInfo(sessionID)
      get :getSessionInfo, :sessionID => sessionID
    end

    # Returns all Sessions in the given Group
    def listSessionsOfGroup(groupID)
      get :listSessionsOfGroup, :groupID => groupID
    end

    # Returns all Sessions belonging to the given Author
    def listSessionsOfAuthor(authorID)
      get :listSessionsOfAuthor, :authorID => authorID
    end

    # Pad content
    # Pad content can be updated and retrieved through the API

    # Returns the text of the given Pad. Optionally pass a revision number to get the text for that revision.
    def getText(padID, rev=nil)
      params = {:padID => padID}
      params[:rev] = rev unless rev.nil?
      get :getText, params
    end

    # Sets the text of the given Pad
    def setText(padID, text)
      post :setText, :padID => padID, :text => text
    end

    # Returns the text of the given Pad as HTML. Optionally pass a revision number to get the HTML for that revision.
    def getHTML(padID, rev=nil)
      params = {:padID => padID}
      params[:rev] = rev unless rev.nil?
      get :getHTML, params
    end

    # Sets the HTML text of the given Pad
    def setHTML(padID, html)
      post :setHTML, :padID => padID, :html => html
    end

    # Pad
    # Group pads are normal pads, but with the name schema
    # GROUPID$PADNAME. A security manager controls access of them and
    # forbids normal pads from including a "$" in the name.

    # Create a new Pad. Optionally specify the initial text.
    def createPad(padID, text=nil)
      params = {:padID => padID}
      params[:text] = text unless text.nil?
      post :createPad, params
    end

    # Returns the number of revisions the given Pad contains
    def getRevisionsCount(padID)
      get :getRevisionsCount, :padID => padID
    end

    # Delete the given Pad
    def deletePad(padID)
      post :deletePad, :padID => padID
    end

    # Returns the Pad's read-only id
    def getReadOnlyID(padID)
      get :getReadOnlyID, :padID => padID
    end

    # Sets a boolean for the public status of a Pad
    def setPublicStatus(padID, publicStatus)
      post :setPublicStatus, :padID => padID, :publicStatus => publicStatus
    end

    # Gets a boolean for the public status of a Pad
    def getPublicStatus(padID)
      get :getPublicStatus, :padID => padID
    end

    # Sets the password on a pad
    def setPassword(padID, password)
      post :setPassword, :padID => padID, :password => password
    end

    # Returns true if the Pad has a password, false if not
    def isPasswordProtected(padID)
      get :isPasswordProtected, :padID => padID
    end

    # Returns true if the connection to the Etherpad Lite instance is using SSL/HTTPS.
    def secure?
      @uri.port == 443
    end

    protected

    # Alias to "call" using the GET HTTP method
    def get(method, params={})
      call method, params, :get
    end

    # Alias to "call" using the POST HTTP method
    def post(method, params={})
      call method, params, :post
    end

    # Calls the EtherpadLite API and returns the :data portion of the response Hash.
    # 
    # "method" should be a valid API method name, as a String or Symbol.
    # 
    # "params" should be any URL or form parameters as a Hash.
    # 
    # "http_method" should be :get or :post, defaults to :get.
    # 
    def call(method, params={}, http_method=:get)
      params[:apikey] = @api_key
      uri = [@uri.path, API_VERSION, method].compact.join('/')
      http_method = :post if BAD_RUBY # XXX A horrible, horrible hack for Ruby 1.8
      req = case http_method
        when :get then Net::HTTP::Get.new(uri << '?' << URI.encode_www_form(params))
        when :post
          post = Net::HTTP::Post.new(uri)
          post.set_form_data(params)
          post
        else raise ArgumentError, "#{http_method} is not a valid HTTP method"
      end
      response = @http.request(req)
      handleResult response.body
    end

    # Parses the JSON response from the server, returning the data object as a Hash with symbolized keys.
    # If the API response contains an error code, an exception is raised.
    def handleResult(response)
      begin
        response = JSON.parse(response, :symbolize_names => true)
      rescue JSON::ParserError
        raise APIError, APIError::MESSAGE % response
      end
      case response[:code]
        when CODE_OK then response[:data]
        when CODE_INVALID_PARAMETERS, CODE_INVALID_API_KEY, CODE_INVALID_METHOD
          raise ArgumentError, response[:message]
        else
          raise APIError, "An unknown error ocurrced while handling the response: #{response.to_s}"
      end
    end

    private

    # Initialize the HTTP connection object
    def connect!
      @http = Net::HTTP.new(@uri.host, @uri.port)
      if secure?
        @http.use_ssl = true
        if self.class.ca_path
          @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          @http.ca_path = self.class.ca_path
        else
          @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end
    end
  end
end

# Try to find the system's CA certs
%w{/etc/ssl/certs /etc/ssl /usr/share/ssl /usr/lib/ssl /System/Library/OpenSSL /usr/local/ssl}.each do |path|
  EtherpadLite::Client.ca_path = path and break if File.exists? path
end
$stderr.puts %q|WARNING Ruby etherpad-lite client was unable to find your CA Certificates; HTTPS connections will *not* be verified! You may remedy this with "EtherpadLite::Client.ca_path = '/path/to/certs'"| unless EtherpadLite::Client.ca_path

# Warn about old Ruby versions
$stderr.puts "WARNING You are using an ancient version of Ruby which may not be supported. Upgrade Ruby!" if BAD_RUBY
