require File.dirname(__FILE__) + '/abstract_unit'

class OptionMergerTest < Test::Unit::TestCase
  def setup
    @options = { :hello => 'world' }
  end
  
  def test_method_with_options_merges_options_when_options_are_present
    local_options = {:cool => true}
    
    with_options(@options) do |o|
      assert_equal local_options, method_with_options(local_options)
      assert_equal @options.merge(local_options),
        o.method_with_options(local_options)
    end
  end
  
  def test_method_with_options_appends_options_when_options_are_missing
    with_options(@options) do |o|
      assert_equal Hash.new, method_with_options
      assert_equal @options, o.method_with_options
    end
  end
  
  def test_method_with_options_allows_to_overwrite_options
    local_options = {:hello => 'moon'}
    assert_equal @options.keys, local_options.keys
    
    with_options(@options) do |o|
      assert_equal local_options, method_with_options(local_options)
      assert_equal @options.merge(local_options),
        o.method_with_options(local_options)
      assert_equal local_options, o.method_with_options(local_options)
    end
    with_options(local_options) do |o|
      assert_equal local_options.merge(@options),
        o.method_with_options(@options)
    end
  end
  
  def test_method_with_merging_options_allows_to_merge_hash_options
    foo_options = { :foo  => { :bar => :baz } }
    more_foo_options = { :foo => { :bort => 'ATTENTION we need more bort license plates ' } }
    expected_options = { :foo => foo_options[:foo].merge(more_foo_options[:foo]) }
    
    with_merging_options(foo_options) do |o|
      assert o.merge_hash_options?
      assert_equal expected_options, o.method_with_options(more_foo_options)
    end
  end
  
  # Needed when counting objects with the ObjectSpace
  def test_option_merger_class_method
    assert_equal ActiveSupport::OptionMerger, ActiveSupport::OptionMerger.new('', '').class
  end
  
  private
    def method_with_options(options = {})
      options
    end
end
