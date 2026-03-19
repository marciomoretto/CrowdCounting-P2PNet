# frozen_string_literal: true

require_relative 'lib/crowd_counting_p2pnet/version'

Gem::Specification.new do |spec|
  spec.name = 'crowd_counting_p2pnet'
  spec.version = CrowdCountingP2PNet::VERSION
  spec.authors = ['OpenAI']
  spec.email = ['support@openai.com']

  spec.summary = 'Rails-friendly wrapper for P2PNet crowd head counting and annotation.'
  spec.description = 'Provides a Ruby API that calls the bundled P2PNet inference script and returns the annotated image path plus detected head count.'
  spec.homepage = 'https://github.com/TencentYoutuResearch/CrowdCounting-P2PNet'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.files = Dir[
    'README.md',
    'LICENSE',
    'lib/**/*',
    'exe/*',
    'p2pnet_infer.py',
    'models/**/*',
    'util/**/*',
    'weights/**/*'
  ]
  spec.bindir = 'exe'
  spec.executables = ['crowd_counting_p2pnet']
  spec.require_paths = ['lib']

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage
  spec.add_development_dependency 'minitest', '>= 5.16', '< 6'
  spec.add_development_dependency 'rake', '>= 13.0', '< 14'
end
