// dsync | Discord framework for programming language for TypeScript
// version: 0.0.1

declare module 'dsync' {
    import { EventEmitter } from 'events';

    // DEFAULT TYPES AND EXTENSIONS

    export interface ClientOptions {
        token: string;
        intents: GatewayIntent[];
        presence?: PresenceData;
        shards?: number | number[] | 'auto';
        shardCount?: number;
        cache?: CacheOptions;
        logger?: LoggerOptions;
        retryLimit?: number;
        restTimeout?: number;
        restOffset?: number;
    }

    export interface CacheOptions {
        guilds?: boolean | number;
        users?: boolean | number;
        members?: boolean | number;
        channels?: boolean | number;
        messages?: boolean | number;
        roles?: boolean | number;
        emojis?: boolean | number;
        presences?: boolean | number; 
    }

    export interface LoggerOptions {
        level?: LogLevel;
        format?: 'json' | 'simple';
        timestamp?: boolean;
        colors?: boolean;
        file?: string;
    }

    export enum LogLevel {
        ERROR = 0,
        WARN = 1,
        INFO = 2,
        DEBUG = 3,
        TRACE = 4
    }

    export enum GatewayIntent {
        GUILD = 1 << 0,
        GUILD_MEMBERS = 1 << 1,
        GUILD_BANS = 1 << 2,
        GUILD_EMOJI_AND_STICKERS = 1 << 3,
        GUILD_INTEGRATIONS = 1 << 4,
        GUILD_WEBHOOKS = 1 << 5,
        GUILD_INVITES = 1 << 6,
        GUILD_VOICE_STATES = 1 << 7,
        GUILD_PRESENCES = 1 << 8,
        GUILD_MESSAGES = 1 << 9,
        GUILD_MESSAGE_REACTIONS = 1 << 10,
        GUILD_MESSAGE_TYPING = 1 << 11,
        DIRECT_MESSAGES = 1 << 12,
        DIRECT_MESSAGE_REACTIONS = 1 << 13,
        DIRECT_MESSAGE_TYPING = 1 << 14,
        MESSAGE_CONTENT = 1 << 15,
        GUILD_SCHEDULED_EVENTS = 1 << 16,
        AUTO_MODERATION_CONFIGURATION = 1 << 20,
        AUTO_MODERATION_EXECUTION = 1 << 21
    }

    export interface PresenceData {
        status?: 'online' | 'idle' | 'dnd' | 'invisible';
        activities?: ActivityData[];
        afk?: boolean;
        since?: number | null;
    }

    export interface ActivityData {
        name: string,
        type: ActivityType;
        url?: string;
        state?: string;
        details?: string;
    }

    export enum ActivityType {
        PLAYING = 0,
        STREAMING = 1,
        LISTENING = 2,
        WATCHING = 3,
        CUSTOM = 4,
        COMPETING = 5
    }

    // DISCORD API TYPES

    export interface User {
        id: string;
        username: string;
        discriminator: string;
        avatar: string | null;
        bot?: boolean;
        system?: boolean;
        mfa_enabled?: boolean;
        banner?: string | null;
        accent_color?: number | null;
        locale?: string;
        verified?: boolean;
        email?: string | null;
        flags?: number;
        premium_type?: number;
        public_flags?: number;
    }

    export interface Guild {
        id: string;
        name: string;
        icon: string | null;
        icon_hash?: string | null;
        splash: string | null;
        discovery_splash: string | null;
        owner?: boolean;
        owner_id: string;
        permissions?: string;
        region?: string | null;
        afk_channel_id: string | null;
        afk_timeout: number;
        widget_enabled?: boolean;
        widget_channel_id?: string | null;
        verification_level: number;
        default_message_notifications: number;
        explicit_content_filter: number;
        roles: Role[];
        emojis: Emoji[];
        features: string[];
        mfa_level: number;
        application_id: string | null;
        system_channel_id: string | null;
        system_channel_flags: number;
        rules_channel_id: string | null;
        max_presences?: number | null;
        max_members?: number;
        vanity_url_code: string | null;
        description: string | null;
        banner: string | null;
        premium_tier: number;
        premium_subscription_count?: number;
        preferred_locale: string;
        public_updates_channel_id: string | null;
        max_video_channel_users?: number;
        approximate_member_count?: number;
        approximate_presence_count?: number;
        welcome_screen?: WelcomeScreen;
        nsfw_level: number;
        stickers?: Sticker[];
        premium_progress_bar_enabled: boolean;
    }

    export interface Channel {
        id: string;
        type: number;
        guild_id?: string;
        position?: number;
        permission_overwrites?: PermissionOverwrite[];
        name?: string;
        topic?: string | null;
        nsfw?: boolean;
        last_message_id?: string | null;
        bitrate?: number;
        user_limit?: number;
        rate_limit_per_user?: number;
        recipients?: User[];
        icon?: string | null;
        owner_id?: string;
        application_id?: string;
        parent_id?: string | null;
        last_pin_timestamp?: string | null;
        rtc_region?: string | null;
        video_quality_mode?: number;
        message_count?: number;
        member_count?: number;
        thread_metadata?: ThreadMetadata;
        member?: ThreadMember;
        default_auto_archive_duration?: number;
        permissions?: string;
        flags?: number;
        total_message_sent?: number;
    }


