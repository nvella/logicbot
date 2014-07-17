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
    def initialize username, identity_token, server_name, server_port
      @username = username
      @identity_token = identity_token
      
      @server_name = server_name
      @server_port = server_port
      
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
  end
end
