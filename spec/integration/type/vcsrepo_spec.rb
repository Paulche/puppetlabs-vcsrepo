
require 'spec_helper'

$restricted_user = 'paulche'

describe Puppet::Type.type(:vcsrepo), :resource => { :name => '/tmp/vcheck' } do

  let :resource do
    traverse_through_metadata_for :resource
  end

  let :prestine_resource do
    traverse_through_metadata_for :prestine_resource
  end

  before(:all) do
    #
    ## Root permition is required for vast majority of tests
    #
    raise Exception, "Root permition is required" unless Puppet::Util::SUIDManager.root?
  end

  let(:vcsrepo)   { described_class.new(resource) }
  let(:provider)  { vcsrepo.provider }
  let(:catalog)   { Puppet::Resource::Catalog.new }

  before(:each) do
    # stub this to not try to create state.yaml
    Puppet::Util::Storage.stubs(:store)
  end

  after(:each) do
   # Teardown
   FileUtils.rm_rf resource[:name]
  end

  context "git provider", :resource => {:provider => :git} do

    resource_with :ensure => :bare do
      with_update_resource :group => { :from => 'wheel', :to => 'nobody' } do
        context "without permition" do
          it 'should failed with log message' do
            Puppet::Util::SUIDManager.asuser(Puppet::Util.uid($restricted_user),Puppet::Util.gid($restricted_user)) do
              catalog.add_resource(vcsrepo)

              trans = catalog.apply

              status = trans.report.resource_statuses["#{vcsrepo.type.to_s.capitalize}[#{vcsrepo.title}]"]

              status.should be_failed
            end
          end
        end

        context "with permition" do
          it 'should recursively update group ownership' do

            catalog.add_resource(vcsrepo)

            catalog.apply

            Dir[File.join(resource[:name],"/**/*")].each do |el|
              File.stat(el).gid.should eq(Puppet::Util.gid(resource[:group]))
            end
          end
        end

        end

        with_update_resource :owner => { :from => 'root', :to => 'paulche' } do

          context "without permition" do
            it 'should failed with log message' do
              Puppet::Util::SUIDManager.asuser(Puppet::Util.uid($restricted_user),Puppet::Util.gid($restricted_user)) do
                  catalog.add_resource(vcsrepo)

                  trans = catalog.apply

                  status = trans.report.resource_statuses["#{vcsrepo.type.to_s.capitalize}[#{vcsrepo.title}]"]

                  status.should be_failed
              end
            end
          end

          context "with permition" do
            it 'should recursively update group ownership' do

              catalog.add_resource(vcsrepo)

              catalog.apply

              Dir[File.join(resource[:name],"/**/*")].each do |el|
                File.stat(el).uid.should eq(Puppet::Util.uid(resource[:owner]))
              end

            end
          end
        end
    end
  end
end


