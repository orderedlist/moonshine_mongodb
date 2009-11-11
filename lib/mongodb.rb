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
    file '/data',                :ensure => :directory
    file '/data/db',             :ensure => :directory
    file '/var/log/mongodb',     :ensure => :directory
    
    exec 'install_mogodb',
      :command => [
        "wget http://downloads.mongodb.org/linux/mongodb-linux-x86_64-#{options[:version]}.tgz",
        "tar xzf mongodb-linux-x86_64-#{options[:version]}.tgz",
        "mv mongodb-linux-x86_64-#{options[:version]} /opt/mongo-#{options[:version]}"
      ].join(' && '),
      :cwd => '/tmp',
      :creates => "/opt/mongo-#{options[:version]}/bin/mongod",
      :require => package('wget')
      
    file '/etc/init.d/mongodb',
        :mode => '744',
        :content => template(File.join(File.dirname(__FILE__), '..', 'templates', 'mongo.init.erb'), binding),
        :before => service('mongodb')

    service "mongodb",
      :ensure => :running,
      :enable => true,
      :require => [
        file('/data/db'),
        file('/var/log/mongodb'),
        exec('install_mogodb')
      ]
    
  end
  
end