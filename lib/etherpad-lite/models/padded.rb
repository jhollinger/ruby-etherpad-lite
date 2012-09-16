module EtherpadLite
  # Methods for dealing with pads belonging to something. Both Instance and Group include this, as they each have pads.
  # This will work with any object which has an instance method, returning an EtherpadLite Instance object.
  module Padded
    # Returns the Pad with the given id, creating it if it doesn't already exist.
    # This requires an HTTP request, so if you *know* the Pad already exists, use Instance#get_pad instead.
    def pad(id, options={})
      begin
        Pad.create(instance, id, options)
      # Pad alreaded exists
      rescue Error
        Pad.new(instance, id, options)
      end
    end

    # Returns the Pad with the given id (presumed to already exist).
    # Use this instead of Instance#pad when you *know* the Pad already exists; it will save an HTTP request.
    def get_pad(id, options={})
      Pad.new instance, id, options
    end

    # Creates and returns a Pad with the given id.
    # 
    # Options:
    # 
    # text => 'initial Pad text'
    def create_pad(id, options={})
      Pad.create instance, id, options
    end
  end
end
