
require 'spec_helper'

describe Puppet::Type.type(:vcsrepo), :resource => { :name => '/tmp/vcheck' } do

  let :resource do
    resource_hash = {}

    current_klass = self.class

    until current_klass == RSpec::Core::ExampleGroup
      metadata = current_klass.metadata
      resource_hash.merge!(metadata[:resource]) if metadata[:resource].kind_of?(Hash)
      current_klass = current_klass.superclass
    end

    resource_hash[:catalog] = catalog
    resource_hash
  end

  let(:vcsrepo)   { described_class.new(resource) }
  let(:provider)  { vcsrepo.provider }
  let(:catalog)   { Puppet::Resource::Catalog.new }

  before(:each) do
    # stub this to not try to create state.yaml
    Puppet::Util::Storage.stubs(:store)
  end

  context "git provider", :resource => {:provider => :git} do
    context "#edit" do

      resource_with :ensure => :bare, :group => 'new-group' do
        it 'should recursively update group ownership' do
          expects_update_group('/tmp/vcheck', 'new-group')

          provider.stubs(:exists?).returns(true)

          catalog.add_resource(vcsrepo)

          catalog.apply.report
        end
      end
    end
  end
end

