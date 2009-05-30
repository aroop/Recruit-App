require 'labeling_form_helper_helper'

class LabelingFormBuilder < ActionView::Helpers::FormBuilder
  include LabelingFormHelperHelper
  
  # A list of labelable helpers. We exclude password and file fields because they use text field,
  # so we would get double labels including them.
  def self.labelable
    ((field_helpers + public_instance_methods.grep(/select/)) - 
    %w( form_for fields_for hidden_field password_field file_field field_set )).
    map { |x| x.to_sym }
  end
  
  labelable.each do |helper|
    define_method helper do |*args|
      label = extract_label_options! args, true
      
      unlabeled_tag = super
      return unlabeled_tag if false == label
      
      label[:for]  ||= extract_for unlabeled_tag
      label[:text] ||= args.first.to_s.humanize
      
      render_label_and_tag label, unlabeled_tag, @template
    end
  end
  
private
  def extract_id(tag)
    tag[/\[([^]]+)\]/, 1]
  end
  
  def extract_for(tag)
    tag[/id="([^"]+)"/, 1]
  end
end