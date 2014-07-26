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
  VERSION = "0.2.1"
  
  TICK_DELAY = 0.1
  CHUNK_SIZE = 32
  
  CLOCK_CHANNELS = {
    'clock:1s' => (1 / TICK_DELAY).floor,
    'clock:5s' => (5 / TICK_DELAY).floor,
    'clock:10s' => (10 / TICK_DELAY).floor,
    'clock:1m' => (60 / TICK_DELAY)
  }
  
  CLOCK_ON_TIME = 5 # Time, in ticks, that a clock channel remains on for
  
  def self.log str
    STDOUT.puts "[#{Time.now.to_s}] #{str}"
    STDOUT.flush
  end  
end

$: << File.dirname(__FILE__)

require 'net/http'
require 'socket'
require 'json'
require 'set'

require 'logicbot/bot'
require 'logicbot/objects'
require 'logicbot/server'
