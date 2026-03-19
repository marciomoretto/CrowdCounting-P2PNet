# frozen_string_literal: true

if defined?(Rails::Railtie)
  module CrowdCountingP2PNet
    class Railtie < Rails::Railtie
      config.crowd_counting_p2pnet = ActiveSupport::OrderedOptions.new

      initializer 'crowd_counting_p2pnet.configure' do |app|
        CrowdCountingP2PNet.configure do |config|
          config.weight_path = app.config.crowd_counting_p2pnet.weight_path if app.config.crowd_counting_p2pnet.weight_path
          config.python_bin = app.config.crowd_counting_p2pnet.python_bin if app.config.crowd_counting_p2pnet.python_bin
        end
      end
    end
  end
end