    export interface Message {
        id: string;
        channel_id: string;
        guild_id?: string;
        author: User;
        member?: GuildMember;
        content: string;
        timestamp: string;
        edited_timestamp: string | null;
        tts: boolean;
        mention_everyone: boolean;
        mentions: User[];
        mention_roles: string[];
        mention_channels?: ChannelMention[];
        attachments: Attachment[];
        embeds: Embed[];
        reactions?: Reaction[];
        nonce?: string | number;
        pinned: boolean;
        webhook_id?: string;
        type: number;
        activity?: MessageActivity;
        application?: Application;
        application_id?: string;
        message_reference?: MessageReference;
        flags?: number;
        referenced_message?: Message | null;
        interaction?: MessageInteraction;
        thread?: Channel;
        components?: Component[];
        sticker_items?: StickerItem[];
        stickers?: Sticker[];
    }

    export interface GuildMember {
        user?: User;
        nick?: string | null;
        avatar?: string | null;
        roles: string[];
        joined_at: string;
        premium_since?: string | null;
        deaf: boolean;
        mute: boolean;
        flags: number;
        pending?: boolean;
        permissions?: string;
        communication_disabled_until?: string | null;
    }

  export interface Role {
        id: string;
        name: string;
        color: number;
        hoist: boolean;
        icon?: string | null;
        unicode_emoji?: string | null;
        position: number;
        permissions: string;
        managed: boolean;
        mentionable: boolean;
        tags?: RoleTag;
    }

  export interface Emoji {
        id: string | null;
        name: string | null;
        roles?: string[];
        user?: User;
        require_colons?: boolean;
        managed?: boolean;
        animated?: boolean;
        available?: boolean;
    }

  export interface Interaction {
        id: string;
        application_id: string;
        type: InteractionType;
        data?: InteractionData;
        guild_id?: string;
        channel_id?: string;
        member?: GuildMember;
        user?: User;
        token: string;
        version: number;
        message?: Message;
        app_permissions?: string;
        locale?: string;
        guild_locale?: string;
    }

  export enum InteractionType {
        PING = 1,
        APPLICATION_COMMAND = 2,
        MESSAGE_COMPONENT = 3,
        APPLICATION_COMMAND_AUTOCOMPLETE = 4,
        MODAL_SUBMIT = 5    
    }

  export interface InteractionData {
        id?: string;
        name?: string;
        type?: number;
        resolved?: InteractionResolvedData;
        options?: ApplicationCommandInteractionDataOption[];
        custom_id?: string;
        component_type?: number;
        values?: string[];
        target_id?: string;
        components?: Component[];
    }


   // Helpful types for completely API.
   
   export interface PermissionOverwrite {
        id: string;
        type: number;
        allow: string;
        deny: string;
    }

  export interface ThreadMetadata {
        archived: boolean;
        auto_archive_duration: number;
        archive_timestamp: string;
        locked: boolean;
        invitable?: boolean;
        create_timestamp?: string | null;
    }

  export interface ThreadMember {
        id?: string;
        user_id?: string;
        join_timestamp: string;
        flags: number;
    }

  export interface ChannelMention {
        id: string;
        guild_id: string;
        type: number;
        name: string;
    }

  export interface Attachment {
        id: string;
        filename: string;
        description?: string;
        content_type?: string;
        size: number;
        url: string;
        proxy_url: string;
        height?: number | null;
        width?: number | null;
        ephemeral?: boolean;
    }

  export interface Embed {
        title?: string;
        type?: string;
        description?: string;
        url?: string;
        timestamp?: string;
        color?: number;
        footer?: EmbedFooter;
        image?: EmbedImage;
        thumbnail?: EmbedThumbnail;
        video?: EmbedVideo;
        provider?: EmbedProvider;
        author?: EmbedAuthor;
        fields?: EmbedField[];
    }

  export interface EmbedFooter {
        text: string;
        icon_url?: string;
        proxy_icon_url?: string;
    }

  export interface EmbedImage {
        url: string;
        proxy_url?: string;
        height?: number;
        width?: number;
    }

  export interface EmbedThumbnail {
        url: string;
        proxy_url?: string;
        height?: number;
        width?: number;
    }

  export interface EmbedVideo {
        url?: string;
        proxy_url?: string;
        height?: number;
        width?: number;
    }

  export interface EmbedProvider {
        name?: string;
        url?: string;
    }

  export interface EmbedAuthor {
        name: string;
        url?: string;
        icon_url?: string;
        proxy_icon_url?: string;
    }

  export interface EmbedField {
        name: string;
        value: string;
        inline?: boolean;
    }

  export interface Reaction {
        count: number;
        me: boolean;
        emoji: Emoji;
    }

  export interface MessageActivity {
        type: number;
        party_id?: string;
    }

  export interface Application {
        id: string;
        name: string;
        icon: string | null;
        description: string;
        rpc_origins?: string[];
        bot_public: boolean;
        bot_require_code_grant: boolean;
        terms_of_service_url?: string;
        privacy_policy_url?: string;
        owner?: User;
        verify_key: string;
        team?: Team | null;
        guild_id?: string;
        primary_sku_id?: string;
        slug?: string;
        cover_image?: string;
        flags?: number;
        tags?: string[];
        install_params?: InstallParams;
        custom_install_url?: string;
    }

  export interface MessageReference {
        message_id?: string;
        channel_id?: string;
        guild_id?: string;
        fail_if_not_exists?: boolean;
    }

  export interface MessageInteraction {
        id: string;
        type: InteractionType;
        name: string;
        user: User;
        member?: GuildMember;
    }

  export interface Component {
        type: number;
        custom_id?: string;
        disabled?: boolean;
        style?: number;
        label?: string;
        emoji?: Emoji;
        url?: string;
        options?: SelectOption[];
        placeholder?: string;
        min_values?: number;
        max_values?: number;
        min_length?: number;
        max_length?: number;
        required?: boolean;
        value?: string;
        components?: Component[];
    }

