# frozen_string_literal: true

require 'rake'
require 'rake/testtask'
require 'bundler/gem_tasks' if defined?(Bundler)
require 'yard'

# Load framework files
Dir.glob('lib/**/*.rb').each { |f| require_relative f }

# Default task
task default: [:test, :rubocop]

# Test tasks
desc 'Run all tests'
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

desc 'Run unit tests'
Rake::TestTask.new('test:unit') do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/unit/**/*_test.rb']
  t.verbose = true
end

desc 'Run integration tests'
Rake::TestTask.new('test:integration') do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/integration/**/*_test.rb']
  t.verbose = true
end

desc 'Run performance tests'
Rake::TestTask.new('test:performance') do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/performance/**/*_test.rb']
  t.verbose = true
end

# Code quality tasks
desc 'Run RuboCop'
task :rubocop do
  sh 'rubocop'
end

desc 'Auto-correct RuboCop offenses'
task 'rubocop:auto_correct' do
  sh 'rubocop -A'
end

desc 'Run Reek code smell detector'
task :reek do
  sh 'reek lib/'
end

# Documentation tasks
desc 'Generate documentation'
YARD::Rake::YardocTask.new(:docs) do |t|
  t.files = ['lib/**/*.rb']
  t.options = ['--markup', 'markdown']
end

desc 'Serve documentation locally'
task 'docs:serve' do
  sh 'yard server --reload'
end

desc 'Clean documentation'
task 'docs:clean' do
  sh 'rm -rf doc/'
end

# Discord bot tasks
namespace :bot do
  desc 'Start Discord bot'
  task :start do
    require_relative 'lib/bot'
    puts 'Starting Discord bot...'
    Bot.start
  end

  desc 'Stop Discord bot'
  task :stop do
    puts 'Stopping Discord bot...'
    # Implementation depends on your bot structure
    # Could use PID file or signal handling
  end

  desc 'Restart Discord bot'
  task restart: [:stop, :start]

  desc 'Check bot status'
  task :status do
    # Check if bot is running
    if File.exist?('tmp/bot.pid')
      pid = File.read('tmp/bot.pid').strip.to_i
      begin
        Process.kill(0, pid)
        puts "Bot is running (PID: #{pid})"
      rescue Errno::ESRCH
        puts 'Bot is not running (stale PID file)'
        File.delete('tmp/bot.pid')
      end
    else
      puts 'Bot is not running'
    end
  end

  desc 'Deploy bot'
  task :deploy do
    puts 'Deploying Discord bot...'
    
    # Run tests first
    Rake::Task['test'].invoke
    
    # Build and push
    sh 'git push origin main'
    
    # Restart bot service
    Rake::Task['bot:restart'].invoke
    
    puts 'Bot deployed successfully!'
  end

  desc 'Validate bot configuration'
  task :validate do
    require_relative 'lib/config'
    
    puts 'Validating bot configuration...'
    
    # Check required environment variables
    required_vars = %w[DISCORD_TOKEN BOT_PREFIX]
    missing_vars = required_vars.reject { |var| ENV[var] }
    
    if missing_vars.any?
      puts "Missing required environment variables: #{missing_vars.join(', ')}"
      exit 1
    end
    
    # Validate Discord token format
    token = ENV['DISCORD_TOKEN']
    unless token&.match?(/^[A-Za-z0-9._-]{70,}$/)
      puts 'Invalid Discord token format'
      exit 1
    end
    
    puts 'Configuration is valid!'
  end
end

# Database tasks (if using database)
namespace :db do
  desc 'Create database'
  task :create do
    require_relative 'lib/database'
    Database.create
    puts 'Database created'
  end

  desc 'Drop database'
  task :drop do
    require_relative 'lib/database'
    Database.drop
    puts 'Database dropped'
  end

  desc 'Migrate database'
  task :migrate do
    require_relative 'lib/database'
    Database.migrate
    puts 'Database migrated'
  end

  desc 'Rollback database'
  task :rollback do
    require_relative 'lib/database'
    Database.rollback
    puts 'Database rolled back'
  end

  desc 'Seed database'
  task :seed do
    require_relative 'lib/database'
    Database.seed
    puts 'Database seeded'
  end

  desc 'Reset database'
  task reset: [:drop, :create, :migrate, :seed]

  desc 'Database status'
  task :status do
    require_relative 'lib/database'
    puts Database.status
  end
