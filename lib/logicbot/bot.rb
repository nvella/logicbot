# Copyright 2014 nick (nick@nxk.me). This file is part of Logicbot.
#
#    Logicbot is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    Logicbot is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Logicbot.  If not, see <http://www.gnu.org/licenses/>.
#

module Logicbot
  class Bot
    attr_accessor :tcp, :buffer, :channels, :objects, :ticks, :server

    def initialize(username, identity_token, server_name, server_port)
      @username = username
      @server = Server.new(username, identity_token, server_name, server_port)

      @tcp = nil

      @tick_mutex = Mutex.new

      @block_cache = {} # Kept upto date with the block types in the world
      @buffer = ''
      @channels = {} # [channel_name] = true/false
      @objects  = {} # [[x, y, z]] = obj
      @channels_marked_for_update = Set.new
      @home = nil

      @ticks = 0
    end

    def load_from_file(filename)
      json = JSON.parse(File.read(filename))

      # Load channels
      @channels = json['channels']

      # Load home (will be nil if it doesn't exist)
      @home = json['home']

      # Load objects
      json['objects'].each do |pos, data|
        pos = pos.split(',').map(&:to_i)
        @objects[pos] = Objects::TYPES[data['type']].new(self, pos, data['in_channels'], data['out_channel'], data['needs_update'], data['metadata'])
        @objects[pos].signs = data['signs'] unless data['signs'].nil? # Provide backwards compat
      end
    end

    def save_to_file(filename)
      data = { 'home' => @home, 'channels' => @channels.dup, 'objects' => {} }

      # Save out the objects
      @objects.dup.each do |pos, obj|
        data['objects'][pos.join(',')] =  { 'type' => obj.class.to_s.split(':')[-1].downcase, 'in_channels' => obj.in_channels,
                                            'out_channel' => obj.out_channel, 'needs_update' => obj.needs_update, 'metadata' => obj.metadata,
                                            'signs' => obj.signs }
      end

      File.open filename, 'w' do |file|
        file.write(JSON.pretty_generate(data))
      end

      # Done
    end

    def run
      Logicbot.log "#{NAME} version #{VERSION} starting..."
      if File.exist? 'logicbot_state.json'
        load_from_file('logicbot_state.json')
        Logicbot.log('Loaded state.')
      end
      @server.connect
      @tick_thread = Thread.new { tick_thread }
      Signal.trap('SIGINT') do
        Logicbot.log('Quitting...')
        @server.disconnect
        save_to_file('logicbot_state.json')
        exit
      end
      # Go home
      @server.set_position(*@home) unless @home.nil?
      @server.send_chat_message("#{NAME} version #{VERSION}")
      @server.flush_buffer
      Logicbot.log('Ready.')

      loop do
        event = @server.get_event
        next if event.nil? # Skip if no event

        case event[:type]
        when :chat_message # Chat message
          Logicbot.log("Chat: #{event[:sender]}> #{event[:message]}")
          command = event[:message].split(' ') # Split message into params
          if command[0] == ".#{@username.downcase}" || command[0] == "@#{@username}" # If the message is directed at us
            case command[1]
            when 'debug'
              if command[2].nil?
                @server.send_private_message(event[:sender], "usage: @#{@username} debug CHANNEL_NAME")
              elsif @channels[command[2]].nil?
                @server.send_private_message(event[:sender], 'error: no such channel.')
              else
                @server.send_private_message(event[:sender], "#{command[2]} => #{@channels[command[2]]}")
              end
            end
          end
        when :chat_special # Chat broadcast
          Logicbot.log("Special message: #{event[:message]}")
        when :block_change # Block break/place
          # If block change was a break and there was an object at the location
          if event[:id] == 0 && !@objects[event[:pos]].nil?
            if @objects[event[:pos]].class == Objects::Toggle # Take special action if the object was a toggle
              @tick_mutex.synchronize do
                toggle_channel(@objects[event[:pos]].out_channel)
                mark_channel_for_update(@objects[event[:pos]].out_channel)
              end
              Logicbot.log("Toggled object at #{event[:pos].join(' ')}.")
            end

            @server.set_block(*event[:pos], @objects[event[:pos]].metadata)

            if @objects[event[:pos]].class::NEEDS_UPDATE_AFTER_BREAK # Update the object if it needs it
              @objects[event[:pos]].force_update
            end

            @objects[event[:pos]].signs.each_with_index do |sign, facing|
              if sign.to_s.length > 0
                @server.set_sign(*event[:pos], facing, sign.to_s)
              end
            end
          end
        when :sign_update # Sign
          if event[:text][0..6] == '[logic]' || event[:text][0..5] == '`logic' # TODO: Add config option for these keywords
            @server.set_sign(*event[:pos], event[:facing], '')
            sign_data = event[:text].split(' ')
            case sign_data[1]
            when 'delete', 'remove' # Player wants to delete object
              if !@objects[event[:pos]].nil?
                @tick_mutex.synchronize { @objects.delete event[:pos] }
                @server.set_block(*event[:pos], 0) if sign_data[2] == 'block'
                @server.send_chat_message("deleted object #{'and block ' if sign_data[2] == 'block'}at #{event[:pos].join(' ')}.")
              else
                @server.send_chat_message("error: no object exists at #{event[:pos].join(' ')}.")
              end
            when 'info' # Player wants info on object
              if !@objects[event[:pos]].nil?
                @server.send_chat_message("info for object at #{event[:pos].join(' ')}.")
                @server.send_chat_message("TYPE(#{@objects[event[:pos]].class.to_s.split(':')[-1].downcase}) IN(#{@objects[event[:pos]].in_channels.map { |c| unresolve_channel event[:pos], c }.join(' ').rstrip}) OUT(#{unresolve_channel event[:pos], @objects[event[:pos]].out_channel})")
              else
                @server.send_chat_message("error: no object exists at #{event[:pos].join(' ')}.")
              end
            else # Player is placing an object
              if !Objects::TYPES[sign_data[1]].nil? # Check if object type exists
                # Check the parameters
                parameters = sign_data[2..4]
                if !(parameters.length >= Objects::TYPES[sign_data[1]]::PARAMS || (parameters.length >= (Objects::TYPES[sign_data[1]]::PARAMS - 1) && Objects::TYPES[sign_data[1]]::PARAM_FORMAT[1] > 0))
                  param_format = Objects::TYPES[sign_data[1]]::PARAM_FORMAT
                  @server.send_chat_message("error: object type `#{sign_data[1]}' expects parameters in format #{(('input ' * param_format[0]) + if param_format[1] > 0 then '[output]' else '' end).rstrip}")
                elsif !@objects[event[:pos]].nil?
                  @server.send_chat_message("error: an object already exists at #{event[:pos].join(' ')}.")
                else
                  block_id = if !Objects::TYPES[sign_data[1]]::COLOUR.nil? then Objects::TYPES[sign_data[1]]::COLOUR else @server.get_block(*event[:pos]) end

                  if block_id.nil?
                    @server.send_chat_message('error: internal server error. please try again. (could not retrieve chunk)')
                  else
                    parameters = parameters.map { |channel| resolve_channel(event[:pos], channel) }

                    @tick_mutex.synchronize do
                      parameters.each { |channel| prepare_channel(channel) } # Prepare the channels
                    end

                    param_format = Objects::TYPES[sign_data[1]]::PARAM_FORMAT
                    in_channels = []
                    out_channel = nil

                    in_channels = parameters[0..(param_format[0] - 1)] if param_format[0] > 0

                    if param_format[1] > 0
                      if parameters[param_format[0]].nil?
                        # Create the block output channel
                        out_channel = event[:pos].join(',')
                        @tick_mutex.synchronize { prepare_channel event[:pos].join(',') }
                      else
                        # Use output channel provided
                        out_channel = parameters[param_format[0]]
                      end
                    end

                    @tick_mutex.synchronize do
                      @objects[event[:pos]] = Objects::TYPES[sign_data[1]].new(self, event[:pos], in_channels, out_channel, true, block_id)
                    end

                    unless Objects::TYPES[sign_data[1]]::COLOUR.nil?
                      @server.set_block(*event[:pos], 0) # Break the block
                      @server.set_block(*event[:pos], Objects::TYPES[sign_data[1]]::COLOUR) # Then set it
                    end

                    6.times { |i| @server.set_sign(*event[:pos], i, '') } # Clear all the signs on this block so we can keep update with new changes

                    # Add description sign
                    @objects[event[:pos]].signs[event[:facing]] = "#{@objects[event[:pos]].class.to_s.split(':')[-1].downcase} #{@objects[event[:pos]].in_channels.map { |c| unresolve_channel event[:pos], c }.join(' ').rstrip} #{unresolve_channel event[:pos], @objects[event[:pos]].out_channel}"
                    @server.set_sign(*event[:pos], event[:facing], @objects[event[:pos]].signs[event[:facing]])

                    @server.send_chat_message("`#{sign_data[1]}' object created at #{event[:pos].join(' ')}.")
                  end
                end
              else
                @server.send_chat_message("error: logic object type `#{sign_data[1]}' does not exist.\nvalid values are `#{Objects::TYPES.keys.join('\' `')}'")
              end
            end
          else # Placed a sign with text we might not care about
            @objects[event[:pos]].signs[event[:facing]] = event[:text] unless @objects[event[:pos]].nil? # We own a block at this location, update the sign data
          end
        end
        @server.flush_buffer
      end
    end

    def tick_thread
      loop do
        start_time = Time.now

        @tick_mutex.synchronize do
          @objects.each do |pos, obj| # Process each object that needs an update
            next unless obj.needs_update

            @channels['t'] = true  # dirty hack here
            @channels['f'] = false # dirty hack there

            CLOCK_CHANNELS.each do |channel, interval| # /really/ need to add read-only channels
              @channels[channel] = ((@ticks - 1) % interval) < CLOCK_ON_TIME # @ticks - 1 because the clock update will get sent to us next tick
            end

            obj.needs_update = false
            obj.update if obj.class::ALWAYS_ON || is_object_in_range?(pos)
          end

          CLOCK_CHANNELS.each do |channel, interval|
            if @ticks % interval == 0
              mark_channel_for_update(channel)
            elsif @ticks % interval == CLOCK_ON_TIME
              mark_channel_for_update(channel)
            end
          end

          @objects.each do |_, obj|
            if (!obj.in_channels[0].nil? && @channels_marked_for_update.include?(obj.in_channels[0])) || (!obj.in_channels[1].nil? && @channels_marked_for_update.include?(obj.in_channels[1]))
              obj.needs_update = true
            end
          end
          @channels_marked_for_update = Set.new

          @server.flush_buffer
        end

        total = Time.now - start_time
        if TICK_DELAY > total
          sleep(TICK_DELAY - total)
        else
          Logicbot.log("Tick took too long! #{total}s")
        end

        if @ticks > 0 && @ticks % 3000 == 0 # Automatic save, TODO make config option for this
          Thread.new do
            Logicbot.log('Saving...')
            save_to_file('logicbot_state.json')
            Logicbot.log('Done.')
          end
        end
        @ticks += 1
      end
    end

    def prepare_channel(channel)
      @channels[channel] = false if @channels[channel].nil?
    end

    def mark_channel_for_update(channel)
      @channels_marked_for_update.add(channel)
    end

    def toggle_channel(channel)
      @channels[channel] = !@channels[channel]
    end

    def unresolve_channel(pos, channel_name)
      return channel_name if channel_name.nil? || channel_name.split(',').length != 3
      other_pos = channel_name.split(',').map(&:to_i)
      case [other_pos[0] - pos[0], other_pos[1] - pos[1], other_pos[2] - pos[2]]
      when [0, 1, 0]
        return 'u'
      when [0, -1, 0]
        return 'd'
      when [1, 0, 0]
        return 'n'
      when [-1, 0, 0]
        return 's'
      when [0, 0, 1]
        return 'e'
      when [0, 0, -1]
        return 'w'
      else
        return channel_name
      end
    end

    def resolve_channel(pos, channel_name)
      case channel_name.downcase
      when 'u'
        return [pos[0], pos[1] + 1, pos[2]].join(',')
      when 'd'
        return [pos[0], pos[1] - 1, pos[2]].join(',')
      when 'n'
        return [pos[0] + 1, pos[1], pos[2]].join(',')
      when 's'
        return [pos[0] - 1, pos[1], pos[2]].join(',')
      when 'e'
        return [pos[0], pos[1], pos[2] + 1].join(',')
      when 'w'
        return [pos[0], pos[1], pos[2] - 1].join(',')
      else
        return channel_name
      end
    end

    def is_object_in_range?(pos)
      @server.players.dup.each do |_, data|
        next if data[:pos].nil?
        dist_x = (pos[0] - data[:pos][0]).abs
        dist_z = (pos[2] - data[:pos][2]).abs
        return true if !data[:name].downcase.include?('bot') && Math.sqrt((dist_x**2.0) + (dist_z**2.0)) < 256
      end
      return false
    end
  end
end