  export interface SelectOption {
        label: string;
        value: string;
        description?: string;
        emoji?: Emoji;
        default?: boolean;
    }

  export interface Sticker {
        id: string;
        pack_id?: string;
        name: string;
        description: string | null;
        tags: string;
        asset?: string;
        type: number;
        format_type: number;
        available?: boolean;
        guild_id?: string;
        user?: User;
        sort_value?: number;
    }

  export interface StickerItem {
        id: string;
        name: string;
        format_type: number;
    }

  export interface WelcomeScreen {
        description: string | null;
        welcome_channels: WelcomeScreenChannel[];
    }

  export interface WelcomeScreenChannel {
        channel_id: string;
        description: string;
        emoji_id: string | null;
        emoji_name: string | null;
    }

  export interface RoleTag {
        bot_id?: string;
        integration_id?: string;
        premium_subscriber?: null;
        subscription_listing_id?: string;
        available_for_purchase?: null;
        guild_connections?: null;
    }

  export interface InteractionResolvedData {
        users?: Record<string, User>;
        members?: Record<string, GuildMember>;
        roles?: Record<string, Role>;
        channels?: Record<string, Channel>;
        messages?: Record<string, Message>;
        attachments?: Record<string, Attachment>;
    }

  export interface ApplicationCommandInteractionDataOption {
        name: string;
        type: number;
        value?: any;
        options?: ApplicationCommandInteractionDataOption[];
        focused?: boolean;
    }

  export interface Team {
        icon: string | null;
        id: string;
        members: TeamMember[];
        name: string;
        owner_user_id: string;
    }

  export interface TeamMember {
        membership_state: number;
        permissions: string[];
        team_id: string;
        user: User;
    }

  export interface InstallParams {
        scopes: string[];
        permissions: string;
    }


    // CLIENT class

    export class Client extends EventEmitter {
        constructor(options: ClientOptions);

        // 
        readonly token: string;
        readonly user: User | null;
        readonly application: Application | null;
        readonly uptime: number | null;
        readonly ping: number;
        readonly readyAt: Date | null;
        readonly cache: Cache;
        readonly gateway: Gateway;
        readonly logger: Logger;
        readonly commands: Map<string, Command>;
        readonly events: Map<string, Event[]>;

        // Methods
        login(token?: string): Promise<string>;
        logout(): Promise<void>;
        destroy(): void;
        isReady(): boolean;

        // Commands helper
        registerCommand(command: Command): void;
        unregisterCommand(name: string): boolean;
        getCommand(name: string): Command | undefined;

        // Events helper
        registerEvent(event: Event): void;
        unregisterEvent(name: string, listener?: Function): boolean;

        // API methods
        fetchUser(id: string, force?: boolean): Promise<User>;
        fetchGuild(id: string, force?: boolean): Promise<Guild>;
        fetchChannel(id: string, force?: boolean): Promise<Channel>;
        fetchMessage(channelId: string, messageId: string, force?: boolean): Promise<Message>;

        // Interaction
        createGlobalCommand(data: ApplicationCommandData): Promise<ApplicationCommand>;
        createGuildCommand(guildId: string, data: ApplicationCommandData): Promise<ApplicationCommand>;
        deleteGlobalCommand(commandId: string): Promise<void>;
        deleteGuildCommand(guildId: string, commandId: string): Promise<void>;

        // Events
        on(event: 'ready', listener: () => void): this;
        on(event: 'messageCreate', listener: (message: Message) => void): this;
        on(event: 'messageDelete', listener: (message: Message) => void): this;
        on(event: 'messageUpdate', listener: (oldMessage: Message, newMessage: Message) => void): this;
        on(event: 'guildCreate', listener: (guild: Guild) => void): this;
        on(event: 'guildDelete', listener: (guild: Guild) => void): this;
        on(event: 'guildUpdate', listener: (oldGuild: Guild, newGuild: Guild) => void): this;
        on(event: 'guildMemberAdd', listener: (member: GuildMember) => void): this;
        on(event: 'guildMemberRemove', listener: (member: GuildMember) => void): this;
        on(event: 'guildMemberUpdate', listener: (oldMember: GuildMember, newMember: GuildMember) => void): this;
        on(event: 'interactionCreate', listener: (interaction: Interaction) => void): this;
        on(event: 'error', listener: (error: Error) => void): this;
        on(event: 'warn', listener: (warning: string) => void): this;
        on(event: 'debug', listener: (info: string) => void): this;
        on(event: string, listener: (...args: any[]) => void): this;

        once(event: 'ready', listener: () => void): this;
        once(event: 'messageCreate', listener: (message: Message) => void): this;
        once(event: 'interactionCreate', listener: (interaction: Interaction) => void): this;
        once(event: string, listener: (...args: any[]) => void): this;
        
        emit(event: 'ready'): boolean;
        emit(event: 'messageCreate', message: Message): boolean;
        emit(event: 'interactionCreate', interaction: Interaction): boolean;
        emit(event: string, ...args: any[]): boolean;
    }

    // COMMANDS CLASS

    export interface CommandOptions {
        name: string;
        description: string;
        aliases?: string[];
        category?: string;
        usage?: string;
        examples?: string[];
        permissions?: string[];
        ownerOnly?: boolean;
        guildOnly?: boolean;
        nsfw?: boolean;
        cooldown?: number;
        args?: CommandArgument[];
    }

    export interface CommandArgument {
        name: string;
        type: 'string' | 'number' | 'boolean' | 'user' | 'channel' | 'role' | 'mentionable';
        description: string;
        required?: boolean;
        choices?: CommandChoice[];
    }

