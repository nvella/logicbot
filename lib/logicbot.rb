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
  NAME = "Logicbot"
  VERSION = "0.0.4"
  
  TICK_DELAY = 0.1
  CHUNK_SIZE = 32
  
  def self.log str
    STDOUT.puts "[#{Time.now.to_s}] #{str}"
    STDOUT.flush
  end  
end

$: << File.dirname(__FILE__)

require 'net/http'
require 'socket'
require 'json'

require 'logicbot/bot'
require 'logicbot/objects'
