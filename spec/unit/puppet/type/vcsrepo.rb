
require 'spec_helper'

describe Puppet::Type.type(:vcsrepo) do

  let(:vcsrepo) { described_class.new(:name => '/tmp/vcheck', :catalog => catalog, :ensure => :bare, :group => 'new-group') }
  let(:provider) { vcsrepo.provider }
  let(:catalog) { Puppet::Resource::Catalog.new }

  it "should update ownership" do
    expects_update_group('/tmp/vcheck', 'new-group')
    catalog.apply
  end
end