    export interface CommandChoice {
        name: string;
        value: string | number;
    }

    export interface CommandContext {
        client: Client;
        message?: Message;
        interaction?: Interaction;
        guild: Guild | null;
        channel: Channel;
        author: User;
        member: GuildMember | null;
        args: any[];
        reply(content: string | MessageOptions): Promise<Message>;
        editReply(content: string | MessageOptions): Promise<Message>;
        followUp(content: string | MessageOptions): Promise<Message>;
        defer(ephemeral?: boolean): Promise<void>;
    }


    export interface MessageOptions {
        content?: string;
        embeds?: Embed[];
        components?: Component[];
        files?: FileData[];
        ephemeral?: boolean;
        tts?: boolean;
        allowedMentions?: AllowedMentions;
    }

    export interface FileData {
        attachment: Buffer | string;
        name: string;
        description?: string;
    }

    export interface AllowedMentions {
        parse?: ('users' | 'roles' | 'everyone')[];
        roles?: string[];
        users?: string[];
        replied_user?: boolean;
    }

    export abstract class Command {
        constructor(options: CommandOptions);
        
        readonly name: string;
        readonly description: string;
        readonly aliases: string[];
        readonly category: string;
        readonly usage: string;
        readonly examples: string[];
        readonly permissions: string[];
        readonly ownerOnly: boolean;
        readonly guildOnly: boolean;
        readonly nsfw: boolean;
        readonly cooldown: number;
        readonly args: CommandArgument[];
        
        abstract execute(context: CommandContext): Promise<void> | void;
        
        checkPermissions(member: GuildMember | null, channel: Channel): boolean;
        checkCooldown(userId: string): boolean;
        setCooldown(userId: string): void;
        validateArgs(args: any[]): boolean;
    }

    // EVENT CLASS

    export interface EventOptions {
        name: string;
        once?: boolean;
        enabled?: boolean;
    }

    export abstract class Event {
        constructor(options: EventOptions);
        
        readonly name: string;
        readonly once: boolean;
        readonly enabled: boolean;
        
        abstract execute(client: Client, ...args: any[]): Promise<void> | void;
    }

    // GATEWAY CLASS

    export interface GatewayOptions {
    intents: GatewayIntent[];
    shards?: number | number[] | 'auto';
    shardCount?: number;
    compress?: boolean;
    largeThreshold?: number;
    version?: number;
    encoding?: 'json' | 'etf';
  }

    export class Gateway extends EventEmitter {
        constructor(client: Client, options: GatewayOptions);
        
        readonly client: Client;
        readonly shards: Map<number, Shard>;
        readonly ping: number;
        readonly status: GatewayStatus;
        
        connect(): Promise<void>;
        disconnect(code?: number, reason?: string): Promise<void>;
        reconnect(): Promise<void>;
        
        send(data: any, shard?: number): void;
        
        on(event: 'ready', listener: () => void): this;
        on(event: 'resumed', listener: () => void): this;
        on(event: 'disconnect', listener: (code: number, reason: string) => void): this;
        on(event: 'error', listener: (error: Error) => void): this;
        on(event: string, listener: (...args: any[]) => void): this;
    }

    export interface Shard {
        id: number;
        status: ShardStatus;
        ping: number;
        sequence: number | null;
        sessionId: string | null;
        lastHeartbeat: number;
        lastHeartbeatAck: number;
    }

    export enum GatewayStatus {
        IDLE = 0,
        CONNECTING = 1,
        CONNECTED = 2,
        RECONNECTING = 3,
        DISCONNECTED = 4
    }

    export enum ShardStatus {
        IDLE = 0,
        CONNECTING = 1,
        IDENTIFYING = 2,
        RESUMING = 3,
        READY = 4,
        DISCONNECTED = 5
    }


    // LOGGER CLASS

    export class Logger {
        constructor(options?: LoggerOptions);
        
        readonly level: LogLevel;
        readonly format: 'json' | 'simple';
        readonly timestamp: boolean;
        readonly colors: boolean;
        readonly file: string | null;
        
        error(message: string, ...meta: any[]): void;
        warn(message: string, ...meta: any[]): void;
        info(message: string, ...meta: any[]): void;
        debug(message: string, ...meta: any[]): void;
        trace(message: string, ...meta: any[]): void;
        
        log(level: LogLevel, message: string, ...meta: any[]): void;
        
        setLevel(level: LogLevel): void;
        isLevelEnabled(level: LogLevel): boolean;
    }

    // CACHE CLASS

        export class Cache {
        constructor(options?: CacheOptions);
        
        readonly options: CacheOptions;
    
    // Collection
        readonly users: Collection<string, User>;
        readonly guilds: Collection<string, Guild>;
        readonly channels: Collection<string, Channel>;
        readonly messages: Collection<string, Message>;
        readonly members: Collection<string, GuildMember>;
        readonly roles: Collection<string, Role>;
        readonly emojis: Collection<string, Emoji>;
        readonly presences: Collection<string, Presence>;

    // Methods
        get<T>(collection: string, key: string): T | undefined;
        set<T>(collection: string, key: string, value: T): void;
        delete(collection: string, key: string): boolean;
        has(collection: string, key: string): boolean;
        clear(collection?: string): void;
    
        size(collection?: string): number;


    // Sweep methods for clean cache
        sweep(collection: string, filter: (value: any, key: string) => boolean): number;
        sweepByAge(collection: string, maxAge: number): number;
        sweepBySize(collection: string, maxSize: number): number;
    }

    export interface Presence {
        user_id: string;
        guild_id: string;
        status: 'online' | 'idle' | 'dnd' | 'offline';
        activities: ActivityData[];
        client_status: {
        desktop?: string;
        mobile?: string;
        web?: string;
        };
    }

