module EtherpadLite
  # Represents a diff between two Pad revisions.
  class Diff
    # The EtherpadLite::Instance object
    attr_accessor :instance
    # The EtherpadLite::Pad object
    attr_accessor :pad
    # Diff start revision
    attr_accessor :start_rev
    # Diff end revision
    attr_accessor :end_rev

    # If end_rev is not specified, the latest revision will be used
    def initialize(pad, start_rev, end_rev=nil)
      @instance = pad.instance
      @pad = pad
      @start_rev = start_rev
      @end_rev = end_rev || pad.revision_numbers.last
    end

    # Returns the diff as html
    def html
      diff[:html]
    end

    # Returns the IDs of the authors who were involved in the diff
    def author_ids
      diff[:authors]
    end

    # Returns Authors who were involved in the diff
    def authors
      @authors ||= author_ids.map { |id| Author.new(instance, id) }
    end

    private

    # Queries and caches the diff
    def diff
      @diff ||= instance.client.createDiffHTML(padID: pad.id, startRev: start_rev, endRev: end_rev)
    end
  end
end
