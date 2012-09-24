module EtherpadLite
  # A Group serves as a container for related pads. Only an Author with a Session can access a group Pad.
  # 
  # Group examples:
  # 
  #  # Create a new group
  #  group1 = @ether.create_group
  #  # Etherpad Lite will assign it an internal id
  #  group.id #> 'g.asdflsadf7w9823kjlasdf' 
  # 
  #  # Create a new group with a mapper, so it can be easily found again
  #  group2 = @ether.create_group :mapper => 'Blurg'
  # 
  #  # Load (or create, if it doesn't exist) a group mapped to "Flarb"
  #  group3 = @ether.group('Flarb')
  # 
  #  # Load an existing group based on its internal id
  #  group4 = @ether.get_group('g.823lasdlfj98asdfj')
  # 
  # Group pad examples:
  # 
  #  # Create a new pad in this group, optionally specifying its initial text
  #  pad1 = group1.create_pad('group 1 pad', :text => 'Words!')
  # 
  #  # Load (or create, if it doesn't exist) a pad in this group
  #  pad2 = group2.pad('group 2 pad')
  # 
  #  # Load an existing pad from group 2
  #  pad3 = group2.get_pad('important pad')
  # 
  # Session examples:
  # 
  #  # Create two hour-long session for an author in group 1
  #  author = @ether.author('author_1')
  #  session = group1.create_session(author, 60)
  # 
  # Understand how ids work. A group pad's id is the group_id + '$' + pad_name:
  # 
  #  pad2.group_id == group2.id #> true
  # 
  #  pad2.id == group2.id + '$' + pad2.name #> true
  # 
  #  pad2 == group2.pad('group 2 pad') == @ether.get_pad("#{group2.id}$group 2 pad") == @ether.get_pad('group 2 pad', :groupID => group2.id) #> true
  # 
  #  group2.mapper #> "Blurg"
  # 
  class Group
    GROUP_ID_REGEX = /^g\.[^\$]+/
    include Padded

    # The EtherpadLite::Instance object
    attr_reader :instance
    # The group id
    attr_reader :id
    # An optional identifier used to map the group to something outside Etherpad Lite
    attr_reader :mapper

    # Creates a new Group. Optionally, you may pass the :mapper option your third party system's group id.
    # This will allow you to find your Group again later using the same identifier as your foreign system.
    # If you pass the mapper option, the method behaves like "create group for <mapper> if it doesn't already exist".
    # 
    # Options:
    # 
    # mapper => your foreign group id
    def self.create(instance, options={})
      result = options[:mapper] \
        ? instance.client.createGroupIfNotExistsFor(groupMapper: options[:mapper]) \
        : instance.client.createGroup
      new instance, result[:groupID], options
    end

    # Instantiates a Group object (presumed it already exists)
    # 
    # Options:
    # 
    # mapper => the foreign id it's mapped to
    def initialize(instance, id, options={})
      @instance = instance
      @id = id
      @mapper = options[:mapper]
    end

    # Returns the Pad with the given id, creating it if it doesn't already exist.
    # This requires an HTTP request, so if you *know* the Pad already exists, use Group#get_pad instead.
    def pad(id, options={})
      options[:groupID] = @id
      super groupify_pad_id(id), options
    end

    # Returns the Pad with the given id (presumed to already exist).
    # Use this instead of Group#pad when you *know* the Pad already exists; it will save an HTTP request.
    def get_pad(id, options={})
      options[:group] = self
      super groupify_pad_id(id), options
    end

    # Creates and returns a Pad with the given id.
    # 
    # Options:
    # 
    # text => 'initial Pad text'
    def create_pad(id, options={})
      options[:groupID] = @id
      super groupify_pad_id(id), options
    end

    # Returns an array of all the Pads in this Group.
    def pads
      pad_ids.map { |id| Pad.new(@instance, id, :group => self) }
    end

    # Returns an array of all the Pad ids in this Group.
    def pad_ids
      @instance.client.listPads(groupID: @id)[:padIDs]
    end

    # Create a new session for author that will last length_in_minutes.
    def create_session(author, length_in_min)
      Session.create(@instance, @id, author.id, length_in_min)
    end

    # Returns all session ids in this Group
    def session_ids
      s = @instance.client.listSessionsOfGroup(groupID: @id) || {}
      s.keys
    end

    # Returns all sessions in this Group
    def sessions
      s = @instance.client.listSessionsOfGroup(groupID: @id) || {}
      s.map { |id,info| Session.new(@instance, id, info) }
    end

    # Deletes the Group
    def delete
      @instance.client.deleteGroup(groupID: @id)
    end

    private

    # Prepend the group_id to the pad name
    def groupify_pad_id(pad_id)
      pad_id =~ GROUP_ID_REGEX ? pad_id : "#{@id}$#{pad_id}"
    end
  end
end