        export class Collection<K, V> extends Map<K, V> {
        constructor(entries?: ReadonlyArray<readonly [K, V]> | null);
        
        array(): V[];
        keyArray(): K[];
        first(): V | undefined;
        first(amount: number): V[];
        last(): V | undefined;
        last(amount: number): V[];
        random(): V | undefined;
        random(amount: number): V[];
        
        find(fn: (value: V, key: K, collection: this) => boolean): V | undefined;
        filter(fn: (value: V, key: K, collection: this) => boolean): Collection<K, V>;
        map<T>(fn: (value: V, key: K, collection: this) => T): T[];
        some(fn: (value: V, key: K, collection: this) => boolean): boolean;
        every(fn: (value: V, key: K, collection: this) => boolean): boolean;
        
        reduce<T>(fn: (accumulator: T, value: V, key: K, collection: this) => T, initialValue?: T): T;
        sort(compareFunction?: (firstValue: V, secondValue: V, firstKey: K, secondKey: K) => number): this;
        
        concat(...collections: Collection<K, V>[]): Collection<K, V>;
        difference(other: Collection<K, any>): Collection<K, V>;
        intersection(other: Collection<K, V>): Collection<K, V>;
        
        sweep(fn: (value: V, key: K, collection: this) => boolean): number;
        partition(fn: (value: V, key: K, collection: this) => boolean): [Collection<K, V>, Collection<K, V>];
        
        tap(fn: (collection: this) => void): this;
        clone(): Collection<K, V>;
    }

    // INTERACTION CLASS
    export class InteractionHandler {
        constructor(client: Client);
        
        readonly client: Client;
        
        handleInteraction(interaction: Interaction): Promise<void>;
        
        createInteractionResponse(interaction: Interaction, response: InteractionResponse): Promise<void>;
        editOriginalInteractionResponse(interaction: Interaction, response: InteractionResponse): Promise<Message>;
        deleteOriginalInteractionResponse(interaction: Interaction): Promise<void>;
        
        createFollowupMessage(interaction: Interaction, response: InteractionResponse): Promise<Message>;
        editFollowupMessage(interaction: Interaction, messageId: string, response: InteractionResponse): Promise<Message>;
        deleteFollowupMessage(interaction: Interaction, messageId: string): Promise<void>;
    }

    export interface InteractionResponse {
        type: InteractionResponseType;
        data?: InteractionResponseData;
    }

    export enum InteractionResponseType {
        PONG = 1,
        CHANNEL_MESSAGE_WITH_SOURCE = 4,
        DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE = 5,
        DEFERRED_UPDATE_MESSAGE = 6,
        UPDATE_MESSAGE = 7,
        APPLICATION_COMMAND_AUTOCOMPLETE_RESULT = 8,
        MODAL = 9
    }

    export interface InteractionResponseData {
        tts?: boolean;
        content?: string;
        embeds?: Embed[];
        allowed_mentions?: AllowedMentions;
        flags?: number;
        components?: Component[];
        attachments?: Attachment[];
        choices?: CommandChoice[];
        custom_id?: string;
        title?: string;
    }


    // APPLICATION COMMAND

    export interface ApplicationCommand {
        id: string;
        type?: number;
        application_id: string;
        guild_id?: string;
        name: string;
        name_localizations?: Record<string, string> | null;
        description: string;
        description_localizations?: Record<string, string> | null;
        options?: ApplicationCommandOption[];
        default_member_permissions?: string | null;
        dm_permission?: boolean;
        default_permission?: boolean | null;
        nsfw?: boolean;
        version: string;
    }

    export interface ApplicationCommandData {
        name: string;
        name_localizations?: Record<string, string>;
        description: string;
        description_localizations?: Record<string, string>;
        required?: boolean;
        choices?: ApplicationCommandOptionChoice[];
        options?: ApplicationCommandOption[];
        channel_types?: ChannelType[];
        min_value?: number;
        max_value?: number;
        min_length?: number;
        max_length?: number;
        autocomplete?: boolean;
    }

    
    export enum ApplicationCommandOptionType {
        SUB_COMMAND = 1,
        SUB_COMMAND_GROUP = 2,
        STRING = 3,
        INTEGER = 4,
        BOOLEAN = 5,
        USER = 6,
        CHANNEL = 7,
        ROLE = 8,
        MENTIONABLE = 9,
        NUMBER = 10,
        ATTACHMENT = 11
    }

    export interface ApplicationCommandOptionChoice {
        name: string;
        name_localizations?: Record<string, string>;
        value: string | number;
    }

    export enum ChannelType {
        GUILD_TEXT = 0,
        DM = 1,
        GUILD_VOICE = 2,
        GROUP_DM = 3,
        GUILD_CATEGORY = 4,
        GUILD_NEWS = 5,
        GUILD_STORE = 6,
        GUILD_NEWS_THREAD = 10,
        GUILD_PUBLIC_THREAD = 11,
        GUILD_PRIVATE_THREAD = 12,
        GUILD_STAGE_VOICE = 13,
        GUILD_DIRECTORY = 14,
        GUILD_FORUM = 15
    }

    // REST API class
    
    export class REST {
        constructor(options?: RESTOptions);
        
        readonly token: string | null;
        readonly version: string;
        readonly baseURL: string;
        readonly userAgent: string;
        
        setToken(token: string): void;
        
        get(endpoint: string, options?: RequestOptions): Promise<any>;
        post(endpoint: string, options?: RequestOptions): Promise<any>;
        put(endpoint: string, options?: RequestOptions): Promise<any>;
        patch(endpoint: string, options?: RequestOptions): Promise<any>;
        delete(endpoint: string, options?: RequestOptions): Promise<any>;
        
