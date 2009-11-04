module Mongodb

  # Define options for this plugin via the <tt>configure</tt> method
  # in your application manifest:
  #
  #   configure(:mongodb => {:foo => true})
  #
  # Then include the plugin and call the recipe(s) you need:
  #
  #  plugin :mongodb
  #  recipe :mongodb
  def mongodb(hash = {})
    options = {
      :version => '1.0.1'
    }.merge(hash)

    package 'wget',              :ensure => :installed
    file '/data/db',             :ensure => :directory
    file '/var/log/mongodb'      :ensure => :directory
    file '/var/run/MongoDB.pid', :ensure => :present
    
    exec 'mogodb',
      :command => [
        "wget http://downloads.mongodb.org/linux/mongodb-linux-x86_64-#{options[:version]}.tar.gz",
        "tar xzf mongodb-linux-x86_64-#{options[:version]}.tar.gz",
        "mv mongodb-linux-x86_64-#{options[:version]} /opt/mongo-#{options[:version]}"
      ].join(' && '),
      :cwd => '/tmp',
      :creates => "/opt/mongo-#{options[:version]}/bin/mongod",
      :require => package('wget')
      
    file '/etc/init.d/mongodb',
        :mode => '744',
        :content => template(File.join(File.dirname(__FILE__), '..', 'templates', 'mongo.init.erb'), binding),
        :notify => service('mongodb')
    
    exec 'mongo.rc.d', :command => '/usr/sbin/update-rc.d -f mongodb defaults'
    
    service "mongodb", :restart => '/etc/init.d/mongodb restart', :ensure => :running
    
  end
  
end