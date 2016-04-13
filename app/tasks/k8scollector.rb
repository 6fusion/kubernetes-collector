require './config/defaults.rb'

# Initialize the application logger
K8scollector::init_logger

# Initialize MongoDB connection
K8scollector::init_mongodb

# Load configuration values
K8scollector::load_configuration

# Initialize Kubernetes collector
$logger.info 'Initializing Kubernetes collector...'

puts $config.inspect