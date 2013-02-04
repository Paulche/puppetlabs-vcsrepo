require 'etc'

module ProviderMacros

  def self.extended(base)
    base.class_eval do

      subject { described_class.new(@resource) }

      attr_accessor :resource

      def provider
        subject
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
