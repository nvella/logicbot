# Copyright 2014 nick (nick@nicko.ml). This file is part of Logicbot.
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
    attr_accessor :tcp, :buffer, :channels, :objects, :ticks
  
    def initialize username, identity_token, server_name, server_port
      @username = username
      @identity_token = identity_token
      
      @server_name = server_name
      @server_port = server_port
      
      @tcp = nil
      
      @tick_mutex = Mutex.new
      @write_mutex = Mutex.new
      
      @block_cache = {} # Kept upto date with the block types in the world
      @buffer = ''
      @channels = {} # [channel_name] = true/false
      @objects  = {} # [[x, y, z]] = obj
      @channels_marked_for_update = []
      @home = nil
      
      @ticks = 0
    end
    
    def load_from_file filename
      json = JSON.parse File.read filename

      # Load channels
      @channels = json['channels']
      
      # Load home (will be nil if it doesn't exist)
      @home = json['home']

      # Load objects
      json['objects'].each do |pos, data|
        pos = pos.split(',').map {|i| i.to_i}
        @objects[pos] = Objects::TYPES[data['type']].new self, pos, data['in_channels'], data['out_channel'], data['needs_update'], data['metadata']
        if data['signs'] != nil then @object[pos].signs = data['signs'] end # Provide backwards compat
      end
    end
    
    def save_to_file filename
      data = { 'home' => @home, 'channels' => @channels.dup, 'objects' => {} }
      
      # Save out the objects
      @objects.dup.each do |pos, obj|
        data['objects'][pos.join(',')] =  { 'type' => obj.class.to_s.split(':')[-1].downcase, 'in_channels' => obj.in_channels, 
                                            'out_channel' => obj.out_channel, 'needs_update' => obj.needs_update, 'metadata' => obj.metadata,
                                            'signs' => obj.signs }
      end
      
      File.open filename, 'w' do |file|
        file.write JSON.pretty_generate data
      end
      
      # Done
    end
    
    def authenticate
      uri = URI.parse 'https://craft.michaelfogleman.com/api/1/identity'
      http = Net::HTTP.new uri.host, uri.port
      http.use_ssl = true

      Logicbot.log "Attempting to authenticate with #{uri.host}"
      response = http.post uri.request_uri, "username=#{@username}&identity_token=#{@identity_token}"
      server_token = response.body.chomp
      if server_token.length != 32 then raise "Could not authenticate!" end
      
      # Connect and authenticate with the server
      Logicbot.log "Connecting to game server..."
      @tcp = TCPSocket.new @server_name, @server_port
      Logicbot.log "Authenticating with game server..."
      @tcp.puts "A,#{@username},#{server_token}"
      @tcp.puts "T,#{NAME} version #{VERSION}"
    end
    
    def run
      Logicbot.log "#{NAME} version #{VERSION} starting..."
      if File.exists? 'logicbot_state.json' then
        load_from_file 'logicbot_state.json'
        Logicbot.log 'Loaded state.'
      end
      authenticate
      @tick_thread = Thread.new {tick_thread}
      Signal.trap('SIGINT') {Logicbot.log 'Quitting...'; @tcp.close; save_to_file 'logicbot_state.json'; exit}
      # Go home
      if @home != nil then
        @write_mutex.synchronize do
          @tcp.puts "P,#{@home.join(',')}"
        end
      end
      Logicbot.log "Ready."
      
      while true do
        data = @tcp.gets.chomp.split(',')

        case data[0]
        when 'T' # Chat message
          Logicbot.log "Chat: #{data[1 .. -1].join(',')}"
          if data[1 .. -1].join(',').split('>')[1] != nil then # If message was said by player
            command = data[1 .. -1].join(',').split('>')[1].lstrip.split(' ') # Split message into params
            if command[0] == '.logicbot' then # If the message is directed at us
              case command[1]
              when 'debug'
                if command[2] == nil then
                  send_chat_message 'usage: .logicbot debug CHANNEL_NAME'
                elsif @channels[command[2]] == nil then
                  send_chat_message 'error: no such channel.'
                else
                  send_chat_message "#{command[2]} => #{@channels[command[2]]}"
                end
              end
            end
          end
        when 'B' # Block break/place
          pos = [data[3].to_i, data[4].to_i, data[5].to_i] # Create the position data
          id = data[6].to_i
          if data[1].to_i != pos[0] / CHUNK_SIZE or data[2].to_i != pos[2] / CHUNK_SIZE then next end # Ignore double notifies      

          # If block change was a break and there was an object at the location
          if id == 0 and @objects[pos] != nil then
            if @objects[pos].class == Objects::Toggle then # Take special action if the object was a toggle
              @tick_mutex.synchronize do
                toggle_channel @objects[pos].out_channel
                mark_channel_for_update @objects[pos].out_channel
              end
              Logicbot.log "Toggled object at #{pos.join(' ')}."              
            end

            set_block *pos, @objects[pos].metadata

            @objects[pos].signs.each_with_index do |sign, facing|
              if sign.length > 0 then
                set_sign *pos, facing, sign
              end
            end
          else
            @block_cache[pos] = id
          end
        when 'S' # Sign
          pos = [data[3].to_i, data[4].to_i, data[5].to_i] # Create the position data
          facing = data[6].to_i
          text = data[7 .. -1].join(',')
          if text[0 .. 6] == '[logic]' or text[0 .. 5] == '`logic' then # TODO Add config option for these keywords
            sign_data = text.split(' ')
            case sign_data[1]
            when 'delete', 'remove' # Player wants to delete object
              if @objects[pos] != nil then
                @tick_mutex.synchronize { @objects.delete pos }
                send_chat_message "deleted object at #{pos.join(' ')}."
              else
                send_chat_message "error: no object exists at #{pos.join(' ')}."
              end
            when 'info' # Player wants info on object
              if @objects[pos] != nil then
                send_chat_message "info for object at #{pos.join(' ')}.\nTYPE(#{@objects[pos].class.to_s.split(':')[-1].downcase}) IN(#{@objects[pos].in_channels.join(' ').rstrip}) OUT(#{@objects[pos].out_channel})"
              else
                send_chat_message "error: no object exists at #{pos.join(' ')}."
              end
            else # Player is placing an object
              if Objects::TYPES[sign_data[1]] != nil then # Check if object type exists
                # Check the parameters
                parameters = sign_data[2 .. 4]
                if parameters.length < Objects::TYPES[sign_data[1]]::PARAMS then
                  param_format = Objects::TYPES[sign_data[1]]::PARAM_FORMAT
                  send_chat_message "error: object type `#{sign_data[1]}' expects parameters in format #{'input ' * param_format[0]}#{'output' * param_format[1]}"
                elsif @objects[pos] != nil then
                  send_chat_message "error: an object already exists at #{pos.join(' ')}."
                else
                  block_id = if Objects::TYPES[sign_data[1]]::COLOUR != nil then Objects::TYPES[sign_data[1]]::COLOUR else get_block_at *pos end
                  
                  if block_id == nil then
                    send_chat_message "error: internal server error. please try again."
                  else
                    @tick_mutex.synchronize do
                      Objects::TYPES[sign_data[1]]::PARAMS.times {|i| prepare_channel parameters[i]} # Prepare the channels
                    end
                    
                    param_format = Objects::TYPES[sign_data[1]]::PARAM_FORMAT
                    in_channels = []
                    out_channel = nil
                    
                    if param_format[0] > 0 then
                      in_channels = parameters[0 .. (param_format[0] - 1)]
                    end
                    
                    if param_format[1] > 0 then
                      out_channel = parameters[param_format[0]]
                    end
                    
                    @tick_mutex.synchronize do
                      @objects[pos] = Objects::TYPES[sign_data[1]].new self, pos, in_channels, out_channel, true, block_id
                    end
                    
                    if Objects::TYPES[sign_data[1]]::COLOUR != nil then
                      set_block *pos, Objects::TYPES[sign_data[1]]::COLOUR
                    end
                    
                    6.times {|i| set_sign *pos, i, ''} # Clear all the signs on this block so we can keep update with new changes
                    send_chat_message "`#{sign_data[1]}' object created at #{pos.join(' ')}."
                  end
                end
              else
                send_chat_message "error: logic object type `#{sign_data[1]}' does not exist.\nvalid values are: #{Objects::TYPES.keys.join(' ')}" 
              end
            end
            set_sign *pos, facing, ''
          else # Placed a sign with text we might not care about
            if @objects[pos] != nil then # We own a block at this location, update the sign data
              @objects[pos].signs[facing] = text
            end
          end
        end  
        flush_buffer                        
      end
    end
    
    def get_block_at x, y, z
      # Return block if it exists in cache
      if @block_cache[[x, y, z]] != nil then return @block_cache[[x, y, z]] end
      # Otherwise, request the chunk the block is in.
      @write_mutex.synchronize do
        chunk_x = (x / CHUNK_SIZE).floor
        chunk_z = (z / CHUNK_SIZE).floor        
        @tcp.puts "C,#{chunk_x},#{chunk_z}"
        @tcp.flush
      end
      
      Logicbot.log "Downloading chunks..."
      while true do
        data = @tcp.gets.chomp.split(',')
        if data[0] == 'B' then
          @block_cache[[data[3].to_i, data[4].to_i, data[5].to_i]] = data[6].to_i
        elsif data[0] == 'C' then
          break
        end
      end
      Logicbot.log "Finished"
      
      return @block_cache[[x, y, z]]
    end
    
    def send_chat_message message
      message.lines.each do |line|
        @buffer += "T,#{line.chomp}\n"
      end
    end
    
    def set_sign x, y, z, facing, data
      @buffer += "S,#{x},#{y},#{z},#{facing},#{data}\n"
    end
    
    def set_block x, y, z, id
      @buffer += "B,#{x},#{y},#{z},#{id}\n"
    end
    
    def flush_buffer
      if @buffer.length > 0 then
        @write_mutex.synchronize do
          begin
            @tcp.write @buffer
            @tcp.flush
          rescue Exception
          end
        end
        @buffer = ''
      end
    end
    
    def tick_thread
      while true do
        start_time = Time.now
        @tick_mutex.synchronize do
          buffer = ''
          @objects.each do |pos, obj| # Process each object that needs an update
            if obj.needs_update then
              obj.needs_update = false
              obj.update
            end
          end
    
          @channels_marked_for_update.each do |channel|      
            @objects.each do |pos, obj|
              if obj.in_channels.include? channel then obj.needs_update = true end
            end
          end
          @channels_marked_for_update = []

          flush_buffer
        end
        
        total = Time.now - start_time
        if TICK_DELAY > total then 
          sleep (TICK_DELAY - total) 
        else
          Logicbot.log "Tick took too long! #{total}s"
        end
        
        if @ticks > 0 and @ticks % 3000 == 0 then # Automatic save, TODO make config option for this
          Thread.new do
            Logicbot.log "Saving..."
            save_to_file 'logicbot_state.json'
            Logicbot.log "Done."
          end
        end
        @ticks += 1
      end
    end
    
    def prepare_channel channel
      if @channels[channel] == nil then 
        @channels[channel] = false
      end      
    end
    
    def mark_channel_for_update channel
      @channels_marked_for_update.push channel
    end
    
    def toggle_channel channel
      @channels[channel] = !@channels[channel]
    end
  end
end