        request(method: string, endpoint: string, options?: RequestOptions): Promise<any>;
    }

    export interface RESTOptions {
        version?: string;
        baseURL?: string;
        userAgent?: string;
        timeout?: number;
        retries?: number;
        retryDelay?: number;
        globalRequestsPerSecond?: number;
        globalTimeout?: number;
        sweepInterval?: number;
        hashSweepInterval?: number;
        hashLifetime?: number;
        handlerSweepInterval?: number;
        invalidRequestWarningInterval?: number;
        authPrefix?: 'Bot' | 'Bearer';
    }

    export interface RequestOptions {
        query?: Record<string, any>;
        body?: any;
        files?: FileData[];
        headers?: Record<string, string>;
        auth?: boolean;
        reason?: string;
        versioned?: boolean;
    }

    // WEBHOOK SUPPORT
    export interface Webhook {
        id: string;
        type: WebhookType;
        guild_id?: string;
        channel_id: string | null;
        user?: User;
        name: string | null;
        avatar: string | null;
        token?: string;
        application_id: string | null;
        source_guild?: Guild;
        source_channel?: Channel;
        url?: string;
    }

    export enum WebhookType {
        INCOMING = 1,
        CHANNEL_FOLLOWER = 2,
        APPLICATION = 3
    }

    export class WebhookClient {
        constructor(options: WebhookClientOptions);
        
        readonly id: string;
        readonly token: string;
        readonly url: string;
        
        send(content: string | WebhookMessageOptions): Promise<Message>;
        edit(messageId: string, content: string | WebhookMessageOptions): Promise<Message>;
        delete(messageId: string): Promise<void>;
        
        fetch(): Promise<Webhook>;
        edit(data: WebhookEditData): Promise<Webhook>;
        delete(): Promise<void>;
    }

    export interface WebhookClientOptions {
        id: string;
        token: string;
        url?: string;
    }

    export interface WebhookMessageOptions {
        content?: string;
        username?: string;
        avatar_url?: string;
        tts?: boolean;
        embeds?: Embed[];
        allowed_mentions?: AllowedMentions;
        components?: Component[];
        files?: FileData[];
        thread_id?: string;
    }

    export interface WebhookEditData {
        name?: string;
        avatar?: Buffer | string | null;
        channel_id?: string;
    }

    // UTILITES CLASS and FUNCTION

    export class Permissions {
    constructor(bits?: string | number | bigint | Permissions);
    
    readonly bitfield: bigint;
    
    static FLAGS: Record<string, bigint>;
    static ALL: bigint;
    static DEFAULT: bigint;
    
    has(permission: PermissionResolvable): boolean;
    missing(permissions: PermissionResolvable[]): string[];
    add(...permissions: PermissionResolvable[]): Permissions;
    remove(...permissions: PermissionResolvable[]): Permissions;
    
    toArray(): string[];
    toString(): string;
    valueOf(): bigint;
    
    static resolve(permission: PermissionResolvable): bigint;
  }

  export type PermissionResolvable = string | number | bigint | Permissions;

  export class Util {
    static escapeMarkdown(text: string, options?: EscapeMarkdownOptions): string;
    static escapeCodeBlock(text: string): string;
    static escapeInlineCode(text: string): string;
    static escapeBold(text: string): string;
    static escapeItalic(text: string): string;
    static escapeUnderline(text: string): string;
    static escapeStrikethrough(text: string): string;
    static escapeSpoiler(text: string): string;
    
    static cleanContent(str: string, channel: Channel): string;
    static removeMentions(str: string): string;
    
    static parseEmoji(text: string): EmojiIdentifierResolvable | null;
    static resolveColor(color: ColorResolvable): number;
    static resolvePartialEmoji(emoji: EmojiIdentifierResolvable): PartialEmoji | null;
    
    static splitMessage(text: string, options?: SplitOptions): string[];
    static mergeDefault<T>(defaults: T, given: Partial<T>): T;
    static flatten(obj: any, prefix?: string): Record<string, any>;
    
    static discordSort<T>(collection: Collection<string, T>): Collection<string, T>;
    static basename(path: string, ext?: string): string;
    static dirname(path: string): string;
    
    static verifyString(data: string, error?: typeof Error, errorMessage?: string, allowEmpty?: boolean): string;
  }

  export interface EscapeMarkdownOptions {
        codeBlock?: boolean;
        inlineCode?: boolean;
        bold?: boolean;
        italic?: boolean;
        underline?: boolean;
        strikethrough?: boolean;
        spoiler?: boolean;
        codeBlockContent?: boolean;
        inlineCodeContent?: boolean;
    }

  export interface SplitOptions {
        maxLength?: number;
        char?: string;
        prepend?: string;
        append?: string;
    }

  export type ColorResolvable = 
        | 'DEFAULT'
        | 'WHITE'
        | 'AQUA'
        | 'GREEN'
        | 'BLUE'
        | 'YELLOW'
        | 'PURPLE'
        | 'LUMINOUS_VIVID_PINK'
        | 'FUCHSIA'
        | 'GOLD'
        | 'ORANGE'
        | 'RED'
        | 'GREY'
        | 'NAVY'
        | 'DARK_AQUA'
        | 'DARK_GREEN'
        | 'DARK_BLUE'
        | 'DARK_PURPLE'
        | 'DARK_VIVID_PINK'
        | 'DARK_GOLD'
        | 'DARK_ORANGE'
        | 'DARK_RED'
        | 'DARK_GREY'
        | 'DARKER_GREY'
        | 'LIGHT_GREY'
        | 'DARK_NAVY'
        | 'BLURPLE'
        | 'GREYPLE'
        | 'DARK_BUT_NOT_BLACK'
        | 'NOT_QUITE_BLACK'
        | 'RANDOM'
        | number
        | [number, number, number];

