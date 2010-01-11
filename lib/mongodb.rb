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
      :version => '1.2.1'
    }.merge(hash)

    package 'wget',              :ensure => :installed
    file '/data',                  :ensure => :directory
    file '/data/db',             :ensure => :directory
    file '/opt/local',           :ensure => :directory
    file '/var/log/mongodb',     :ensure => :directory

    arch = Facter.architecture
    arch = 'i686' if arch == 'i386'

    exec 'install_mongodb',
      :command => [
        "wget http://downloads.mongodb.org/linux/mongodb-linux-#{arch}-#{options[:version]}.tgz",
        "tar xzf mongodb-linux-#{arch}-#{options[:version]}.tgz",
        "mv mongodb-linux-#{arch}-#{options[:version]} /opt/local/mongo-#{options[:version]}"
      ].join(' && '),
      :cwd => '/tmp',
      :creates => "/opt/local/mongo-#{options[:version]}/bin/mongod",
      :require => [
        file('/opt/local'),
        package('wget')
      ]

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
        exec('install_mongodb')
      ]
  end

end