# frozen_string_literal: true

require 'thread'
require 'time'
require 'logger'

module Core
  # Rate limiter for Discord API
  # Handles both global and bucket-specific rate limiting according to Discord API specifications
  class Limiter
    # Discord API rate limit constants
    GLOBAL_LIMIT = 50 # Global request limit per second
    GLOBAL_WINDOW = 1 # Global window in seconds
    DEFAULT_BUCKET_LIMIT = 5 # Default bucket limit if not specified by Discord
    
    # HTTP response headers for Discord rate limiting
    LIMIT_HEADER = 'x-ratelimit-limit'
    REMAINING_HEADER = 'x-ratelimit-remaining'
    RESET_HEADER = 'x-ratelimit-reset'
    RESET_AFTER_HEADER = 'x-ratelimit-reset-after'
    BUCKET_HEADER = 'x-ratelimit-bucket'
    GLOBAL_HEADER = 'x-ratelimit-global'
    RETRY_AFTER_HEADER = 'retry-after'
    SCOPE_HEADER = 'x-ratelimit-scope'

    # Rate limit exception class
    class RateLimitError < StandardError
      attr_reader :retry_after, :global, :bucket

      def initialize(message, retry_after: nil, global: false, bucket: nil)
        super(message)
        @retry_after = retry_after
        @global = global
        @bucket = bucket
      end
    end

    def initialize(logger: nil)
      @global_mutex = Mutex.new
      @bucket_mutexes = {}
      @bucket_limits = {}
      @global_reset = Time.now
      @global_remaining = GLOBAL_LIMIT
      @logger = logger || (defined?(Rails) ? Rails.logger : Logger.new($stdout))
      @debug = ENV['DISCORD_DEBUG'] == 'true'
    end

    # Main method to execute request with rate limiting
    # @param bucket [String, nil] Bucket identifier for the endpoint (optional)
    # @param route [String, nil] Route for bucket identification (optional)
    # @param major_params [Hash] Major parameters for bucket identification
    # @param retries [Integer] Number of retries on rate limit (default: 3)
    # @param &block [Block] Block of code to execute HTTP request
    # @return [Object] Response from the block
    def execute(bucket: nil, route: nil, major_params: {}, retries: 3, &block)
      raise ArgumentError, 'Block is required' unless block_given?

      # Generate bucket if route is provided
      bucket = generate_bucket(route, major_params) if route && !bucket

      attempt = 0
      begin
        attempt += 1
        
        # Pre-request rate limit checks
        wait_for_global_limit
        wait_for_bucket_limit(bucket) if bucket

        # Execute the request
        log_debug("Executing request for bucket: #{bucket}")
        response = yield
        
        # Update limits based on response headers
        update_limits_from_response(response, bucket)
        
        # Handle rate limit responses
        if response.respond_to?(:code) && response.code == 429
          handle_429_response(response, bucket, attempt, retries)
        end
        
        log_debug("Request completed successfully for bucket: #{bucket}")
        response
        
      rescue RateLimitError => e
        if attempt <= retries
          log_warn("Rate limit hit (attempt #{attempt}/#{retries + 1}): #{e.message}")
          sleep(e.retry_after || 1)
          retry
        else
          log_error("Rate limit exceeded maximum retries for bucket: #{bucket}")
          raise
        end
      rescue => error
        log_error("Rate limiter error: #{error.message}")
        log_error(error.backtrace.join("\n")) if @debug
        raise
      end
    end

    # Execute request without retries (throws RateLimitError immediately)
    # @param bucket [String, nil] Bucket identifier
    # @param &block [Block] Block to execute
    def execute_once(bucket: nil, &block)
      execute(bucket: bucket, retries: 0, &block)
    end

    # Check if currently rate limited
    # @param bucket [String, nil] Bucket to check (nil for global only)
    # @return [Boolean] True if rate limited
    def rate_limited?(bucket: nil)
      return true if globally_rate_limited?
      return bucket_rate_limited?(bucket) if bucket
      false
    end

    # Get global rate limit status
    # @return [Hash] Global rate limit information
    def global_status
      @global_mutex.synchronize do
        {
          limit: GLOBAL_LIMIT,
          remaining: @global_remaining,
          reset_at: @global_reset,
          reset_in: [(@global_reset - Time.now).to_f, 0].max
        }
      end
    end

    # Get bucket rate limit status
    # @param bucket [String] Bucket identifier
    # @return [Hash, nil] Bucket rate limit information or nil if no data
    def bucket_status(bucket)
      return nil unless bucket
      
      bucket_mutex = @bucket_mutexes[bucket]
      return nil unless bucket_mutex
      
      bucket_mutex.synchronize do
        data = @bucket_limits[bucket]
        return nil unless data
        
        {
          bucket: bucket,
          limit: data[:limit],
          remaining: data[:remaining],
          reset_at: data[:reset_at],
          reset_in: [(data[:reset_at] - Time.now).to_f, 0].max
        }
      end
    end

    # Get all bucket statuses
    # @return [Hash] Hash of bucket_name => status
    def all_bucket_statuses
      statuses = {}
      @bucket_mutexes.keys.each do |bucket|
        status = bucket_status(bucket)
        statuses[bucket] = status if status
      end
      statuses
    end

    # Reset all rate limits (useful for testing)
    def reset!
      @global_mutex.synchronize do
        @global_remaining = GLOBAL_LIMIT
        @global_reset = Time.now + GLOBAL_WINDOW
      end
      
      @bucket_mutexes.each_value do |mutex|
        mutex.synchronize { } # Just to ensure no operations are in progress
      end
      
      @bucket_mutexes.clear
      @bucket_limits.clear
      
      log_debug("All rate limits reset")
    end

    # Get statistics about rate limiter usage
    # @return [Hash] Usage statistics
    def statistics
      bucket_count = @bucket_limits.size
      active_buckets = @bucket_limits.count { |_, data| data[:remaining] < data[:limit] }
      
      {
        global: global_status,
        bucket_count: bucket_count,
        active_buckets: active_buckets,
        buckets: all_bucket_statuses
      }
    end

    private

    # Wait for global rate limit to reset if needed
    def wait_for_global_limit
      @global_mutex.synchronize do
        now = Time.now
        
        # Reset global counter if window has passed
        if now >= @global_reset
          @global_remaining = GLOBAL_LIMIT
          @global_reset = now + GLOBAL_WINDOW
          log_debug("Global rate limit window reset")
        end
        
        # Check if we need to wait
        if @global_remaining <= 0
          wait_time = (@global_reset - now).to_f
          if wait_time > 0
            log_warn("Global rate limit exceeded, waiting #{wait_time.round(2)}s")
            raise RateLimitError.new(
              "Global rate limit exceeded", 
              retry_after: wait_time, 
              global: true
            )
          end
        end
        
        @global_remaining -= 1
        log_debug("Global requests remaining: #{@global_remaining}")
      end
    end

    # Wait for bucket-specific rate limit to reset if needed
    def wait_for_bucket_limit(bucket)
      return unless bucket

      # Get or create mutex for this bucket
      bucket_mutex = (@bucket_mutexes[bucket] ||= Mutex.new)
      
      bucket_mutex.synchronize do
        bucket_data = @bucket_limits[bucket]
        return unless bucket_data # No limit data yet
        
        now = Time.now
        
        # Reset bucket if window has passed
        if now >= bucket_data[:reset_at]
          bucket_data[:remaining] = bucket_data[:limit]
          bucket_data[:reset_at] = now + 1 # Default 1 second window
          log_debug("Bucket #{bucket} rate limit window reset")
        end
        
        # Check if we need to wait
        if bucket_data[:remaining] <= 0
          wait_time = (bucket_data[:reset_at] - now).to_f
          if wait_time > 0
            log_warn("Bucket #{bucket} rate limit exceeded, waiting #{wait_time.round(2)}s")
            raise RateLimitError.new(
              "Bucket rate limit exceeded: #{bucket}", 
              retry_after: wait_time, 
              bucket: bucket
            )
          end
        end
        
        bucket_data[:remaining] -= 1
        log_debug("Bucket #{bucket} requests remaining: #{bucket_data[:remaining]}")
      end
    end

    # Update rate limit data from Discord API response headers
    def update_limits_from_response(response, bucket)
      return unless response.respond_to?(:headers) || response.respond_to?(:[])
      
      headers = response.respond_to?(:headers) ? response.headers : response
      headers = normalize_headers(headers)
      
      # Handle global rate limit
      if headers[GLOBAL_HEADER] == 'true'
        handle_global_rate_limit_headers(headers)
        return # Global rate limits don't update bucket info
      end
      
      # Handle bucket-specific rate limit
      actual_bucket = headers[BUCKET_HEADER] || bucket
      if actual_bucket
        handle_bucket_rate_limit_headers(headers, actual_bucket)
      end
      
      log_debug("Updated rate limits from response headers")
    end

    # Handle 429 Too Many Requests response
    def handle_429_response(response, bucket, attempt, max_retries)
      headers = response.respond_to?(:headers) ? response.headers : response
      headers = normalize_headers(headers)
      
      retry_after = (headers[RETRY_AFTER_HEADER] || 1).to_f
      is_global = headers[GLOBAL_HEADER] == 'true'
      
      if is_global
        handle_global_rate_limit_exceeded(retry_after)
        raise RateLimitError.new(
          "Global rate limit exceeded (429)", 
          retry_after: retry_after, 
          global: true
        )
      elsif bucket
        handle_bucket_rate_limit_exceeded(bucket, retry_after)
        raise RateLimitError.new(
          "Bucket rate limit exceeded (429): #{bucket}", 
          retry_after: retry_after, 
          bucket: bucket
        )
      else
        log_error("Received 429 without bucket or global flag")
        raise RateLimitError.new(
          "Unknown rate limit exceeded (429)", 
          retry_after: retry_after
        )
      end
    end

    # Handle global rate limit from headers
    def handle_global_rate_limit_headers(headers)
      retry_after = (headers[RESET_AFTER_HEADER] || headers[RETRY_AFTER_HEADER])&.to_f
      
      if retry_after && retry_after > 0
        @global_mutex.synchronize do
          @global_remaining = 0
          @global_reset = Time.now + retry_after
          log_warn("Global rate limit updated from headers, reset in #{retry_after}s")
        end
      end
    end

    # Handle bucket-specific rate limit from headers
    def handle_bucket_rate_limit_headers(headers, bucket)
      limit = headers[LIMIT_HEADER]&.to_i
      remaining = headers[REMAINING_HEADER]&.to_i
      reset = headers[RESET_HEADER]&.to_f
      reset_after = headers[RESET_AFTER_HEADER]&.to_f

      # Need at least limit and remaining
      return unless limit && !remaining.nil? && remaining >= 0

      bucket_mutex = (@bucket_mutexes[bucket] ||= Mutex.new)
      
      bucket_mutex.synchronize do
        reset_time = if reset && reset > 0
          Time.at(reset)
        elsif reset_after && reset_after > 0
          Time.now + reset_after
        else
          Time.now + 1 # Default 1 second
        end

        @bucket_limits[bucket] = {
          limit: limit,
          remaining: remaining,
          reset_at: reset_time
        }
        
        log_debug("Updated bucket #{bucket}: #{remaining}/#{limit}, reset at #{reset_time}")
      end
    end

    # Handle global rate limit exceeded
    def handle_global_rate_limit_exceeded(retry_after)
      @global_mutex.synchronize do
        @global_remaining = 0
        @global_reset = Time.now + retry_after
        log_error("Global rate limit exceeded, reset in #{retry_after}s")
      end
    end

    # Handle bucket rate limit exceeded
    def handle_bucket_rate_limit_exceeded(bucket, retry_after)
      bucket_mutex = (@bucket_mutexes[bucket] ||= Mutex.new)
      bucket_mutex.synchronize do
        bucket_data = @bucket_limits[bucket] ||= { 
          limit: DEFAULT_BUCKET_LIMIT, 
          remaining: 0, 
          reset_at: Time.now 
        }
        bucket_data[:remaining] = 0
        bucket_data[:reset_at] = Time.now + retry_after
        log_error("Bucket #{bucket} rate limit exceeded, reset in #{retry_after}s")
      end
    end

    # Generate bucket identifier from route and major parameters
    def generate_bucket(route, major_params)
      return route if major_params.empty?
      
      # Sort parameters for consistent bucket generation
      params_str = major_params.sort.map { |k, v| "#{k}:#{v}" }.join('|')
      "#{route}|#{params_str}"
    end

    # Normalize headers to handle different header implementations
    def normalize_headers(headers)
      case headers
      when Hash
        # Convert string keys to lowercase for case-insensitive access
        headers.transform_keys(&:to_s).transform_keys(&:downcase)
      else
        # Assume it responds to [] method
        headers
      end
    end

    # Check if globally rate limited
    def globally_rate_limited?
      @global_mutex.synchronize do
        @global_remaining <= 0 && Time.now < @global_reset
      end
    end

    # Check if bucket is rate limited
    def bucket_rate_limited?(bucket)
      return false unless bucket
      
      bucket_mutex = @bucket_mutexes[bucket]
      return false unless bucket_mutex
      
      bucket_mutex.synchronize do
        bucket_data = @bucket_limits[bucket]
        return false unless bucket_data
        
        bucket_data[:remaining] <= 0 && Time.now < bucket_data[:reset_at]
      end
    end

    # Logging methods
    def log_debug(message)
      @logger.debug("[Discord Rate Limiter] #{message}") if @debug
    end

    def log_warn(message)
      @logger.warn("[Discord Rate Limiter] #{message}")
    end

    def log_error(message)
      @logger.error("[Discord Rate Limiter] #{message}")
    end
  end
end
