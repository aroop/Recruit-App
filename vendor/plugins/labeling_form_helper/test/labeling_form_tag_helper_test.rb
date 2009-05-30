%w(
set
rubygems
action_controller
action_view
test/unit
mocha
).each { |x| require x }

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

%w(
labeling_form_tag_helper
labeling_form_builder
).each { |x| require x }

class LabelingFormTagHelperTest < Test::Unit::TestCase
  include ActionView::Helpers::TagHelper,
          ActionView::Helpers::FormTagHelper
  
  def test_original_behavior
    labelable.each do |helper|
      assert_no_match %r(<label), send(helper, :foo)
    end
  end
  
  def test_custom_id_affects_label_for_attribute
    labelable.each do |helper|
      assert_match %r(<label.+for="bar"[^>]*>), send(helper, :foo, :id => :bar, :label => true)
    end
  end
  
  def test_label_id
    labelable.each do |helper|
      assert_match %r(<label.+id="foo"[^>]*>), send(helper, :foo, :label => { :id => :foo })
    end
  end
  
  def test_label_class
    labelable.each do |helper|
      assert_match %r(<label.+class="foo"[^>]*>), send(helper, :foo, :label => { :class => :foo })
    end
  end
  
  def test_label_wrap
    labelable.each do |helper|
      assert_match %r(</label>\Z), send(helper, :foo, :label => { :wrap => true })
    end
  end
  
  def test_label_after_with_wrap
    label_after_options = [
      { :wrap => true, :after => true },
      { :wrap => :after }
    ]
    
    label_after_options.each do |opts|
      labelable.each do |helper|
        tag = send helper, :foo, :label => opts
        assert_match    %r(Foo</label>\Z),    tag
        assert_no_match %r(<label[^>]*?>Foo), tag
      end
    end
  end
  
  def test_label_after
    labelable.each do |helper|
      tag = send helper, :foo, :label => { :after => true }
      assert_match    %r(Foo</label>\Z), tag
      assert_no_match %r(\A<label>), tag
    end
  end
  
  def test_labels_once
    labelable.each do |helper|      
      label_tags = send(helper, :foo, :label => true).scan(%r(</?label)).size      
      assert_equal 2, label_tags, ":#{helper} labeled #{label_tags / 2} times"
    end
  end
  
  def test_with_options
    with_options :label => true do |foo|
      labelable.each do |helper|
        assert_match %r(<label for="foo">Foo</label>), foo.send(helper, :foo)
      end
    end
  end
  
  begin
    require File.dirname(__FILE__) + '/with_merging_options/lib/with_merging_options'
    # This test is getting a little messy with the regexp approach.
    # TODO a better way to express those assertions?
    def test_with_merging_options
      with_merging_options :label => { :text => 'bar' } do |foo|
        labelable.each do |helper|
          output = foo.send(helper, :foo, :label => { :class => 'baz' })
          assert_match %r(bar</label>), output
          assert_match %r(<label .*?class="baz".*?>), output
          assert_match %r(<label .*?for="foo".*?>), output
        end
      end
    end
  rescue LoadError
    puts 'with_merging_options not tested'
  end
  
  def test_labeling_form_for
    block = proc {}
    args = [:foo, @foo]
    args_with_builder_option = args << { :builder => LabelingFormBuilder }
    expects(:form_for).with(*args_with_builder_option, &block)
    labeling_form_for(*args, &block)
  end
  
  def test_labeling_form_for_with_options
    block = proc {}
    args = [:foo, @foo, { :method => :post }]
    args_with_builder_option = args.dup
    args_with_builder_option.last[:builder] = LabelingFormBuilder
    expects(:form_for).with(*args_with_builder_option, &block)
    labeling_form_for(*args, &block)
  end
  
private
  def labelable
    ActionView::Helpers::FormTagHelper.labelable
  end
end
