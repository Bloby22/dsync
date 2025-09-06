# frozen_string_literal: true

require_relative 'lib/version'

Gem::Specification.new do |spec|
  # Basic gem information
  spec.name          = 'discord-framework'
  spec.version       = DiscordFramework::VERSION
  spec.summary       = 'A comprehensive Ruby framework for Discord bots'
  spec.description   = <<~DESC
    A powerful, feature-rich Ruby framework for building Discord bots with built-in 
    rate limiting, command handling, event management, caching, and more. Designed 
    for both simple bots and complex applications.
  DESC
  spec.homepage      = 'https://github.com/yourusername/discord-framework'
  spec.license       = 'MIT'

  # Author information
  spec.authors       = ['Your Name']
  spec.email         = ['your.email@example.com']

  # Platform and Ruby requirements
  spec.platform      = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 3.0.0'

  # Gem metadata
  spec.metadata = {
    'bug_tracker_uri'   => 'https://github.com/yourusername/discord-framework/issues',
    'changelog_uri'     => 'https://github.com/yourusername/discord-framework/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://yourusername.github.io/discord-framework',
    'homepage_uri'      => spec.homepage,
    'source_code_uri'   => 'https://github.com/yourusername/discord-framework',
    'wiki_uri'          => 'https://github.com/yourusername/discord-framework/wiki',
    
    # Security and quality indicators
    'rubygems_mfa_required' => 'true',
    'github_repo' => 'ssh://github.com/yourusername/discord-framework',
    
    # Additional metadata for better discoverability
    'funding_uri' => 'https://github.com/sponsors/yourusername'
  }

  # Files to include in the gem
  spec.files = Dir.glob([
    'lib/**/*',
    'exe/*',
    'config/**/*',
    'templates/**/*',
    'README.md',
    'CHANGELOG.md',
    'LICENSE',
    'CODE_OF_CONDUCT.md',
    'CONTRIBUTING.md'
  ]).select { |f| File.file?(f) }

  # Executable files
  spec.bindir        = 'exe'
  spec.executables   = Dir.glob('exe/*').map { |f| File.basename(f) }
  
  # Require paths
  spec.require_paths = ['lib']

  # Documentation files
  spec.extra_rdoc_files = [
    'README.md',
    'CHANGELOG.md',
    'LICENSE'
  ]
  spec.rdoc_options = [
    '--charset=UTF-8',
    '--main=README.md',
    '--exclude=lib/templates/'
  ]

  # Runtime dependencies
  spec.add_runtime_dependency 'discordrb', '~> 3.4'
  spec.add_runtime_dependency 'rest-client', '~> 2.1'
  spec.add_runtime_dependency 'json', '~> 2.6'
  spec.add_runtime_dependency 'concurrent-ruby', '~> 1.2'
  spec.add_runtime_dependency 'redis', '~> 5.0'
  spec.add_runtime_dependency 'connection_pool', '~> 2.3'
  spec.add_runtime_dependency 'activesupport', '~> 7.0'
  spec.add_runtime_dependency 'dry-configurable', '~> 1.0'
  spec.add_runtime_dependency 'dry-validation', '~> 1.10'
  spec.add_runtime_dependency 'zeitwerk', '~> 2.6'
  spec.add_runtime_dependency 'logger', '~> 1.5'

  # Development dependencies
  spec.add_development_dependency 'bundler', '~> 2.4'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'minitest', '~> 5.18'
  spec.add_development_dependency 'minitest-reporters', '~> 1.6'
  spec.add_development_dependency 'minitest-hooks', '~> 1.5'
  spec.add_development_dependency 'mocha', '~> 2.0'
  spec.add_development_dependency 'vcr', '~> 6.1'
  spec.add_development_dependency 'webmock', '~> 3.18'
  
  # Code quality and documentation
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-minitest', '~> 0.31'
  spec.add_development_dependency 'rubocop-performance', '~> 1.18'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6'
  spec.add_development_dependency 'reek', '~> 6.1'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'redcarpet', '~> 3.6' # For YARD markdown
  
  # Performance and benchmarking
  spec.add_development_dependency 'benchmark-ips', '~> 2.12'
  spec.add_development_dependency 'memory_profiler', '~> 1.0'
  spec.add_development_dependency 'stackprof', '~> 0.2'
  
  # Security scanning
  spec.add_development_dependency 'bundler-audit', '~> 0.9'
  spec.add_development_dependency 'brakeman', '~> 6.0'

  # Optional database dependencies (for advanced features)
  spec.add_development_dependency 'sqlite3', '~> 1.6'
  spec.add_development_dependency 'pg', '~> 1.5'
  spec.add_development_dependency 'sequel', '~> 5.70'

  # Post-install message
  spec.post_install_message = <<~MSG
    
    🎉 Discord Framework installed successfully!
    
    To get started:
      1. Run: discord-framework new my_bot
      2. cd my_bot
      3. Configure your bot token in .env
      4. Run: rake bot:start
    
    Documentation: #{spec.metadata['documentation_uri']}
    Issues: #{spec.metadata['bug_tracker_uri']}
    
    Happy coding! 🤖
    
  MSG

  # Gem requirements and constraints
  spec.requirements = [
    'Redis server (for caching and rate limiting)',
    'Ruby 3.0+ for modern language features',
    'Discord bot token from Discord Developer Portal'
  ]

  # Security considerations
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
    spec.metadata['mfa_required'] = 'true'
  end

  # Validate gem before build
  spec.validate = proc do
    required_files = %w[lib/version.rb README.md LICENSE]
    missing_files = required_files.reject { |f| File.exist?(f) }
    
    unless missing_files.empty?
      raise "Missing required files: #{missing_files.join(', ')}"
    end
    
    # Validate version format
    unless DiscordFramework::VERSION.match?(/\A\d+\.\d+\.\d+(\.\w+)?\z/)
      raise "Invalid version format: #{DiscordFramework::VERSION}"
    end
  end
end
