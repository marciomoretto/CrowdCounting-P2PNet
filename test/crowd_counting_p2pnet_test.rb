# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require_relative 'test_helper'

class CrowdCountingP2PNetTest < Minitest::Test
  FakeStatus = Struct.new(:success?)

  class FakeExecutor
    attr_reader :command

    def initialize(stdout:, stderr: '', success: true)
      @stdout = stdout
      @stderr = stderr
      @status = FakeStatus.new(success)
    end

    def capture3(*command)
      @command = command
      [@stdout, @stderr, @status]
    end
  end

  def setup
    @tmp_dir = Dir.mktmpdir
    @image_path = File.join(@tmp_dir, 'input.jpg')
    @output_path = File.join(@tmp_dir, 'output.jpg')
    @weight_path = File.join(@tmp_dir, 'weights.pth')
    @script_path = File.join(@tmp_dir, 'p2pnet_infer.py')

    File.write(@image_path, 'fake image')
    File.write(@weight_path, 'fake weights')
    File.write(@script_path, 'print("ok")')
  end

  def teardown
    FileUtils.remove_entry(@tmp_dir)
  end

  def test_annotate_returns_count_and_output_path
    executor = FakeExecutor.new(
      stdout: {
        count: 12,
        annotated_image_path: @output_path,
        points: [[10.1, 20.4], [12.2, 21.0]]
      }.to_json
    )

    detector = CrowdCountingP2PNet::Detector.new(
      weight_path: @weight_path,
      script_path: @script_path,
      python_bin: 'python-custom',
      executor: executor
    )

    result = detector.call(image_path: @image_path, output_path: @output_path, threshold: 0.65, device: 'cpu')

    assert_equal 12, result.count
    assert_equal @output_path, result.annotated_image_path
    assert_equal [[10.1, 20.4], [12.2, 21.0]], result.points
    assert_equal(
      ['python-custom', @script_path, '--image-path', @image_path, '--output-path', @output_path,
       '--weight-path', @weight_path, '--threshold', '0.65', '--device', 'cpu'],
      executor.command
    )
  end

  def test_annotate_raises_when_python_fails
    executor = FakeExecutor.new(stdout: '', stderr: 'boom', success: false)
    detector = CrowdCountingP2PNet::Detector.new(
      weight_path: @weight_path,
      script_path: @script_path,
      executor: executor
    )

    error = assert_raises(CrowdCountingP2PNet::InferenceError) do
      detector.call(image_path: @image_path, output_path: @output_path)
    end

    assert_includes error.message, 'boom'
  end
end
