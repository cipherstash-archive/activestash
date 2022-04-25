module ActiveStash
  module RelationHelp # :nodoc:
    module Compatability # :nodoc:

      def self.included(base)
        base.extend ClassMethods
      end

      def unsupported!(method_name)
        # TODO: Use a proper class
        raise "'#{method_name}' is unsupported when used with encrypted queries or sorts"
      end

      module ClassMethods # :nodoc:
        def stash_wrap(*names)
          names.each do |name|
            define_method(name) do |*args|
              @scope = @scope.send(name, *args)
              self
            end
          end
        end

        def stash_unsupported(*names)
          names.each do |name|
            define_method(name) do |*args|
              if stash_query?
                unsupported!(name)
              else
                super
              end
            end
          end
        end
      end
    end
  end
end
