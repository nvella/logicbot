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
  class Server
    attr_accessor :block_cache
    attr_reader :username
  
    def initialize username, identity_token, server_name, server_port
      @username = username
      @identity_token = identity_token
      
      @server_name = server_name
      @server_port = server_port
      @block_cache = {}
      
      @write_mutex = Mutex.new
      
      @buffer = ''
      
      @tcp = nil
    end
    
    def connect
      # Authenticate with craft.michaelfogleman.com
      uri = URI.parse 'https://craft.michaelfogleman.com/api/1/identity'
      http = Net::HTTP.new uri.host, uri.port
      http.use_ssl = true

      response = http.post uri.request_uri, "username=#{@username}&identity_token=#{@identity_token}"
      server_token = response.body.chomp
      if server_token.length != 32 then raise "Could not authenticate!" end
      
      # Connect and authenticate with the server
      @tcp = TCPSocket.new @server_name, @server_port
      @tcp.puts "A,#{@username},#{server_token}"
    end
    
    def get_event
      # Blocks and returns an event hash
      data = @tcp.gets.chomp.split(',')
      
      case data[0]
      when 'T'            # Chat message
        message_contents = data[1 .. -1].join(',')
        if message_contents.split('>')[1] != nil then # If message was said by player
          return {:type => :chat_message, :sender => message_contents.split('>')[0], :message => message_contents.split('>')[1].lstrip}
        else
          return {:type => :chat_broadcast, :message => message_contents}
        end
      when 'B'            # Block change
        pos = [data[3].to_i, data[4].to_i, data[5].to_i] # Create the position data
        if data[1].to_i != pos[0] / CHUNK_SIZE or data[2].to_i != pos[2] / CHUNK_SIZE then return nil end
        return {:type => :block_change, :pos => pos, :id => data[6].to_i}
      when 'S'            # Sign change
        return {:type => :sign_update, :pos => [data[3].to_i, data[4].to_i, data[5].to_i], :facing => data[6].to_i, :text => data[7 .. -1].join(',')}
      else
        return nil
      end
    end
    
    def get_block x, y, z     # get_block_at
      # Return block if it exists in cache
      if @block_cache[[x, y, z]] != nil then return @block_cache[[x, y, z]] end

      # Otherwise, request the chunk the block is in.
      @write_mutex.synchronize do
        chunk_x = (x / CHUNK_SIZE).floor
        chunk_z = (z / CHUNK_SIZE).floor        
        @tcp.puts "C,#{chunk_x},#{chunk_z}"
        @tcp.flush
        
        # Keep mutex locked to stop other threads requesting from server
        while true do
          data = @tcp.gets.chomp.split(',')
          if data[0] == 'B' then
            @block_cache[[data[3].to_i, data[4].to_i, data[5].to_i]] = data[6].to_i
          elsif data[0] == 'C' then
            break
          end
        end
      end
      
      return @block_cache[[x, y, z]]
    end
    
    def set_block x, y, z, id # set_block
      @write_mutex.synchronize do
        @buffer += "B,#{x},#{y},#{z},#{id}\n"
      end
    end
        
    def flush_buffer
      @write_mutex.synchronize do
        @tcp.write @buffer
        @tcp.flush
        @buffer = ''
      end
    end
  end
end
