module EtherpadLite
  # Contains all API methods. Note that only a subset may be available depending on the API version you chose to use.
  module API
    # Supported Etherpad Lite API versions
    VERSIONS = %w[1] # :nodoc:

    # Raises an EtherpadLite::Error if the version is invalid
    def verify_api_version!
      raise Error, "API version #{api_version} is not supported" unless VERSIONS.include? api_version
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

    # Lists all pads belonging to the autor
    def listPadsOfAuthor(authorID)
      get :listPadsOfAuthor, :authorID => authorID
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

    # Returns the number of users currently editing the pad
    def padUsersCount(padID)
      get :padUsersCount, :padID => padID
    end

    # Returns the time the pad was last edited as a Unix timestamp
    def getLastEdited(padID)
      get :getLastEdited, :padID => padID
    end

    # Delete the given Pad
    def deletePad(padID)
      post :deletePad, :padID => padID
    end

    # Returns the Pad's read-only id
    def getReadOnlyID(padID)
      get :getReadOnlyID, :padID => padID
    end

    def listAuthorsOfPad(padID)
      get :listAuthorsOfPad, :padID => padID
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
  end
end
