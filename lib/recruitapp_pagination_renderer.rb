class RecruitappPaginationRenderer < WillPaginate::LinkRenderer
  
  def to_html
    links = @options[:page_links] ? windowed_links : []
    
    links.unshift(prev_next_link(@collection.previous_page, @options[:previous_label]))
    links.push(prev_next_link(@collection.next_page, @options[:next_label]))
    
    html = "#{page_number} <ul class=pag_list> #{links.join(@options[:separator])} </ul>" 
    
    @options[:container] ? @template.content_tag(:div, html, html_attributes) : html
  end

protected

  def page_number
    "<span class=page_no>Page #{current_page} of #{total_pages}</span>"
  end
  
  def prev_next_link(page, text)
    text ||= page.to_s
    
    if page && page != current_page
      @template.content_tag(:li, @template.link_to(text, url_for(page), :class => "button light_blue_btn"))    
    else
      @template.content_tag(:li, text)
    end    
  end

  def windowed_links
    visible_page_numbers.map { |n| page_link(n, (n == current_page ? 'current_page' : nil)) }
  end

  def page_link(page, span_class)
    text ||= "<span><span>#{page.to_s}</span></span>"
    @template.content_tag(:li, @template.link_to(text, url_for(page), :class => span_class))
  end

end