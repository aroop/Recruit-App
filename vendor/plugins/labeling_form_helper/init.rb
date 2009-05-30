require 'labeling_form_builder'
require 'labeling_form_tag_helper'

class ActionView::Base
  include LabelingFormHelperHelper
end
