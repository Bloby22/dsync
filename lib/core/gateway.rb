# frozen_string_literal: true

require 'websocket-client-simple'
require 'json'
require 'concurrent'
require 'zlib'

require_relative '../constants/opcodes'
require_relative '../constants/intents'
require_relative '../errors/gateway_error'
require_relative 'heartbeat'


module gateway_ruby
    module Core
        class Gateway
            include Constants

            attr_reader :client, :ws, :session_id, :sequence, :heartbeat
            attr_reader :connected, :ready, :resume_gateway_url

            # Gateway close codes that should trigger a reconnect
      RECONNECT_CLOSE_CODES = [
        4000, # Unknown error
        4001, # Unknown opcode
        4002, # Decode error
        4003, # Not authenticated
        4005, # Already authenticated
        4007, # Invalid seq
        4008, # Rate limited
        4009, # Session timed out
      ].freeze

      # Gateway close codes that should NOT trigger a reconnect
      FATAL_CLOSE_CODES = [
        4004, # Authentication failed
        4010, # Invalid shard
        4011, # Sharding required
        4012, # Invalid API version
        4013, # Invalid intent(s)
        4014, # Disallowed intent(s)
      ].freeze

      def initialize(client)
        @client = client
        @session_id = nil
        @sequence = Concurrent::AtomicFixnum.new(0)
        @connected = Concurrent::AtomicBoolean.new(false)
        @ready = Concurrent::AtomicBoolean.new(false)
        @heartbeat = Heartbeat.new(self)
        @reconnect_attempts = 0
        @max_reconnect_attempts = 5
        @resume_gateway_url = nil
        @compression = false
        @logger = client.logger
      end

      # Connect to Discord Gateway
      def connect!
        @logger.info "Connecting to Discord Gateway..."
        
        gateway_info = get_gateway_info
        gateway_url = gateway_info['url']
        
        # Add query parameters
        url = build_gateway_url(gateway_url)
        
        @logger.debug "Connecting to: #{url}"
        
        # Create WebSocket connection
        @ws = WebSocket::Client::Simple.connect(url)
        
        setup_websocket_handlers
        
        # Wait for connection
        sleep 0.1 until @ws.open?
        @connected.make_true
        
        @logger.info "Connected to Discord Gateway"
        
        # Start heartbeat in separate thread
        @heartbeat.start
        
      rescue => e
        @logger.error "Failed to connect to gateway: #{e.message}"
        raise GatewayError, "Connection failed: #{e.message}"
      end

      # Disconnect from gateway
      def disconnect!
        @logger.info "Disconnecting from Discord Gateway..."
        
        @connected.make_false
        @ready.make_false
        @heartbeat.stop
        
        @ws&.close if @ws&.open?
        @ws = nil
        
        @logger.info "Disconnected from Discord Gateway"
      end

      # Check if connected
      def connected?
        @connected.value && @ws&.open?
      end

      # Check if ready
      def ready?
        @ready.value
      end

      # Send payload to gateway
      def send_payload(op_code, data = nil)
        return unless connected?
        
        payload = { op: op_code }
        payload[:d] = data if data
        
        json = JSON.generate(payload)
        
        @logger.debug "Sending payload: #{json}" if @client.debug?
        @ws.send(json)
        
      rescue => e
        @logger.error "Failed to send payload: #{e.message}"
      end

      # Send identify payload
      def identify
        @logger.info "Identifying with Discord..."
        
        identify_data = {
          token: @client.token,
          intents: @client.intents,
          properties: {
            '$os' => RUBY_PLATFORM,
            '$browser' => 'DiscordRuby',
            '$device' => 'DiscordRuby'
          },
          compress: @compression,
          large_threshold: 50
        }
        
        # Add sharding info if needed
        if @client.shard_count > 1
          identify_data[:shard] = [@client.shard_id, @client.shard_count]
        end
        
        send_payload(Opcodes::IDENTIFY, identify_data)
      end

      # Send resume payload
      def resume
        return unless @session_id
        
        @logger.info "Resuming Discord session..."
        
        resume_data = {
          token: @client.token,
          session_id: @session_id,
          seq: @sequence.value
        }
        
        send_payload(Opcodes::RESUME, resume_data)
      end

      # Update presence
      def update_presence(status, activity = nil)
        return unless ready?
        
        presence_data = {
          status: status.to_s,
          afk: false,
          since: nil,
          activities: activity ? [activity] : []
        }
        
        send_payload(Opcodes::PRESENCE_UPDATE, presence_data)
        @logger.debug "Updated presence: #{status}"
      end

      # Request guild members
      def request_guild_members(guild_id, query: '', limit: 0)
        return unless ready?
        
        request_data = {
          guild_id: guild_id,
          query: query,
          limit: limit
        }
        
        send_payload(Opcodes::REQUEST_GUILD_MEMBERS, request_data)
      end

      # Update voice state
      def update_voice_state(guild_id, channel_id, mute: false, deaf: false)
        voice_data = {
          guild_id: guild_id,
          channel_id: channel_id,
          self_mute: mute,
          self_deaf: deaf
        }
        
        send_payload(Opcodes::VOICE_STATE_UPDATE, voice_data)
      end

      private

      # Get gateway information from Discord API
      def get_gateway_info
        response = @client.rest_client.request(:get, '/gateway/bot')
        
        unless response.success?
          raise GatewayError, "Failed to get gateway info: #{response.body}"
        end
        
        JSON.parse(response.body)
      end

      # Build gateway URL with parameters
      def build_gateway_url(base_url)
        uri = URI(base_url)
        query_params = {
          v: 10,
          encoding: 'json'
        }
        query_params[:compress] = 'zlib-stream' if @compression
        
        uri.query = URI.encode_www_form(query_params)
        uri.to_s
      end

      # Setup WebSocket event handlers
      def setup_websocket_handlers
        @ws.on :open do |event|
          @logger.debug "WebSocket opened"
        end

        @ws.on :message do |event|
          handle_message(event.data)
        end

        @ws.on :close do |event|
          handle_close(event.code, event.reason)
        end

        @ws.on :error do |event|
          @logger.error "WebSocket error: #{event.message}"
        end
      end

      # Handle incoming WebSocket messages
      def handle_message(data)
        begin
          # Handle compression if enabled
          data = decompress_data(data) if @compression
          
          payload = JSON.parse(data)
          
          @logger.debug "Received payload: #{payload}" if @client.debug?
          
          # Update sequence number
          @sequence.value = payload['s'] if payload['s']
          
          # Handle based on opcode
          case payload['op']
          when Opcodes::DISPATCH
            handle_dispatch_event(payload)
          when Opcodes::HEARTBEAT
            @heartbeat.send_heartbeat
          when Opcodes::RECONNECT
            handle_reconnect
          when Opcodes::INVALID_SESSION
            handle_invalid_session(payload['d'])
          when Opcodes::HELLO
            handle_hello(payload['d'])
          when Opcodes::HEARTBEAT_ACK
            @heartbeat.acknowledge
          else
            @logger.warn "Unknown opcode received: #{payload['op']}"
          end
          
        rescue JSON::ParserError => e
          @logger.error "Failed to parse gateway message: #{e.message}"
        rescue => e
          @logger.error "Error handling gateway message: #{e.message}"
          @logger.error e.backtrace.join("\n")
        end
      end

      # Handle gateway close events
      def handle_close(code, reason)
        @logger.warn "Gateway connection closed: #{code} - #{reason}"
        
        @connected.make_false
        @ready.make_false
        @heartbeat.stop
        
        if should_reconnect?(code)
          schedule_reconnect
        else
          @logger.error "Gateway closed with fatal error code: #{code}"
          @client.stop!
        end
      end

      # Handle dispatch events (actual Discord events)
      def handle_dispatch_event(payload)
        event_type = payload['t']
        event_data = payload['d']
        
        case event_type
        when 'READY'
          handle_ready_event(event_data)
        when 'RESUMED'
          handle_resumed_event
        else
          # Emit raw event for client to handle
          @client.event_manager.emit("raw_#{event_type.downcase}", event_data)
        end
      end

      # Handle READY event
      def handle_ready_event(data)
        @session_id = data['session_id']
        @resume_gateway_url = data['resume_gateway_url']
        @ready.make_true
        @reconnect_attempts = 0
        
        @logger.info "Gateway session ready (Session ID: #{@session_id})"
        
        # Notify client
        @client.handle_ready!(
          data['user'],
          data['guilds'],
          @session_id
        )
      end

      # Handle RESUMED event
      def handle_resumed_event
        @ready.make_true
        @reconnect_attempts = 0
        @logger.info "Gateway session resumed"
      end

      # Handle HELLO event (start heartbeating)
      def handle_hello(data)
        heartbeat_interval = data['heartbeat_interval']
        @heartbeat.set_interval(heartbeat_interval)
        @logger.debug "Heartbeat interval set to #{heartbeat_interval}ms"
        
        # Identify or resume
        if @session_id && @resume_gateway_url
          resume
        else
          identify
        end
      end

      # Handle RECONNECT event
      def handle_reconnect
        @logger.info "Gateway requested reconnect"
        disconnect!
        schedule_reconnect
      end

      # Handle INVALID_SESSION event
      def handle_invalid_session(resumable)
        @logger.warn "Invalid session (resumable: #{resumable})"
        
        unless resumable
          @session_id = nil
          @resume_gateway_url = nil
          @sequence.value = 0
        end
        
        disconnect!
        schedule_reconnect
      end

      # Check if we should reconnect based on close code
      def should_reconnect?(code)
        return false if FATAL_CLOSE_CODES.include?(code)
        return true if RECONNECT_CLOSE_CODES.include?(code)
        
        # Unknown close codes - attempt reconnect
        true
      end

      # Schedule a reconnect attempt
      def schedule_reconnect
        return if @reconnect_attempts >= @max_reconnect_attempts
        
        @reconnect_attempts += 1
        delay = [2 ** @reconnect_attempts, 60].min # Exponential backoff, max 60s
        
        @logger.info "Scheduling reconnect attempt #{@reconnect_attempts}/#{@max_reconnect_attempts} in #{delay}s"
        
        Thread.new do
          sleep delay
          
          begin
            if @resume_gateway_url && @session_id
              # Use resume gateway URL
              url = build_gateway_url(@resume_gateway_url)
              @ws = WebSocket::Client::Simple.connect(url)
            else
              # Get new gateway URL
              connect!
              return
            end
            
            setup_websocket_handlers
            
            sleep 0.1 until @ws.open?
            @connected.make_true
            @heartbeat.start
            
          rescue => e
            @logger.error "Reconnect attempt failed: #{e.message}"
            schedule_reconnect if @reconnect_attempts < @max_reconnect_attempts
          end
        end
      end

      # Decompress zlib data if compression is enabled
      def decompress_data(data)
        return data unless @compression
        
        # Discord uses zlib-stream compression
        @inflate ||= Zlib::Inflate.new
        @inflate.inflate(data)
      rescue => e
        @logger.error "Failed to decompress data: #{e.message}"
        data # Return original data if decompression fails
      end
    end
  end
end
