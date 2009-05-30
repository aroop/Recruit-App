module LabelingFormHelperHelper #:nodoc:
private
  # return label and tag according to custom options
  def render_label_and_tag(label, unlabeled_tag, template = self)
    label_html = extract_label_html! label
    
    if label[:wrap]
      label_and_tag = if label[:after] or :after == label[:wrap]
        [unlabeled_tag, label[:text]]
      else
        [label[:text], unlabeled_tag]
      end.join("\n")
      
      template.content_tag(:label, label_and_tag, label_html)
      
    elsif label[:after]
      unlabeled_tag + template.content_tag(:label, label[:text], label_html)
      
    else
      template.content_tag(:label, label[:text], label_html) + unlabeled_tag
    end
  end
  
  def extract_label_options!(args, builder = false) #:nodoc:
    options = args.last.is_a?(Hash) ? args.last : {}
    
    label = options.delete :label
    
    # Default behavior for the builder is to be ON, so a missing :label option still means to use the plugin.
    # Default behavior for the tag helpers is to be OFF, so a missing :label option is like :label => false in the builder.
    if (label.nil? and !builder) or (false == label)
      return false
    end
    
    # From here on, we need a Hash..
    label = case label
    when Hash     then label
    when String   then { :text => label }
    when nil,true then {}
    end
    
    # Per the HTML spec..
    label[:for] = options[:id]
    
    label
  end
  
  def extract_label_html!(label) #:nodoc:
    [:id, :class, :for].inject({}) { |html,k| html.merge k => label.delete(k) }
  end
  
  def check_or_radio?(helper) #:nodoc:
    [:check_box_tag, :radio_button_tag].include? helper.to_sym
  end
end
