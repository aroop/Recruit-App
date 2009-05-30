require 'labeling_form_helper_helper'

module ActionView::Helpers::FormTagHelper
  include LabelingFormHelperHelper
  
  # A list of labelable helpers.
  # We exclude password and file fields because they use a text field, 
  # so we would get double labels including them in the list.
  def self.labelable #:nodoc:
    public_instance_methods.
    reject { |h| h =~ /form|field_set|submit|hidden|password|file/ || h =~ /_with(out)?_label/ }.
    map { |x| x.to_sym }
  end
  
  labelable.each do |helper|
    define_method "#{helper}_with_label" do |*args|
      label = extract_label_options! args
      
      handle_disparate_args! helper, args
      
      unlabeled_tag = send "#{helper}_without_label", *args
      return unlabeled_tag unless label
      
      name = args.first.to_s
      label[:text] ||= name.humanize
      label[:for]  ||= name.gsub(/[^a-z0-9_-]+/, '_').gsub(/^_+|_+$/, '')
      
      render_label_and_tag label, unlabeled_tag
    end
    
    alias_method_chain helper, :label
  end
  
  # Test doesn't work, dunno why.. use with caution..
  def labeling_form_for(*args, &block)
    options = args.last.is_a?(Hash) ? args.pop : {}
    options[:builder] = LabelingFormBuilder
    args << options
    form_for *args, &block
  end
  
private
  # We want to account for certain optional arguments
  # that can occur before the options hash in the unlabeled helpers.
  #
  # Specifically, we want to be able to ignore them and say things like:
  #     check_box_tag :bulk_delete, :label => 'get outta here'
  def handle_disparate_args!(helper, args) #:nodoc:
    # Ignore the options hash, if present, until we are done munging the args.
    options = args.pop if args.last.is_a? Hash
    
    if args.size == 1
      if check_or_radio?(helper)
        args.insert 1, 1
      # Everything except :file_field_tag takes something as its second
      # argument which can be safely defaulted to +nil+.
      elsif helper != :file_field_tag
        args.insert 1, nil
      end
    end
    
    # :check_box_tag and :radio_button_tag can take another argument
    # to determine if they are 'checked' or not.
    if (2 == args.size) and check_or_radio?(helper)
      args.insert 2, false
    end
    
    # Reunite the options with the rest of the args.
    args << options if options
    
    args
  end
end