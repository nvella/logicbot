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

# convert_sqldb_to_json.rb
#  convert an old-style Logicbot world to the new flatfile JSON format

require 'sqlite3'
require 'json'

require_relative '../lib/logicbot'

if ARGV.length < 2 then
  STDERR.puts "usage: ruby convert_sqldb_to_json.rb in.db out.json"
  exit 1
end

db = SQLite3::Database.new ARGV[0]
data = { 'channels' => {}, 'objects' => {} }

STDERR.puts "Processing channels..."
db.execute("select * from channels;") {|row| data['channels'][row[0]] = row[1] == 1}

STDERR.puts "Processing objects..."
db.execute("select * from objects;") do |row| 
  obj = { 'type' => Logicbot::Objects::TYPES.to_a[row[4]][0], 'in_channels' => [row[5], row[6]], 
          'out_channel' => row[7], 'needs_update' => (row[8] == 1), 'metadata' => row[9] }

  data['objects'][[row[1], row[2], row[3]].join(',')] = obj
end

STDERR.puts "Saving out..."
File.open ARGV[1], 'w' do |file|
  file.write JSON.pretty_generate data
end
