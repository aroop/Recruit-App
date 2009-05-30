module ActiveSupport
  class OptionMerger #:nodoc:
    instance_methods.each do |method|
      if method !~ /^(__|instance_eval|class|object_id|inspect)/
        undef_method(method)
      end
    end
    
    def initialize(context, options, merge_hash_options = false)
      @context, @options = context, options
      @merge_hash_options = merge_hash_options
    end
    
    def merge_hash_options?
      @merge_hash_options
    end
    
    private
      def method_missing(method, *arguments, &block)
        merge_argument_options! arguments
        @context.send!(method, *arguments, &block)
      end
      
      def merge_argument_options!(arguments)
        arguments << if arguments.last.respond_to? :to_hash
          options_arg = arguments.pop
          
          if merge_hash_options?
            options_arg.keys.each do |k|
              if @options[k].respond_to? :to_hash
                options_arg[k] = options_arg[k].merge(@options[k])
              end
            end
          end
          
          @options.merge(options_arg)
        else
          @options.dup
        end
      end
  end
end
