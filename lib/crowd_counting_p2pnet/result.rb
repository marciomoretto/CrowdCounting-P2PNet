# frozen_string_literal: true

module CrowdCountingP2PNet
  class Result
    attr_reader :count, :annotated_image_path, :points, :raw_payload

    def initialize(count:, annotated_image_path:, points:, raw_payload:)
      @count = count
      @annotated_image_path = annotated_image_path
      @points = points.freeze
      @raw_payload = raw_payload.freeze
    end
  end
end
