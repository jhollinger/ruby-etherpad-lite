module EtherpadLite
  # An Etherpad Lite Pad
  # 
  # This class allows you to interact with pads stored in an Etherpad Lite server. The README 
  # has some basic examples.
  # 
  # Note that some functions are restricted to Group pads.
  # 
  class Pad
    # The EtherpadLite::Instance object
    attr_reader :instance
    # The pad id
    attr_reader :id
    # An optional pad revision number
    attr_reader :rev

    # Creates and returns a new Pad.
    # 
    # Options:
    # 
    # text => 'initial Pad text'
    # 
    # groupID => group id of Group new Pad should belong to
    def self.create(instance, id, options={})
      if options[:groupID]
        group = Group.new instance, options[:groupID]
        instance.client.createGroupPad(groupID: group.id, padName: degroupify_pad_id(id), text: options[:text])
      else
        group = nil
        instance.client.createPad(padID: id, text: options[:text])
      end
      new instance, id, groupID: options[:groupID], group: group
    end

    # Remove the group id portion of a Group Pad's id
    def self.degroupify_pad_id(pad_id)
      pad_id.to_s.sub(Group::GROUP_ID_REGEX, '').sub(/^\$/, '')
    end

    # Instantiate a Pad. It is presumed to already exist (via Pad.create).
    # 
    # Options:
    # 
    # groupID => a group id
    # 
    # group => an EtherpadLite::Group object
    # 
    # rev => a pad revision number
    def initialize(instance, id, options={})
      @instance = instance
      @id = id.to_s
      if options[:groupID]
        @group_id = options[:groupID]
        @id = "#{@group_id}$#{@id}" unless @id =~ Group::GROUP_ID_REGEX
      end
      @group = options[:group]
      @rev = options[:rev]
    end

    # Returns the name of the Pad. For a normal pad, this is the same as it's id. But for a Group Pad,
    # this strips away the group id part of the pad id.
    def name
      @name ||= self.class.degroupify_pad_id(@id)
    end

    # Returns the group_id of this Pad, if any
    def group_id
      unless @group_id
        match = Group::GROUP_ID_REGEX.match(@id)
        @group_id = match ? match[0] : nil
      end
      @group_id
    end

    # Returns this Pad's group, if any
    def group
      return nil unless group_id
      @group ||= Group.new(@instance, group_id)
    end

    # Returns the Pad's text. Unless you specified a :rev when instantiating the Pad, or specify one here, this will return the latest revision.
    # 
    # Options:
    # 
    # rev => revision_number
    def text(options={})
      options[:padID] = @id
      options[:rev] ||= @rev unless @rev.nil?
      @instance.client.getText(options)[:text]
    end

    # Writes txt to the Pad. There is no 'save' method; it is written immediately.
    def text=(txt)
      @instance.client.setText(padID: @id, text: txt)
    end

    # Returns the Pad's text as HTML. Unless you specified a :rev when instantiating the Pad, or specify one here, this will return the latest revision.
    # 
    # Options:
    # 
    # rev => revision_number
    def html(options={})
      options[:padID] = @id
      options[:rev] ||= @rev unless @rev.nil?
      @instance.client.getHTML(options)[:html]
    end

    # Writes HTML to the Pad. There is no 'save' method; it is written immediately.
    def html=(html)
      @instance.client.setHTML(padID: @id, html: html)
    end

    # Returns an Array of all this Pad's revision numbers
    def revision_numbers
      max = @instance.client.getRevisionsCount(padID: @id)[:revisions]
      (0..max).to_a
    end

    # Returns an array of Pad objects, each with an increasing revision of the text.
    def revisions
      revision_numbers.map { |n| Pad.new(@instance, @id, :rev => n) }
    end

    # Returns a Diff. If end_rev is not specified, the latest revision will be used
    def diff(start_rev, end_rev=nil)
      Diff.new(self, start_rev, end_rev)
    end

    # Returns the changeset for the given revision
    def changeset(rev)
      @instance.client.getRevisionChangeset(padID: @id, rev: rev)
    end

    # Returns an array of users hashes, representing users currently using the pad
    def users
      @instance.client.padUsers(padID: @id)[:padUsers]
    end

    # Returns the number of users currently editing a pad
    def user_count
      @instance.client.padUsersCount(padID: @id)[:padUsersCount]
    end
    alias_method :users_count, :user_count

    # Returns the Pad's read-only id. This is cached.
    def read_only_id
      @read_only_id ||= @instance.client.getReadOnlyID(padID: @id)[:readOnlyID]
    end

    # Returns the time the pad was last edited as a Unix timestamp
    def last_edited
      @instance.client.getLastEdited(padID: @id)[:lastEdited]
    end

    # Returns an array of ids of authors who've edited this pad
    def author_ids
      @instance.client.listAuthorsOfPad(padID: @id)[:authorIDs] || []
    end

    # Returns an array of Authors who've edited this pad
    def authors
      author_ids.map { |id| Author.new(@instance, id) }
    end

    # Returns an array of chat message Hashes
    def chat_messages(start_index=nil, end_index=nil)
      messages = @instance.client.getChatHistory(:padID => @id, :start => start_index, :end => end_index)[:messages]
      messages.map do |msg|
        attrs = {padID: @id}.merge(msg)
        ChatMessage.new(@instance, attrs)
      end
    end

    # Returns the number of chat messages
    def chat_size
      @instance.client.getChatHead(padID: @id)[:chatHead] + 1
    end

    # Returns true if this is a public Pad (opposite of private?).
    # This only applies to Pads belonging to a Group.
    def public?
      @instance.client.getPublicStatus(padID: @id)[:publicStatus]
    end

    # Set the pad's public status to true or false (opposite of private=)
    # This only applies to Pads belonging to a Group.
    def public=(status)
      @instance.client.setPublicStatus(padID: @id, publicStatus: status)
    end

    # Returns true if this is a private Pad (opposite of public?)
    # This only applies to Pads belonging to a Group.
    def private?
      not self.public?
    end

    # Set the pad's private status to true or false (opposite of public=)
    # This only applies to Pads belonging to a Group.
    def private=(status)
      self.public = !status
    end

    # Returns true if this Pad has a password, false if not.
    # This only applies to Pads belonging to a Group.
    def password?
      @instance.client.isPasswordProtected(padID: @id)[:isPasswordProtected]
    end

    # Sets the Pad's password.
    # This only applies to Pads belonging to a Group.
    def password=(new_password)
      @instance.client.setPassword(padID: @id, password: new_password)
    end

    # Sends a custom message of type msg to the pad.
    def message(msg)
      @instance.client.sendClientsMessage(padID: @id, msg: msg)
    end

    # Deletes the Pad
    def delete
      @instance.client.deletePad(padID: @id)
    end
  end
end
