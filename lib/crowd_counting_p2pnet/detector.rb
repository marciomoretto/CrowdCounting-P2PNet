# frozen_string_literal: true

require 'json'
require 'open3'
require 'pathname'
require 'shellwords'
require 'tmpdir'
require 'securerandom'

module CrowdCountingP2PNet
  class Detector
    DEFAULT_THRESHOLD = 0.5

    def initialize(
      weight_path: CrowdCountingP2PNet.weight_path,
      python_bin: CrowdCountingP2PNet.python_bin,
      script_path: CrowdCountingP2PNet.script_path,
      executor: Open3
    )
      @weight_path = Pathname(weight_path)
      @python_bin = python_bin
      @script_path = Pathname(script_path)
      @executor = executor
    end

    def call(image_path:, output_path: nil, threshold: DEFAULT_THRESHOLD, device: 'auto')
      image = Pathname(image_path)
      raise InvalidImageError, "Image not found: #{image}" unless image.exist?
      raise InvalidImageError, "Weights not found: #{@weight_path}" unless @weight_path.exist?
      raise InvalidImageError, "Inference script not found: #{@script_path}" unless @script_path.exist?

      output = Pathname(output_path || default_output_path(image))
      output.dirname.mkpath

      stdout, stderr, status = @executor.capture3(*command_for(image, output, threshold, device))
      raise InferenceError, failure_message(stdout, stderr) unless status.success?

      payload = JSON.parse(stdout)
      Result.new(
        count: Integer(payload.fetch('count')),
        annotated_image_path: payload.fetch('annotated_image_path'),
        points: payload.fetch('points'),
        raw_payload: payload
      )
    rescue JSON::ParserError => e
      raise InferenceError, "Could not parse inference response: #{e.message}\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    end

    def command_for(image, output, threshold, device)
      [
        @python_bin,
        @script_path.to_s,
        '--image-path', image.to_s,
        '--output-path', output.to_s,
        '--weight-path', @weight_path.to_s,
        '--threshold', threshold.to_s,
        '--device', device.to_s
      ]
    end

    private

    def default_output_path(image)
      File.join(Dir.tmpdir, 'crowd_counting_p2pnet', "#{image.basename(image.extname)}-#{SecureRandom.hex(8)}.jpg")
    end

    def failure_message(stdout, stderr)
      details = [stdout, stderr].reject(&:empty?).join("\n")
      "P2PNet inference failed#{details.empty? ? '' : ":\n#{details}"}"
    end
  end
end