    export type EmojiIdentifierResolvable = string | Emoji | PartialEmoji;

    export interface PartialEmoji {
        id: string | null;
        name: string | null;
        animated?: boolean;
    }

    // CONST AND ENUMS
    export const Constants: {
    Package: {
      name: string;
      version: string;
      description: string;
      author: string;
      license: string;
      homepage: string;
    };
    
    UserAgent: string;
    
    Endpoints: {
      CDN: string;
      API: string;
      GATEWAY: string;
      OAUTH2: string;
    };
    
    WSCodes: Record<number, string>;
    HTTPCodes: Record<number, string>;
    
    Events: {
      READY: 'ready';
      RESUMED: 'resumed';
      APPLICATION_COMMAND_PERMISSIONS_UPDATE: 'applicationCommandPermissionsUpdate';
      AUTO_MODERATION_ACTION_EXECUTION: 'autoModerationActionExecution';
      AUTO_MODERATION_RULE_CREATE: 'autoModerationRuleCreate';
      AUTO_MODERATION_RULE_DELETE: 'autoModerationRuleDelete';
      AUTO_MODERATION_RULE_UPDATE: 'autoModerationRuleUpdate';
      CHANNEL_CREATE: 'channelCreate';
      CHANNEL_DELETE: 'channelDelete';
      CHANNEL_PINS_UPDATE: 'channelPinsUpdate';
      CHANNEL_UPDATE: 'channelUpdate';
      DEBUG: 'debug';
      WARN: 'warn';
      DISCONNECT: 'disconnect';
      ERROR: 'error';
      GUILD_AVAILABLE: 'guildAvailable';
      GUILD_BAN_ADD: 'guildBanAdd';
      GUILD_BAN_REMOVE: 'guildBanRemove';
      GUILD_CREATE: 'guildCreate';
      GUILD_DELETE: 'guildDelete';
      GUILD_UPDATE: 'guildUpdate';
      GUILD_UNAVAILABLE: 'guildUnavailable';
      GUILD_INTEGRATIONS_UPDATE: 'guildIntegrationsUpdate';
      GUILD_MEMBER_ADD: 'guildMemberAdd';
      GUILD_MEMBER_AVAILABLE: 'guildMemberAvailable';
      GUILD_MEMBER_REMOVE: 'guildMemberRemove';
      GUILD_MEMBER_UPDATE: 'guildMemberUpdate';
      GUILD_MEMBERS_CHUNK: 'guildMembersChunk';
      GUILD_ROLE_CREATE: 'guildRoleCreate';
      GUILD_ROLE_DELETE: 'guildRoleDelete';
      GUILD_ROLE_UPDATE: 'guildRoleUpdate';
      GUILD_SCHEDULED_EVENT_CREATE: 'guildScheduledEventCreate';
      GUILD_SCHEDULED_EVENT_DELETE: 'guildScheduledEventDelete';
      GUILD_SCHEDULED_EVENT_UPDATE: 'guildScheduledEventUpdate';
      GUILD_SCHEDULED_EVENT_USER_ADD: 'guildScheduledEventUserAdd';
      GUILD_SCHEDULED_EVENT_USER_REMOVE: 'guildScheduledEventUserRemove';
      GUILD_STICKER_CREATE: 'guildStickerCreate';
      GUILD_STICKER_DELETE: 'guildStickerDelete';
      GUILD_STICKER_UPDATE: 'guildStickerUpdate';
      GUILD_EMOJI_CREATE: 'guildEmojiCreate';
      GUILD_EMOJI_DELETE: 'guildEmojiDelete';
      GUILD_EMOJI_UPDATE: 'guildEmojiUpdate';
      INTERACTION_CREATE: 'interactionCreate';
      INVITE_CREATE: 'inviteCreate';
      INVITE_DELETE: 'inviteDelete';
      MESSAGE_CREATE: 'messageCreate';
      MESSAGE_DELETE: 'messageDelete';
      MESSAGE_REACTION_ADD: 'messageReactionAdd';
      MESSAGE_REACTION_REMOVE: 'messageReactionRemove';
      MESSAGE_REACTION_REMOVE_ALL: 'messageReactionRemoveAll';
      MESSAGE_REACTION_REMOVE_EMOJI: 'messageReactionRemoveEmoji';
      MESSAGE_UPDATE: 'messageUpdate';
      PRESENCE_UPDATE: 'presenceUpdate';
      STAGE_INSTANCE_CREATE: 'stageInstanceCreate';
      STAGE_INSTANCE_DELETE: 'stageInstanceDelete';
      STAGE_INSTANCE_UPDATE: 'stageInstanceUpdate';
      THREAD_CREATE: 'threadCreate';
      THREAD_DELETE: 'threadDelete';
      THREAD_LIST_SYNC: 'threadListSync';
      THREAD_MEMBERS_UPDATE: 'threadMembersUpdate';
      THREAD_MEMBER_UPDATE: 'threadMemberUpdate';
      THREAD_UPDATE: 'threadUpdate';
      TYPING_START: 'typingStart';
      USER_UPDATE: 'userUpdate';
      VOICE_SERVER_UPDATE: 'voiceServerUpdate';
      VOICE_STATE_UPDATE: 'voiceStateUpdate';
      WEBHOOK_UPDATE: 'webhookUpdate';
    };
    
    Status: {
      READY: 0;
      CONNECTING: 1;
      RECONNECTING: 2;
      IDLE: 3;
      NEARLY: 4;
      DISCONNECTED: 5;
      WAITING_FOR_GUILDS: 6;
      IDENTIFYING: 7;
      RESUMING: 8;
    };
    
    OPCodes: {
      DISPATCH: 0;
      HEARTBEAT: 1;
      IDENTIFY: 2;
      STATUS_UPDATE: 3;
      VOICE_STATE_UPDATE: 4;
      VOICE_GUILD_PING: 5;
      RESUME: 6;
      RECONNECT: 7;
      REQUEST_GUILD_MEMBERS: 8;
      INVALID_SESSION: 9;
      HELLO: 10;
      HEARTBEAT_ACK: 11;
    };
    
    VoiceOPCodes: {
      IDENTIFY: 0;
      SELECT_PROTOCOL: 1;
      READY: 2;
      HEARTBEAT: 3;
      SESSION_DESCRIPTION: 4;
      SPEAKING: 5;
      HEARTBEAT_ACK: 6;
      RESUME: 7;
      HELLO: 8;
      RESUMED: 9;
      CLIENT_DISCONNECT: 13;
    };
  };