end

# Cache tasks
namespace :cache do
  desc 'Clear all caches'
  task :clear do
    require_relative 'lib/cache'
    Cache.clear_all
    puts 'All caches cleared'
  end

  desc 'Cache statistics'
  task :stats do
    require_relative 'lib/cache'
    stats = Cache.statistics
    puts "Cache statistics:"
    stats.each { |k, v| puts "  #{k}: #{v}" }
  end
end

# Rate limiter tasks
namespace :limiter do
  desc 'Rate limiter status'
  task :status do
    require_relative 'lib/core/limiter'
    limiter = Core::Limiter.new
    stats = limiter.statistics
    
    puts "Rate Limiter Status:"
    puts "  Global: #{stats[:global][:remaining]}/#{stats[:global][:limit]} remaining"
    puts "  Bucket count: #{stats[:bucket_count]}"
    puts "  Active buckets: #{stats[:active_buckets]}"
    
    if stats[:buckets].any?
      puts "  Buckets:"
      stats[:buckets].each do |bucket, data|
        puts "    #{bucket}: #{data[:remaining]}/#{data[:limit]} remaining"
      end
    end
  end

  desc 'Reset rate limiter'
  task :reset do
    require_relative 'lib/core/limiter'
    limiter = Core::Limiter.new
    limiter.reset!
    puts 'Rate limiter reset'
  end
end

# Development tasks
namespace :dev do
  desc 'Setup development environment'
  task :setup do
    puts 'Setting up development environment...'
    
    # Create necessary directories
    %w[tmp log test/fixtures].each do |dir|
      Dir.mkdir(dir) unless Dir.exist?(dir)
    end
    
    # Copy example configuration
    if File.exist?('.env.example') && !File.exist?('.env')
      sh 'cp .env.example .env'
      puts 'Created .env from example'
    end
    
    # Install dependencies
    sh 'bundle install'
    
    # Setup database if configured
    if defined?(Database)
      Rake::Task['db:create'].invoke rescue nil
      Rake::Task['db:migrate'].invoke rescue nil
    end
    
    puts 'Development environment ready!'
  end

  desc 'Start development console'
  task :console do
    require 'irb'
    require_relative 'lib/framework'
    
    puts 'Loading Discord framework console...'
    ARGV.clear
    IRB.start
  end

  desc 'Generate new command'
  task :generate_command, [:name] do |_, args|
    name = args[:name] || 'example'
    
    template = <<~RUBY
      # frozen_string_literal: true

      module Commands
        class #{name.capitalize}Command < BaseCommand
          def execute
            # Implementation here
            respond_with("Hello from #{name} command!")
          end

          private

          def command_name
            '#{name}'
          end

          def description
            'Description for #{name} command'
          end
        end
      end
    RUBY

    filename = "lib/commands/#{name}_command.rb"
    File.write(filename, template)
    puts "Generated command: #{filename}"
  end

  desc 'Generate new event handler'
  task :generate_event, [:name] do |_, args|
    name = args[:name] || 'example'
    
    template = <<~RUBY
      # frozen_string_literal: true

      module Events
        class #{name.capitalize}Handler < BaseHandler
          def handle(event)
            # Implementation here
            logger.info("Handling #{name} event")
          end

          private

          def event_type
            :#{name}
          end
        end
      end
    RUBY

    filename = "lib/events/#{name}_handler.rb"
    File.write(filename, template)
    puts "Generated event handler: #{filename}"
  end
end

