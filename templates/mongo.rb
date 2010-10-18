require 'mongo_mapper'

MongoMapper.setup(YAML.load_file(Rails.root.join('config', 'mongo.yml')), Rails.env, {
  :logger    => Rails.logger,
  :passenger => true,
})