  // ==========================================
  // ERROR TŘÍDY
  // ==========================================

  export class DiscordError extends Error {
    constructor(message?: string);
    readonly name: 'DiscordError';
  }

  export class DiscordAPIError extends DiscordError {
    constructor(path: string, error: any, method: string, status: number);
    readonly name: 'DiscordAPIError';
    readonly url: string;
    readonly status: number;
    readonly method: string;
    readonly path: string;
    readonly code: number;
    readonly httpStatus: number;
    readonly requestData: any;
  }

  export class DiscordHTTPError extends DiscordError {
    constructor(message: string, name: string, code: number, method: string);
    readonly name: 'DiscordHTTPError';
    readonly code: number;
    readonly method: string;
  }

  export class RateLimitError extends DiscordError {
    constructor(request: any);
    readonly name: 'RateLimitError';
    readonly timeout: number;
    readonly method: string;
    readonly path: string;
    readonly route: string;
    readonly global: boolean;
  }

  // MANAGERS

  export abstract class BaseManager<K, Holds, R = Holds> {
    constructor(client: Client, holds: new (...args: any[]) => Holds);
    
    readonly client: Client;
    readonly holds: new (...args: any[]) => Holds;
    readonly cache: Collection<K, Holds>;
    
    add(data: any, cache?: boolean): Holds;
    resolve(resolvable: R): Holds | null;
    resolveId(resolvable: R): K | null;
    valueOf(): Collection<K, Holds>;
  }

  export abstract class DataManager<K, Holds, R = Holds> extends BaseManager<K, Holds, R> {
    fetch(id: K, options?: FetchOptions): Promise<Holds>;
    fetch(id: K, options: FetchOptions & { force: false }): Promise<Holds | null>;
  }

  export interface FetchOptions {
    cache?: boolean;
    force?: boolean;
  }

  export class GuildManager extends DataManager<string, Guild> {
    create(options: GuildCreateOptions): Promise<Guild>;
    fetch(options: GuildResolvable): Promise<Guild>;
    fetch(options: FetchGuildOptions, cache?: boolean): Promise<Guild>;
  }

  export interface GuildCreateOptions {
    name: string;
    region?: string;
    icon?: Buffer | string;
    verification_level?: number;
    default_message_notifications?: number;
    explicit_content_filter?: number;
    roles?: PartialRoleData[];
    channels?: PartialChannelData[];
    afk_channel_id?: string;
    afk_timeout?: number;
    system_channel_id?: string;
    system_channel_flags?: number;
  }

  export interface PartialRoleData {
    name?: string;
    permissions?: PermissionResolvable;
    color?: ColorResolvable;
    hoist?: boolean;
    mentionable?: boolean;
  }

  export interface PartialChannelData {
    name: string;
    type?: ChannelType;
    topic?: string;
    bitrate?: number;
    user_limit?: number;
    rate_limit_per_user?: number;
    position?: number;
    parent_id?: string;
    nsfw?: boolean;
  }

  export interface FetchGuildOptions extends FetchOptions {
    guild: GuildResolvable;
    withCounts?: boolean;
  }

  export type GuildResolvable = Guild | string;

  export class UserManager extends DataManager<string, User> {
    fetch(options: UserResolvable): Promise<User>;
    fetch(options: FetchUserOptions, cache?: boolean): Promise<User>;
  }

  export interface FetchUserOptions extends FetchOptions {
    user: UserResolvable;
  }

  export type UserResolvable = User | string;

  export class ChannelManager extends DataManager<string, Channel> {
    fetch(options: ChannelResolvable): Promise<Channel>;
    fetch(options: FetchChannelOptions, cache?: boolean): Promise<Channel>;
  }

  export interface FetchChannelOptions extends FetchOptions {
    channel: ChannelResolvable;
  }

  export type ChannelResolvable = Channel | string;

  // EXPORTS MAIN CLASS

  export {
    Client,
    Command,
    Event,
    Gateway,
    Logger,
    Cache,
    Collection,
    InteractionHandler,
    REST,
    WebhookClient,
    Permissions,
    Util,
    Constants,
    
    // Error classes
    DiscordError,
    DiscordAPIError,
    DiscordHTTPError,
    RateLimitError,
    
    // Managers
    BaseManager,
    DataManager,
    GuildManager,
    UserManager,
    ChannelManager
  };

  // VERSION AND METADATA

  export const version: string;
  export const author: string;
  export const license: string;
}
