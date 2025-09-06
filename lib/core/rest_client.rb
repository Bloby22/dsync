# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'concurrent'

require_relative '../constants/api_endpoints'
require_relative '../errors/api_error'
require_relative '../errors/rate_limit_error'
require_relative 'rate_limiter'

module DiscordRuby
  module Core
    # Discord REST API client with rate limiting and error handling
    class RestClient
      include Constants

      attr_reader :client, :rate_limiter, :user_agent

      # Discord API base URL
      BASE_URL = 'https://discord.com/api/v10'

      # HTTP status codes
      HTTP_OK = 200
      HTTP_CREATED = 201
      HTTP_NO_CONTENT = 204
      HTTP_NOT_MODIFIED = 304
      HTTP_BAD_REQUEST = 400
      HTTP_UNAUTHORIZED = 401
      HTTP_FORBIDDEN = 403
      HTTP_NOT_FOUND = 404
      HTTP_METHOD_NOT_ALLOWED = 405
      HTTP_TOO_MANY_REQUESTS = 429
      HTTP_GATEWAY_UNAVAILABLE = 502

      # Retry configuration
      MAX_RETRIES = 3
      RETRY_STATUSES = [HTTP_GATEWAY_UNAVAILABLE, 503, 504].freeze

      def initialize(client)
        @client = client
        @rate_limiter = RateLimiter.new
        @user_agent = "DiscordBot (DiscordRuby, #{DiscordRuby::VERSION})"
        @logger = client.logger
        
        # HTTP client pool for concurrent requests
        @http_pool = Concurrent::Hash.new do |hash, key|
          hash[key] = create_http_client(key)
        end
      end

      # Make HTTP request with rate limiting and error handling
      def request(method, endpoint, data: nil, headers: {}, files: nil, query: nil)
        url = build_url(endpoint, query)
        route = build_route(method, endpoint)
        
        # Wait for rate limit
        @rate_limiter.wait_if_rate_limited(route)
        
        response = execute_request(method, url, data, headers, files)
        
        # Handle rate limiting
        handle_rate_limiting(response, route)
        
        # Handle other errors
        handle_response_errors(response)
        
        response
        
      rescue => e
        @logger.error "REST API request failed: #{e.message}"
        raise
      end

      # GET request
      def get(endpoint, query: nil, headers: {})
        request(:get, endpoint, query: query, headers: headers)
      end

      # POST request
      def post(endpoint, data: nil, headers: {}, files: nil)
        request(:post, endpoint, data: data, headers: headers, files: files)
      end

      # PUT request
      def put(endpoint, data: nil, headers: {}, files: nil)
        request(:put, endpoint, data: data, headers: headers, files: files)
      end

      # PATCH request
      def patch(endpoint, data: nil, headers: {}, files: nil)
        request(:patch, endpoint, data: data, headers: headers, files: files)
      end

      # DELETE request
      def delete(endpoint, headers: {})
        request(:delete, endpoint, headers: headers)
      end

      # === USER ENDPOINTS ===

      # Get current user
      def get_current_user
        response = get(ApiEndpoints::USER_ME)
        parse_response(response)
      end

      # Get user by ID
      def get_user(user_id)
        response = get(ApiEndpoints::USER(user_id))
        parse_response(response) if response.code.to_i == HTTP_OK
      end

      # Modify current user
      def modify_current_user(username: nil, avatar: nil)
        data = {}
        data[:username] = username if username
        data[:avatar] = avatar if avatar
        
        response = patch(ApiEndpoints::USER_ME, data: data)
        parse_response(response)
      end

      # === GUILD ENDPOINTS ===

      # Get guild
      def get_guild(guild_id, with_counts: false)
        query = with_counts ? { with_counts: true } : nil
        response = get(ApiEndpoints::GUILD(guild_id), query: query)
        parse_response(response) if response.code.to_i == HTTP_OK
      end

      # Get guild channels
      def get_guild_channels(guild_id)
        response = get(ApiEndpoints::GUILD_CHANNELS(guild_id))
        parse_response(response)
      end

      # Create guild channel
      def create_guild_channel(guild_id, name, type: 0, **options)
        data = { name: name, type: type }.merge(options)
        response = post(ApiEndpoints::GUILD_CHANNELS(guild_id), data: data)
        parse_response(response)
      end

      # Get guild members
      def get_guild_members(guild_id, limit: 1, after: nil)
        query = { limit: limit }
        query[:after] = after if after
        
        response = get(ApiEndpoints::GUILD_MEMBERS(guild_id), query: query)
        parse_response(response)
      end

      # Get guild member
      def get_guild_member(guild_id, user_id)
        response = get(ApiEndpoints::GUILD_MEMBER(guild_id, user_id))
        parse_response(response) if response.code.to_i == HTTP_OK
      end

      # Modify guild member
      def modify_guild_member(guild_id, user_id, **options)
        response = patch(ApiEndpoints::GUILD_MEMBER(guild_id, user_id), data: options)
        parse_response(response) if response.code.to_i == HTTP_OK
      end

      # Remove guild member
      def remove_guild_member(guild_id, user_id)
        response = delete(ApiEndpoints::GUILD_MEMBER(guild_id, user_id))
        response.code.to_i == HTTP_NO_CONTENT
      end

      # Get guild bans
      def get_guild_bans(guild_id, limit: nil, before: nil, after: nil)
        query = {}
        query[:limit] = limit if limit
        query[:before] = before if before
        query[:after] = after if after
        
        response = get(ApiEndpoints::GUILD_BANS(guild_id), query: query.empty? ? nil : query)
        parse_response(response)
      end

      # Create guild ban
      def create_guild_ban(guild_id, user_id, delete_message_days: nil, reason: nil)
        data = {}
        data[:delete_message_days] = delete_message_days if delete_message_days
        
        headers = {}
        headers['X-Audit-Log-Reason'] = reason if reason
        
        response = put(ApiEndpoints::GUILD_BAN(guild_id, user_id), data: data, headers: headers)
        response.code.to_i == HTTP_NO_CONTENT
      end

      # Remove guild ban
      def remove_guild_ban(guild_id, user_id, reason: nil)
        headers = {}
        headers['X-Audit-Log-Reason'] = reason if reason
        
        response = delete(ApiEndpoints::GUILD_BAN(guild_id, user_id), headers: headers)
        response.code.to_i == HTTP_NO_CONTENT
      end

      # === CHANNEL ENDPOINTS ===

      # Get channel
      def get_channel(channel_id)
        response = get(ApiEndpoints::CHANNEL(channel_id))
        parse_response(response) if response.code.to_i == HTTP_OK
      end

      # Modify channel
      def modify_channel(channel_id, **options)
        response = patch(ApiEndpoints::CHANNEL(channel_id), data: options)
        parse_response(response)
      end

      # Delete channel
      def delete_channel(channel_id)
        response = delete(ApiEndpoints::CHANNEL(channel_id))
        parse_response(response) if response.code.to_i == HTTP_OK
      end

      # Get channel messages
      def get_channel_messages(channel_id, around: nil, before: nil, after: nil, limit: 50)
        query = { limit: [limit, 100].min }
        query[:around] = around if around
        query[:before] = before if before
        query[:after] = after if after
        
        response = get(ApiEndpoints::CHANNEL_MESSAGES(channel_id), query: query)
        parse_response(response)
      end

      # Get channel message
      def get_channel_message(channel_id, message_id)
        response = get(ApiEndpoints::CHANNEL_MESSAGE(channel_id, message_id))
        parse_response(response) if response.code.to_i == HTTP_OK
      end

      # Create message
      def create_message(channel_id, content = nil, **options)
        data = options.dup
        data[:content] = content if content
        
        files = data.delete(:files)
        
        if files&.any?
          create_message_with_files(channel_id, data, files)
        else
          response = post(ApiEndpoints::CHANNEL_MESSAGES(channel_id), data: data)
          parse_response(response)
        end
      end

      # Edit message
      def edit_message(channel_id, message_id, content = nil, **options)
        data = options.dup
        data[:content] = content if content
        
        response = patch(ApiEndpoints::CHANNEL_MESSAGE(channel_id, message_id), data: data)
        parse_response(response)
      end

      # Delete message
      def delete_message(channel_id, message_id)
        response = delete(ApiEndpoints::CHANNEL_MESSAGE(channel_id, message_id))
        response.code.to_i == HTTP_NO_CONTENT
      end

      # Bulk delete messages
      def bulk_delete_messages(channel_id, message_ids)
        data = { messages: message_ids }
        response = post(ApiEndpoints::CHANNEL_MESSAGES_BULK_DELETE(channel_id), data: data)
        response.code.to_i == HTTP_NO_CONTENT
      end

      # Create reaction
      def create_reaction(channel_id, message_id, emoji)
        encoded_emoji = URI.encode_www_form_component(emoji)
        endpoint = ApiEndpoints::CHANNEL_MESSAGE_REACTION_ME(channel_id, message_id, encoded_emoji)
        
        response = put(endpoint)
        response.code.to_i == HTTP_NO_CONTENT
      end

      # Delete reaction
      def delete_reaction(channel_id, message_id, emoji, user_id = '@me')
        encoded_emoji = URI.encode_www_form_component(emoji)
        
        if user_id == '@me'
          endpoint = ApiEndpoints::CHANNEL_MESSAGE_REACTION_ME(channel_id, message_id, encoded_emoji)
        else
          endpoint = ApiEndpoints::CHANNEL_MESSAGE_REACTION_USER(channel_id, message_id, encoded_emoji, user_id)
        end
        
        response = delete(endpoint)
        response.code.to_i == HTTP_NO_CONTENT
      end

      # Get reactions
      def get_reactions(channel_id, message_id, emoji, after: nil, limit: 25)
        encoded_emoji = URI.encode_www_form_component(emoji)
        query = { limit: limit }
        query[:after] = after if after
        
        endpoint = ApiEndpoints::CHANNEL_MESSAGE_REACTIONS(channel_id, message_id, encoded_emoji)
        response = get(endpoint, query: query)
        parse_response(response)
      end

      # === APPLICATION COMMAND ENDPOINTS ===

      # Get global application commands
      def get_global_application_commands(application_id)
        response = get(ApiEndpoints::APPLICATION_COMMANDS(application_id))
        parse_response(response)
      end

      # Create global application command
      def create_global_application_command(application_id, command_data)
        response = post(ApiEndpoints::APPLICATION_COMMANDS(application_id), data: command_data)
        parse_response(response)
      end

      # Get guild application commands
      def get_guild_application_commands(application_id, guild_id)
        response = get(ApiEndpoints::APPLICATION_GUILD_COMMANDS(application_id, guild_id))
        parse_response(response)
      end

      # Create guild application command
      def create_guild_application_command(application_id, guild_id, command_data)
        response = post(ApiEndpoints::APPLICATION_GUILD_COMMANDS(application_id, guild_id), data: command_data)
        parse_response(response)
      end

      # Bulk overwrite global application commands
      def bulk_overwrite_global_application_commands(application_id, commands)
        response = put(ApiEndpoints::APPLICATION_COMMANDS(application_id), data: commands)
        parse_response(response)
      end

      # Bulk overwrite guild application commands
      def bulk_overwrite_guild_application_commands(application_id, guild_id, commands)
        response = put(ApiEndpoints::APPLICATION_GUILD_COMMANDS(application_id, guild_id), data: commands)
        parse_response(response)
      end

      # Create interaction response
      def create_interaction_response(interaction_id, interaction_token, response_data)
        endpoint = ApiEndpoints::INTERACTION_RESPONSE(interaction_id, interaction_token)
        response = post(endpoint, data: response_data)
        response.code.to_i == HTTP_NO_CONTENT
      end

      # Edit original interaction response
      def edit_original_interaction_response(application_id, interaction_token, message_data)
        endpoint = ApiEndpoints::WEBHOOK_MESSAGE(application_id, interaction_token, '@original')
        response = patch(endpoint, data: message_data)
        parse_response(response)
      end

      private

      # Create HTTP client for host
      def create_http_client(host)
        uri = URI(host)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.read_timeout = 30
        http.open_timeout = 10
        http
      end

      # Build full URL
      def build_url(endpoint, query = nil)
        url = "#{BASE_URL}#{endpoint}"
        url += "?#{URI.encode_www_form(query)}" if query && !query.empty?
        url
      end

      # Build route for rate limiting
      def build_route(method, endpoint)
        # Replace major parameters with placeholders for rate limiting
        route = endpoint.gsub(/\/\d+/, '/{id}')
        "#{method.upcase} #{route}"
      end

      # Execute HTTP request with retries
      def execute_request(method, url, data, headers, files, attempt = 1)
        uri = URI(url)
        http = @http_pool[uri.to_s.split(uri.path)[0]]
        
        # Build request
        request = build_http_request(method, uri, data, headers, files)
        
        # Execute request
        response = http.request(request)
        
        # Retry on server errors
        if RETRY_STATUSES.include?(response.code.to_i) && attempt < MAX_RETRIES
          sleep_time = 2 ** attempt
          @logger.warn "Request failed with #{response.code}, retrying in #{sleep_time}s (attempt #{attempt}/#{MAX_RETRIES})"
          sleep sleep_time
          return execute_request(method, url, data, headers, files, attempt + 1)
        end
        
        @logger.debug "#{method.upcase} #{url} => #{response.code}"
        response
        
      rescue => e
        if attempt < MAX_RETRIES
          sleep_time = 2 ** attempt
          @logger.warn "Request error: #{e.message}, retrying in #{sleep_time}s"
          sleep sleep_time
          return execute_request(method, url, data, headers, files, attempt + 1)
        end
        
        raise
      end

      # Build HTTP request object
      def build_http_request(method, uri, data, headers, files)
        # Create request class
        request_class = case method.to_s.upcase
                       when 'GET' then Net::HTTP::Get
                       when 'POST' then Net::HTTP::Post
                       when 'PUT' then Net::HTTP::Put
                       when 'PATCH' then Net::HTTP::Patch
                       when 'DELETE' then Net::HTTP::Delete
                       else raise ArgumentError, "Unsupported method: #{method}"
                       end
        
        request = request_class.new(uri)
        
        # Set headers
        request['Authorization'] = @client.token
        request['User-Agent'] = @user_agent
        headers.each { |key, value| request[key] = value }
        
        # Set body
        if files&.any?
          set_multipart_body(request, data, files)
        elsif data
          request.body = JSON.generate(data)
          request['Content-Type'] = 'application/json'
        end
        
        request
      end

      # Set multipart body for file uploads
      def set_multipart_body(request, data, files)
        require 'net/http/post/multipart'
        
        params = {}
        
        # Add JSON payload
        if data && !data.empty?
          params[:payload_json] = JSON.generate(data)
        end
        
        # Add files
        files.each_with_index do |file, index|
          if file.is_a?(Hash)
            params["files[#{index}]"] = UploadIO.new(
              file[:io] || File.open(file[:path], 'rb'),
              file[:content_type] || 'application/octet-stream',
              file[:filename] || File.basename(file[:path])
            )
          else
            params["files[#{index}]"] = file
          end
        end
        
        request.set_form(params, 'multipart/form-data')
      end

      # Handle rate limiting
      def handle_rate_limiting(response, route)
        if response.code.to_i == HTTP_TOO_MANY_REQUESTS
          rate_limit_data = parse_response(response)
          
          retry_after = rate_limit_data['retry_after']
          global = rate_limit_data['global']
          
          @rate_limiter.handle_rate_limit(route, retry_after, global)
          
          raise RateLimitError.new(
            "Rate limited for #{retry_after}s",
            retry_after: retry_after,
            global: global,
            route: route
          )
        end
        
        # Update rate limit bucket info
        if response['X-RateLimit-Bucket']
          @rate_limiter.update_bucket_info(
            route,
            response['X-RateLimit-Bucket'],
            response['X-RateLimit-Limit']&.to_i,
            response['X-RateLimit-Remaining']&.to_i,
            response['X-RateLimit-Reset']&.to_f
          )
        end
      end

      # Handle response errors
      def handle_response_errors(response)
        case response.code.to_i
        when HTTP_OK, HTTP_CREATED, HTTP_NO_CONTENT, HTTP_NOT_MODIFIED
          # Success codes
        when HTTP_BAD_REQUEST
          error_data = parse_response(response)
          raise ApiError.new("Bad Request: #{error_data['message']}", status: 400, data: error_data)
        when HTTP_UNAUTHORIZED
          raise ApiError.new("Unauthorized - Invalid token", status: 401)
        when HTTP_FORBIDDEN
          error_data = parse_response(response)
          raise ApiError.new("Forbidden: #{error_data['message']}", status: 403, data: error_data)
        when HTTP_NOT_FOUND
          raise ApiError.new("Not Found", status: 404)
        when HTTP_METHOD_NOT_ALLOWED
          raise ApiError.new("Method Not Allowed", status: 405)
        when HTTP_TOO_MANY_REQUESTS
          # Already handled in handle_rate_limiting
        else
          error_data = parse_response(response) rescue nil
          message = error_data&.dig('message') || "HTTP #{response.code}"
          raise ApiError.new(message, status: response.code.to_i, data: error_data)
        end
      end

      # Parse JSON response
      def parse_response(response)
        return nil if response.body.nil? || response.body.empty?
        
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        @logger.error "Failed to parse response: #{e.message}"
        @logger.error "Response body: #{response.body}"
        nil
      end

      # Create message with file attachments
      def create_message_with_files(channel_id, data, files)
        response = post(ApiEndpoints::CHANNEL_MESSAGES(channel_id), data: data, files: files)
        parse_response(response)
      end
    end
  end
end
