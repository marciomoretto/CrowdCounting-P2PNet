# frozen_string_literal: true

require_relative 'crowd_counting_p2pnet/version'
require_relative 'crowd_counting_p2pnet/errors'
require_relative 'crowd_counting_p2pnet/result'
require_relative 'crowd_counting_p2pnet/detector'
require_relative 'crowd_counting_p2pnet/railtie'

module CrowdCountingP2PNet
  class Configuration
    attr_accessor :weight_path, :python_bin, :script_path

    def initialize
      root = File.expand_path('..', __dir__)
      @weight_path = File.join(root, 'weights', 'SHTechA.pth')
      @python_bin = ENV.fetch('P2PNET_PYTHON_BIN', 'python3')
      @script_path = File.join(root, 'p2pnet_infer.py')
    end
  end

  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def weight_path
      configuration.weight_path
    end

    def python_bin
      configuration.python_bin
    end

    def script_path
      configuration.script_path
    end

    def detector(**kwargs)
      Detector.new(**kwargs)
    end

    def annotate(image_path:, output_path: nil, threshold: Detector::DEFAULT_THRESHOLD, device: 'auto')
      detector.call(
        image_path: image_path,
        output_path: output_path,
        threshold: threshold,
        device: device
      )
    end
  end
end