# Maintenance tasks
namespace :maintenance do
  desc 'Clean temporary files'
  task :clean do
    puts 'Cleaning temporary files...'
    
    # Remove log files older than 7 days
    Dir.glob('log/*.log').each do |file|
      if File.mtime(file) < Time.now - (7 * 24 * 60 * 60)
        File.delete(file)
        puts "Deleted old log file: #{file}"
      end
    end
    
    # Clean tmp directory
    Dir.glob('tmp/*').each do |file|
      unless File.basename(file) == '.keep'
        File.delete(file)
        puts "Deleted temp file: #{file}"
      end
    end
    
    puts 'Cleanup complete!'
  end

  desc 'Health check'
  task :health do
    puts 'Running health checks...'
    
    # Check disk space
    disk_usage = `df -h | grep -E '^/dev/'`.lines.first
    puts "Disk usage: #{disk_usage&.strip}"
    
    # Check memory usage
    memory_info = `free -h | grep Mem:`.strip
    puts "Memory: #{memory_info}"
    
    # Check bot process
    Rake::Task['bot:status'].invoke
    
    # Check rate limiter
    Rake::Task['limiter:status'].invoke
    
    puts 'Health check complete!'
  end

  desc 'Backup data'
  task :backup do
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    backup_dir = "backups/#{timestamp}"
    
    Dir.mkdir('backups') unless Dir.exist?('backups')
    Dir.mkdir(backup_dir)
    
    # Backup database if exists
    if defined?(Database)
      puts 'Backing up database...'
      sh "pg_dump #{ENV['DATABASE_URL']} > #{backup_dir}/database.sql" rescue nil
    end
    
    # Backup configuration
    %w[.env config/].each do |path|
      if File.exist?(path)
        sh "cp -r #{path} #{backup_dir}/" rescue nil
      end
    end
    
    # Backup logs
    sh "cp -r log/ #{backup_dir}/" if Dir.exist?('log')
    
    puts "Backup created: #{backup_dir}"
  end
end

# Deployment tasks
namespace :deploy do
  desc 'Deploy to production'
  task :production do
    puts 'Deploying to production...'
    
    # Validate configuration
    Rake::Task['bot:validate'].invoke
    
    # Run tests
    Rake::Task['test'].invoke
    
    # Build and deploy
    sh 'git push production main'
    
    puts 'Production deployment complete!'
  end

  desc 'Deploy to staging'
  task :staging do
    puts 'Deploying to staging...'
    
    # Run tests
    Rake::Task['test'].invoke
    
    # Build and deploy
    sh 'git push staging main'
    
    puts 'Staging deployment complete!'
  end

  desc 'Rollback deployment'
  task :rollback do
    puts 'Rolling back deployment...'
    
    # Implementation depends on your deployment strategy
    sh 'git revert HEAD --no-edit'
    sh 'git push production main'
    
    puts 'Rollback complete!'
  end
end

# Monitoring tasks
namespace :monitor do
  desc 'Show logs'
  task :logs do
    sh 'tail -f log/bot.log'
  end

  desc 'Show error logs'
  task :errors do
    sh 'grep ERROR log/*.log'
  end

  desc 'Show rate limit logs'
  task :rate_limits do
    sh 'grep "rate limit" log/*.log'
  end

  desc 'System metrics'
  task :metrics do
    puts 'System Metrics:'
    puts `uptime`
    puts `df -h`
    puts `free -h`
  end
end

# Security tasks
namespace :security do
  desc 'Audit gems for vulnerabilities'
  task :audit do
    sh 'bundle audit'
  end

  desc 'Update vulnerable gems'
  task :update do
    sh 'bundle audit --update'
  end

  desc 'Check for secrets in code'
  task :secrets do
    puts 'Scanning for potential secrets...'
    
    # Simple regex patterns for common secrets
    patterns = [
      /password\s*=\s*['"][^'"]+['"]/i,
      /token\s*=\s*['"][^'"]+['"]/i,
      /key\s*=\s*['"][^'"]+['"]/i,
      /secret\s*=\s*['"][^'"]+['"]/i
    ]
    
    Dir.glob('lib/**/*.rb').each do |file|
      content = File.read(file)
      patterns.each do |pattern|
        matches = content.scan(pattern)
        if matches.any?
          puts "Potential secret found in #{file}: #{matches.join(', ')}"
        end
      end
    end
    
    puts 'Secret scan complete!'
  end
end
