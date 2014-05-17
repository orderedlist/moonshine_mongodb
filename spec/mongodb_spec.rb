require File.join(File.dirname(__FILE__), 'spec_helper.rb')

class MongodbManifest < Moonshine::Manifest
  include Mongodb
  configure(:mongodb => {:version => '1.5', :auth => true, :master? => true })
  recipe :mongodb
end

describe "A manifest with the Mongodb plugin" do
  
  before do
    @manifest = MongodbManifest.new
    @manifest.send(:evaluate_recipes)
  end
  
  it "should use the version specified" do
    # should not include the default
    @manifest.files['/etc/init.d/mongodb'].content.should_not =~ %r{mongo-1.4.4/bin/mongod}
    # but rather use our own custom version
    @manifest.files['/etc/init.d/mongodb'].content.should =~ %r{mongo-1.5/bin/mongod}
  end
  
  it "should require auth" do
    @manifest.files['/etc/init.d/mongodb'].content.should =~ /--auth/
  end
  
  it "should be a master" do
    @manifest.files['/etc/init.d/mongodb'].content.should =~ /--master/
  end
  
  it "should be executable" do
    @manifest.should be_executable
  end
  
  #it "should provide packages/services/files" do
  # @manifest.packages.keys.should include 'foo'
  # @manifest.files['/etc/foo.conf'].content.should match /foo=true/
  # @manifest.execs['newaliases'].refreshonly.should be_true
  #end
  
end