require File.join(File.dirname(__FILE__), 'spec_helper.rb')

class MongodbManifest < Moonshine::Manifest
  plugin :mongodb
end

describe "A manifest with the Mongodb plugin" do
  
  before do
    @manifest = MongodbManifest.new
    @manifest.mongodb
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