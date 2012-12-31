# encoding: utf-8
module Mongoid
  module Persistence
    module Atomic

      # Performs atomic $unset operations.
      class Unset
        include Operation

        attr_accessor :fields

        def initialize(document, fields, value, options = {})
          @document, @value, @options = document, value, options

          @fields = Array.wrap(fields).collect do |field|
            document.database_field_name(field.to_s)
          end

          self.class.send(:define_method, :field) do
            @fields.first
          end if @fields.length == 1

        end

        def operation(modifier)
          hash = Hash[fields.collect do |field|
            [path(field), cast_value]
          end]
          { modifier => hash }
        end

        def path(field = field)
          position = document.atomic_position
          position.blank? ? field : "#{position}.#{field}"
        end

        def execute(name)
          unless document.new_record?
            collection.find(document.atomic_selector).update(operation(name))
            if fields.length > 1
              document.remove_change(fields)
            else
              document.remove_change(field)
            end
          end
        end

        # Sends the atomic $unset operation to the database.
        #
        # @example Persist the new values.
        #   unset.persist
        #
        # @return [ nil ] The new value.
        #
        # @since 2.1.0
        def persist
          prepare do
            fields.each { |f| document.attributes.delete(f) }
            execute("$unset")
          end
        end
      end
    end
  end
end
