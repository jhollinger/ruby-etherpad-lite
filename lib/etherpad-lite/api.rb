module EtherpadLite
  # Holds all API methods and versions. For internal use by EtherpadLite::Client, only.
  class API
    # Supported Etherpad Lite API versions
    VERSIONS = %w[1]

    # The API version
    attr_reader :version

    # The EtherpadLite::Client object
    attr_reader :client

    # Instantiates support for the given API version. "client" is used to actually communicate with the server.
    def initialize(version, client)
      @version = version.to_s
      @client = client
      raise Error, "API version #{@version} is not supported" unless VERSIONS.include? @version
    end

    # Groups
    # Pads can belong to a group. There will always be public pads which don't belong to a group.

    # Creates a new Group
    def createGroup
      client.post :createGroup
    end

    # Creates a new Group for groupMapper if one doesn't already exist. Helps you map your application's groups to Etherpad Lite's groups.
    def createGroupIfNotExistsFor(groupMapper)
      client.post :createGroupIfNotExistsFor, :groupMapper => groupMapper
    end

    # Deletes a group
    def deleteGroup(groupID)
      client.post :deleteGroup, :groupID => groupID
    end

    # Returns all the Pads in the given Group
    def listPads(groupID)
      client.get :listPads, :groupID => groupID
    end

    # Creates a new Pad in the given Group
    def createGroupPad(groupID, padName, text=nil)
      params = {:groupID => groupID, :padName => padName}
      params[:text] = text unless text.nil?
      client.post :createGroupPad, params
    end

    # Authors
    # These authors are bound to the attributes the users choose (color and name).

    # Create a new Author
    def createAuthor(name=nil)
      params = {}
      params[:name] = name unless name.nil?
      client.post :createAuthor, params
    end

    # Creates a new Author for authorMapper if one doesn't already exist. Helps you map your application's authors to Etherpad Lite's authors.
    def createAuthorIfNotExistsFor(authorMapper, name=nil)
      params = {:authorMapper => authorMapper}
      params[:name] = name unless name.nil?
      client.post :createAuthorIfNotExistsFor, params
    end

    # Lists all pads belonging to the autor
    def listPadsOfAuthor(authorID)
      client.get :listPadsOfAuthor, :authorID => authorID
    end

    # Sessions
    # Sessions can be created between a group and an author. This allows
    # an author to access more than one group. The sessionID will be set as
    # a cookie to the client and is valid until a certian date.

    # Creates a new Session for the given Author in the given Group
    def createSession(groupID, authorID, validUntil)
      client.post :createSession, :groupID => groupID, :authorID => authorID, :validUntil => validUntil
    end

    # Deletes the given Session
    def deleteSession(sessionID)
      client.post :deleteSession, :sessionID => sessionID
    end

    # Returns information about the Session
    def getSessionInfo(sessionID)
      client.get :getSessionInfo, :sessionID => sessionID
    end

    # Returns all Sessions in the given Group
    def listSessionsOfGroup(groupID)
      client.get :listSessionsOfGroup, :groupID => groupID
    end

    # Returns all Sessions belonging to the given Author
    def listSessionsOfAuthor(authorID)
      client.get :listSessionsOfAuthor, :authorID => authorID
    end

    # Pad content
    # Pad content can be updated and retrieved through the API

    # Returns the text of the given Pad. Optionally pass a revision number to get the text for that revision.
    def getText(padID, rev=nil)
      params = {:padID => padID}
      params[:rev] = rev unless rev.nil?
      client.get :getText, params
    end

    # Sets the text of the given Pad
    def setText(padID, text)
      client.post :setText, :padID => padID, :text => text
    end

    # Returns the text of the given Pad as HTML. Optionally pass a revision number to get the HTML for that revision.
    def getHTML(padID, rev=nil)
      params = {:padID => padID}
      params[:rev] = rev unless rev.nil?
      client.get :getHTML, params
    end

    # Sets the HTML text of the given Pad
    def setHTML(padID, html)
      client.post :setHTML, :padID => padID, :html => html
    end

    # Pad
    # Group pads are normal pads, but with the name schema
    # GROUPID$PADNAME. A security manager controls access of them and
    # forbids normal pads from including a "$" in the name.

    # Create a new Pad. Optionally specify the initial text.
    def createPad(padID, text=nil)
      params = {:padID => padID}
      params[:text] = text unless text.nil?
      client.post :createPad, params
    end

    # Returns the number of revisions the given Pad contains
    def getRevisionsCount(padID)
      client.get :getRevisionsCount, :padID => padID
    end

    # Returns the number of users currently editing the pad
    def padUsersCount(padID)
      client.get :padUsersCount, :padID => padID
    end

    # Returns the time the pad was last edited as a Unix timestamp
    def getLastEdited(padID)
      client.get :getLastEdited, :padID => padID
    end

    # Delete the given Pad
    def deletePad(padID)
      client.post :deletePad, :padID => padID
    end

    # Returns the Pad's read-only id
    def getReadOnlyID(padID)
      client.get :getReadOnlyID, :padID => padID
    end

    def listAuthorsOfPad(padID)
      client.get :listAuthorsOfPad, :padID => padID
    end

    # Sets a boolean for the public status of a Pad
    def setPublicStatus(padID, publicStatus)
      client.post :setPublicStatus, :padID => padID, :publicStatus => publicStatus
    end

    # Gets a boolean for the public status of a Pad
    def getPublicStatus(padID)
      client.get :getPublicStatus, :padID => padID
    end

    # Sets the password on a pad
    def setPassword(padID, password)
      client.post :setPassword, :padID => padID, :password => password
    end

    # Returns true if the Pad has a password, false if not
    def isPasswordProtected(padID)
      client.get :isPasswordProtected, :padID => padID
    end
  end
end
