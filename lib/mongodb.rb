require 'pathname'

module Mongodb
  def self.included(manifest)
    manifest.class_eval do
      extend ClassMethods
    end
  end

  module ClassMethods
    def mongo_yml
      @mongo_yml ||= Pathname.new(configuration[:deploy_to]) + 'shared/config/mongo.yml'
    end

    def mongo_rb
      @mongo_rb ||= Pathname.new(configuration[:deploy_to]) + 'current/config/initializers/mongo.rb'
    end

    def mongo_configuration
      configuration[:mongodb][rails_env.to_sym]
    end

    def mongo_template_dir
      @mongo_template_dir ||= Pathname.new(__FILE__).dirname.dirname.join('templates')
    end
  end

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
    configure :mongodb => YAML::load(template(mongo_template_dir + 'mongo.yml', binding))

    if ubuntu_intrepid?
      # 10gen does not have repo support for < 9.04

      options = {
        :version => '1.4.4',
        :master? => false,
        :auth    => false,
        :slave?  => false,
        :slave   => {
          :auto_resync => false,
          :master_host => ''
        }
      }.merge(hash)

      file '/data',                :ensure => :directory
      file '/data/db',             :ensure => :directory
      file '/var/log/mongodb',     :ensure => :directory
      file '/opt/local',           :ensure => :directory
      package 'wget',              :ensure => :installed

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
        :before => service('mongodb'),
        :checksum => :md5

      service "mongodb",
        :ensure => :running,
        :enable => true,
        :require => [
          file('/data/db'),
          file('/var/log/mongodb'),
          exec('install_mongodb')
        ]
    elsif ubuntu_lucid?
      options = {
        :release => 'stable',
        :dbpath => '/var/lib/mongodb',
        :logpath => '/var/log/mongodb',
        :port => '27017',
        :cpu_logging => false,
        :verbose => false,
        :loglevel => '0',
        :journal => true
      }.merge(hash)

      file '/etc/apt/sources.list.d/mongodb.list',
        :ensure => :present,
        :mode => '644',
        :content => template(File.join(File.dirname(__FILE__), '..', 'templates', 'mongodb.list.erb'), binding)

      exec '10gen apt-key',
        :command => 'apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10',
        :unless => 'apt-key list | grep 7F0CEB10'

      exec 'apt-get update',
        :command => 'apt-get update',
        :require => [
          file('/etc/apt/sources.list.d/mongodb.list'),
          exec('10gen apt-key')
        ]

      if configuration[:mongodb][:release] == 'stable'
        package "mongodb-10gen",
          :alias => 'mongodb',
          :ensure => :latest,
          :require => [ exec('apt-get update') ]
      else
        package "mongodb-10gen-unstable",
          :alias => 'mongodb',
          :ensure => :latest,
          :require => [ exec('apt-get update') ]
      end

      file '/etc/mongodb.conf',
        :ensure => :present,
        :mode => '644',
        :content => template(File.join(File.dirname(__FILE__), '..', 'templates', 'mongodb.conf.erb'), binding),
        :before => service('mongodb')

      file '/etc/init/mongodb.conf',
        :ensure => :present,
        :mode => '644',
        :content => template(File.join(File.dirname(__FILE__), '..', 'templates', 'mongodb.upstart.erb'), binding),
        :before => service('mongodb')

      file '/etc/init.d/mongodb',
        :ensure => :absent,
        :before => service('mongodb')

      service 'mongodb',
        :ensure => :running,
        :enable => true,
        :require => [
          package('mongodb'),
          file('/etc/mongodb.conf'),
          file('/etc/init/mongodb.conf'),
        ]
    end
  end

  private
  def ubuntu_lucid?
    Facter.lsbdistid == 'Ubuntu' && Facter.lsbdistrelease.to_f == 10.04
  end

  def ubuntu_intrepid?
    Facter.lsbdistid == 'Ubuntu' && Facter.lsbdistrelease.to_f == 8.10
  end
end
