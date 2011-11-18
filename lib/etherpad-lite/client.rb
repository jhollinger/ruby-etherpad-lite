require 'uri'
require 'net/http'
require 'net/https'
require 'json'

module EtherpadLite
  # A thin wrapper around Etherpad Lite's HTTP JSON API
  class Client
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

    # Instantiate a new Etherpad Lite Client. The url should include the protocol (i.e. http or https).
    def initialize(api_key, url='http://localhost:9001/api')
      @uri = URI.parse(url)
      raise ArgumentError, "#{url} is not a valid url" unless @uri.host and @uri.port
      @api_key = api_key
      connect!
    end

    # Calls the EtherpadLite API and returns the :data portion of the response Hash.
    def call(method, params={})
      # Build path
      params[:apikey] = @api_key
      params = params.map { |k,v| "#{k}=#{URI.encode(v.to_s)}" }.join('&')
      path = [@uri.path, API_VERSION, method].compact.join('/') << '?' << params
      # Send request
      get = Net::HTTP::Get.new(path)
      response = @http.request(get)
      handleResult response.body
    end

    # Groups
    # Pads can belong to a group. There will always be public pads which don't belong to a group.

    # Creates a new Group
    def createGroup
      call :createGroup
    end

    # Creates a new Group for groupMapper if one doesn't already exist. Helps you map your application's groups to Etherpad Lite's groups.
    def createGroupIfNotExistsFor(groupMapper)
      call :createGroupIfNotExistsFor, :groupMapper => groupMapper
    end

    # Deletes a group
    def deleteGroup(groupID)
      call :deleteGroup, :groupID => groupID
    end

    # Returns all the Pads in the given Group
    def listPads(groupID)
      call :listPads, :groupID => groupID
    end

    # Creates a new Pad in the given Group
    def createGroupPad(groupID, padName, text=nil)
      params = {:groupID => groupID, :padName => padName}
      params[:text] = text unless text.nil?
      call :createGroupPad, params
    end

    # Authors
    # These authors are bound to the attributes the users choose (color and name).

    # Create a new Author
    def createAuthor(name=nil)
      params = {}
      params[:name] = name unless name.nil?
      call :createAuthor, params
    end

    # Creates a new Author for authorMapper if one doesn't already exist. Helps you map your application's authors to Etherpad Lite's authors.
    def createAuthorIfNotExistsFor(authorMapper, name=nil)
      params = {:authorMapper => authorMapper}
      params[:name] = name unless name.nil?
      call :createAuthorIfNotExistsFor, params
    end

    # Sessions
    # Sessions can be created between a group and an author. This allows
    # an author to access more than one group. The sessionID will be set as
    # a cookie to the client and is valid until a certian date.

    # Creates a new Session for the given Author in the given Group
    def createSession(groupID, authorID, validUntil)
      call :createSession, :groupID => groupID, :authorID => authorID, :validUntil => validUntil
    end

    # Deletes the given Session
    def deleteSession(sessionID)
      call :deleteSession, :sessionID => sessionID
    end

    # Returns information about the Session
    def getSessionInfo(sessionID)
      call :getSessionInfo, :sessionID => sessionID
    end

    # Returns all Sessions in the given Group
    def listSessionsOfGroup(groupID)
      call :listSessionsOfGroup, :groupID => groupID
    end

    # Returns all Sessions belonging to the given Author
    def listSessionsOfAuthor(authorID)
      call :listSessionsOfAuthor, :authorID => authorID
    end

    # Pad content
    # Pad content can be updated and retrieved through the API

    # Returns the text of the given Pad as HTML. Optionally pass a revision number to get the HTML for that revision.
    def getHTML(padID, rev=nil)
      params = {:padID => padID}
      params[:rev] = rev unless rev.nil?
      call :getHTML, params
    end

    # Returns the text of the given Pad. Optionally pass a revision number to get the text for that revision.
    def getText(padID, rev=nil)
      params = {:padID => padID}
      params[:rev] = rev unless rev.nil?
      call :getText, params
    end

    # Sets the text of the given Pad
    def setText(padID, text)
      call :setText, :padID => padID, :text => text
    end

    # Pad
    # Group pads are normal pads, but with the name schema
    # GROUPID$PADNAME. A security manager controls access of them and
    # forbids normal pads from including a "$" in the name.

    # Create a new Pad. Optionally specify the initial text.
    def createPad(padID, text=nil)
      params = {:padID => padID}
      params[:text] = text unless text.nil?
      call :createPad, params
    end

    # Returns the number of revisions the given Pad contains
    def getRevisionsCount(padID)
      call :getRevisionsCount, :padID => padID
    end

    # Delete the given Pad
    def deletePad(padID)
      call :deletePad, :padID => padID
    end

    # Returns the Pad's read-only id
    def getReadOnlyID(padID)
      call :getReadOnlyID, :padID => padID
    end

    # Sets a boolean for the public status of a Pad
    def setPublicStatus(padID, publicStatus)
      call :setPublicStatus, :padID => padID, :publicStatus => publicStatus
    end

    # Gets a boolean for the public status of a Pad
    def getPublicStatus(padID)
      call :getPublicStatus, :padID => padID
    end

    # Sets the password on a pad
    def setPassword(padID, password)
      call :setPassword, :padID => padID, :password => password
    end

    # Returns true if the Pad has a password, false if not
    def isPasswordProtected(padID)
      call :isPasswordProtected, :padID => padID
    end

    # Returns true if the connection to the Etherpad Lite instance is using SSL/HTTPS.
    def secure?
      @uri.port == 443
    end

    protected

    # Parses the JSON response from the server, returning the data object as a Hash with symbolized keys.
    # If the API response contains an error code, an exception is raised.
    def handleResult(response)
      response = JSON.parse(response, :symbolize_names => true)
      case response[:code]
        when CODE_OK then response[:data]
        when CODE_INVALID_PARAMETERS, CODE_INVALID_API_KEY, CODE_INVALID_METHOD
          raise ArgumentError, response[:message]
        else
          raise StandardError, "An unknown error ocurrced while handling the response: #{response.to_s}"
      end
    end

    private

    # Initialize the HTTP connection object
    def connect!
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
  end
end

# Try to find the system's CA certs
%w{/etc/ssl/certs /etc/ssl /usr/share/ssl /usr/lib/ssl /System/Library/OpenSSL /usr/local/ssl}.each do |path|
  EtherpadLite::Client.ca_path = path and break if File.exists? path
end
$stderr.puts %q|WARNING Ruby etherpad-lite client was unable to find your CA Certificates; HTTPS connections will *not* be verified! You may remedy this with "EtherpadLite::Client.ca_path = '/path/to/certs'"| unless EtherpadLite::Client.ca_path
