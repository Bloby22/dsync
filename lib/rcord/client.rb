require require 'json'
require 'uri'
require 'net/http'
require 'websocket-client-simple'
require 'concurrent'
require 'logger'

require_relative 'core/gateway'
require_relative 'core/rest_client'
require_relative 'core/event_manager'
require_relative 'core/command_manager'
require_relative 'utils/logger'
require_relative 'errors/discord_error'
require_relative 'constants/intents'
require_relative 'constants/opcodes'

module discord_ruby

    class client
        include constants

        attr_reader :token, :intents, :user, :guilds, :channels, :logger
        attr_reader :gateway, :rest_client, :event_manager, :command_manager
        attr_reader :ready, :shard_id, :shard_count

        def initialize(token:, intents: Intents::DEFAULT, **options)
            @token = validate_token!(token)
            @intents = intents
            @shard_id = options[:shard_id] || 0
            @shard_count = options[:shard_count] || 1
            @ready = Concurrent::AtomicBoolean.new(false)

            # Collections
            @guilds = Concurrent::Hash.new
            @channels = Concurrent::Hash.new
            @users = Concurrent::Hash.new

            # Initialize components
            setup_logger(options[:log_level] || :info)
            setup_components

            @logger.info "[RCord] client initalized with shard #{@shard_id}/#{@shard_count}"
        end

        def run!
            @logger.info "Starting Discord bot..."

            begin
                # Connect to gateway
                @gateway.connect!

                # Keep the main thread alive
                loop do
                    sleep 1
                    break unless @gateway.connected?
                end

            rescue Interrupt
                @logger.info "Received interrupt signal, shutting down."
                stop!
            rescue => e
                @logger.error "Fatal ERROR: #{e.message}"
                @logger.error e.backtrace.join("\n")
                stop!
                raise
            end
        end

        # Stop the bot gracefully
        def stop!
            @logger.info "Shutting down Discord bot..."

            @ready.make_false
            @gateway&.disconnect!

            @logger.info "Discord Bot stopped"
        end


        def ready?
            @ready.value
        end

        def on(event_name, &block)
            @event_manager.on(event_name, &block)
        end

        # Register slash commands
    def slash_command(name, description, **options, &block)
      @command_manager.register_slash_command(name, description, options, &block)
    end

    # Register text commands (legacy)
    def command(name, **options, &block)
      @command_manager.register_command(name, options, &block)
    end

    # Get user by ID
    def get_user(user_id)
      return @users[user_id] if @users.key?(user_id)
      
      @rest_client.get_user(user_id).tap do |user|
        @users[user_id] = user if user
      end
    end

    # Get guild by ID
    def get_guild(guild_id)
      return @guilds[guild_id] if @guilds.key?(guild_id)
      
      @rest_client.get_guild(guild_id).tap do |guild|
        @guilds[guild_id] = guild if guild
      end
    end

    # Get channel by ID
    def get_channel(channel_id)
      return @channels[channel_id] if @channels.key?(channel_id)
      
      @rest_client.get_channel(channel_id).tap do |channel|
        @channels[channel_id] = channel if channel
      end
    end

    # Send message to channel
    def send_message(channel_id, content = nil, **options)
      @rest_client.create_message(channel_id, content, **options)
    end

    # Edit message
    def edit_message(channel_id, message_id, content = nil, **options)
      @rest_client.edit_message(channel_id, message_id, content, **options)
    end

    # Delete message
    def delete_message(channel_id, message_id)
      @rest_client.delete_message(channel_id, message_id)
    end

    # Add reaction to message
    def add_reaction(channel_id, message_id, emoji)
      @rest_client.create_reaction(channel_id, message_id, emoji)
    end

    # Remove reaction from message
    def remove_reaction(channel_id, message_id, emoji, user_id = '@me')
      @rest_client.delete_reaction(channel_id, message_id, emoji, user_id)
    end

    # Update bot status
    def update_status(status, activity = nil)
      @gateway.update_presence(status, activity)
    end

    # Set bot activity
    def set_activity(name, type: :playing, url: nil)
      activity = { name: name, type: activity_type_to_int(type) }
      activity[:url] = url if url && type == :streaming
      
      update_status(:online, activity)
    end

    # Get application commands (slash commands)
    def get_application_commands(guild_id = nil)
      if guild_id
        @rest_client.get_guild_application_commands(@user.id, guild_id)
      else
        @rest_client.get_global_application_commands(@user.id)
      end
    end

    # Create application command (slash command)
    def create_application_command(command_data, guild_id = nil)
      if guild_id
        @rest_client.create_guild_application_command(@user.id, guild_id, command_data)
      else
        @rest_client.create_global_application_command(@user.id, command_data)
      end
    end

    # Bulk overwrite application commands
    def overwrite_application_commands(commands, guild_id = nil)
      if guild_id
        @rest_client.bulk_overwrite_guild_application_commands(@user.id, guild_id, commands)
      else
        @rest_client.bulk_overwrite_global_application_commands(@user.id, commands)
      end
    end

    # Internal method called when bot is ready
    def handle_ready!(user_data, guilds_data, session_id)
      @user = Entities::User.new(user_data, self)
      @session_id = session_id
      
      # Cache initial guilds
      guilds_data.each do |guild_data|
        guild = Entities::Guild.new(guild_data, self)
        @guilds[guild.id] = guild
      end
      
      @ready.make_true
      @logger.info "Bot ready as #{@user.username}##{@user.discriminator} (ID: #{@user.id})"
      
      # Emit ready event
      @event_manager.emit(:ready, self)
    end

    # Internal method to update cached objects
    def cache_user(user_data)
      user = Entities::User.new(user_data, self)
      @users[user.id] = user
      user
    end

    def cache_guild(guild_data)
      guild = Entities::Guild.new(guild_data, self)
      @guilds[guild.id] = guild
      guild
    end

    def cache_channel(channel_data)
      channel = Entities::Channel.new(channel_data, self)
      @channels[channel.id] = channel
      channel
    end

    # Internal method to remove from cache
    def uncache_guild(guild_id)
      @guilds.delete(guild_id)
    end

    def uncache_channel(channel_id)
      @channels.delete(channel_id)
    end

    private

    def validate_token!(token)
      raise ArgumentError, 'Token cannot be nil or empty' if token.nil? || token.strip.empty?
      
      # Remove "Bot " prefix if present
      token = token.sub(/^Bot\s+/i, '')
      
      # Basic token format validation
      unless token.match?(/^[A-Za-z0-9._-]+$/)
        raise ArgumentError, 'Invalid token format'
      end
      
      "Bot #{token}"
    end

    def setup_logger(level)
      @logger = Utils::Logger.new(level)
    end

    def setup_components
      @rest_client = Core::RestClient.new(self)
      @event_manager = Core::EventManager.new(self)
      @command_manager = Core::CommandManager.new(self)
      @gateway = Core::Gateway.new(self)
      
      # Register internal event handlers
      setup_internal_events
    end

    def setup_internal_events
      # Handle gateway events
      @event_manager.on(:raw_message_create) do |data|
        message = Entities::Message.new(data, self)
        @event_manager.emit(:message_create, message)
        
        # Handle commands
        @command_manager.handle_message(message) if message.content
      end

      @event_manager.on(:raw_guild_create) do |data|
        guild = cache_guild(data)
        @event_manager.emit(:guild_create, guild)
      end

      @event_manager.on(:raw_guild_delete) do |data|
        guild = @guilds[data['id']]
        uncache_guild(data['id'])
        @event_manager.emit(:guild_delete, guild) if guild
      end

      @event_manager.on(:raw_channel_create) do |data|
        channel = cache_channel(data)
        @event_manager.emit(:channel_create, channel)
      end

      @event_manager.on(:raw_channel_delete) do |data|
        channel = @channels[data['id']]
        uncache_channel(data['id'])
        @event_manager.emit(:channel_delete, channel) if channel
      end

      @event_manager.on(:raw_interaction_create) do |data|
        interaction = Entities::Interaction.new(data, self)
        @event_manager.emit(:interaction_create, interaction)
        
        # Handle slash commands
        @command_manager.handle_interaction(interaction)
      end
    end

    def activity_type_to_int(type)
      case type.to_sym
      when :playing then 0
      when :streaming then 1
      when :listening then 2
      when :watching then 3
      when :custom then 4
      when :competing then 5
      else 0
      end
    end
  end
end
