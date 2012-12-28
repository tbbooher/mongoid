# encoding: utf-8
module Mongoid
  module Relations
    module Touchable
      extend ActiveSupport::Concern

      included do
        class_attribute :touchables
        self.touchables = []
      end

      # Touch the document, in effect updating its updated_at timestamp and
      # optionally the provided field to the current time. If any belongs_to
      # relations exist with a touch option, they will be updated as well.
      #
      # @example Update the updated_at timestamp.
      #   document.touch
      #
      # @example Update the updated_at and provided timestamps.
      #   document.touch(:audited)
      #
      # @note This will not autobuild relations if those options are set.
      #
      # @param [ Symbol ] field The name of an additional field to update.
      #
      # @return [ true ] true.
      #
      # @since 3.0.0
      def touch(field = nil)
        current = Time.now
        write_attribute(:updated_at, current) if fields["updated_at"]
        write_attribute(field, current) if field
        _root.collection.find(atomic_selector).update(touch_atomic_updates(field))
        without_autobuild do
          self.touchables.each { |name| send(name).try(:touch) }
        end
        move_changes and true
      end

      module ClassMethods

        # Add the metadata to the touchable relations if the touch option was
        # provided.
        #
        # @example Add the touchable.
        #   Model.touchable(meta)
        #
        # @param [ Metadata ] metadata The relation metadata.
        #
        # @return [ Class ] The model class.
        #
        # @since 3.0.0
        def touchable(metadata)
          self.touchables.push(metadata.name) if metadata.touchable?
          self
        end
      end
    end
  end
end
