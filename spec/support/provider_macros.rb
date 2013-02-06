require 'etc'

module ProviderMacros

  def self.extended(base)
    base.class_eval do

      subject { described_class.new(@resource) }

      attr_accessor :resource

      def provider
        subject
      end

      def traverse_through_metadata_for(key)
        resource_hash = {}

        current_klass = self.class

        until current_klass == RSpec::Core::ExampleGroup
          metadata = current_klass.metadata
          resource_hash.merge!(metadata[key]) if metadata[key].kind_of?(Hash)
          current_klass = current_klass.superclass
        end

        resource_hash
      end

    end
  end


  # Generate a context for a provider operating on a resource with:
  #
  # call-seq:
  #
  #   # A parameter/property set (when the value isn't important)
  #   resource_with :source do
  #     # ...
  #   end
  #
  #   # A parameter/property set to a specific value
  #   resource_with :source => 'a-specific-value' do
  #     # ...
  #   end
  #
  # Note: Choose one or the other (mixing will create two separate contexts)
  #
  def resource_with(*params, &block)
    params_with_values = params.last.is_a?(Hash) ? params.pop : {}
    build_value_context(params_with_values, &block)
    build_existence_context(*params, &block)
  end

  def build_existence_context(*params, &block) #:nodoc:
    unless params.empty?
      text = params.join(', ')
      placeholders = params.inject({}) { |memo, key| memo.merge(key => 'an-unimportant-value') }
      context("and with a #{text}", {:resource => placeholders}, &block)
    end
  end

  def build_value_context(params = {}, &block) #:nodoc:
    unless params.empty?
      text = params.map { |k, v| "#{k} => #{v.inspect}" }.join(' and with ')
      context("and with #{text}", {:resource => params}, &block)
    end
  end

  def with_update_resource(what, &block)

    metadata = what.reduce(:message => [], :resource => {}, :prestine => {}) do |acc,el|
      acc[:message]             << "property #{el.first.inspect} from #{el.last[:from].inspect} to #{el.last[:to].inspect}"
      acc[:resource][el.first]  = el.last[:to]
      acc[:prestine][el.first]  = el.last[:from]
      acc
    end

    prestine_block = lambda do |arg|

      before(:each) do
        c = Puppet::Resource::Catalog.new
        r = described_class.new(resource.merge(prestine_resource))
        c.add_resource(r)
        c.apply
      end

      context(&block)
    end

    context(  "with update #{metadata[:message].join(' and ')}",
              {
                :resource           => metadata[:resource],
                :prestine_resource  => metadata[:prestine]
              },&prestine_block)

  end

  def actual_group(group)
    stat = mock('file:stat')

    gid = gid_by_group(group)

    stat.stubs(:gid).returns(gid)

    File.stubs(:stat).with(@superclass_metadata[:resource][:path]).returns(stat)

    yield
  end

  def gid_by_group(group)
    groupdb = []

    while entry = Etc.passwd
      groupdb << entry
    end

    if found = groupdb.detect { |el| el.name == group }
      found.gid
    end
  end


  # Generate a context for a provider operating on a resource without
  # a given parameter/property.
  #
  # call-seq:
  #
  #   resource_without :source do
  #     # ...
  #   end
  #
  def resource_without(field, &block)
    context("and without a #{field}", &block)
  end

end

# Outside wrapper to lookup a provider and start the spec using ProviderExampleGroup
def describe_provider(type_name, provider_name, options = {}, &block)
  provider_class = Puppet::Type.type(type_name).provider(provider_name)
  describe(provider_class, options.merge(:type => :provider), &block)
end
