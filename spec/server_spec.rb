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

require 'minitest/spec'
require 'minitest/autorun'

require 'stringio'

require_relative '../lib/logicbot'

class BidirectionalStringIO
  attr_accessor :in_io, :out_io

  def initialize
    @in_io = StringIO.new
    @out_io = StringIO.new
  end
  
  def write str
    @out_io.write str
  end
  
  def print str
    write str
  end
  
  def puts str
    print "#{str}\n"
  end
  
  def read bytes
    @in_io.read bytes
  end
  
  def gets
    @in_io.gets
  end
  
  def flush; end
end

describe Logicbot::Server do
  it 'can correctly handle a server chat message broadcast' do
    server = Logicbot::Server.new '', '', '', 0
    io = StringIO.new "T,abc,def\n"
    server.instance_variable_set :@tcp, io
    server.get_event.must_equal({:type => :chat_broadcast, :message => 'abc,def'})
  end
  
  it 'can correctly handle a player chat message' do
    server = Logicbot::Server.new '', '', '', 0
    io = StringIO.new "T,player> test,test123\n"
    server.instance_variable_set :@tcp, io
    server.get_event.must_equal({:type => :chat_message, :sender => 'player', :message => 'test,test123'})
  end
  
  it 'can correctly handle a block change' do
    server = Logicbot::Server.new '', '', '', 0
    io = StringIO.new "B,0,0,1,1,1,5\n"
    server.instance_variable_set :@tcp, io
    server.get_event.must_equal({:type => :block_change, :pos => [1, 1, 1], :id => 5})
  end
  
  it 'can correctly handle a block change double-notify' do
    server = Logicbot::Server.new '', '', '', 0
    io = StringIO.new "B,1,1,1,1,1,5\n"
    server.instance_variable_set :@tcp, io
    server.get_event.must_equal nil
  end
  
  it 'can correctly handle a sign update' do
    server = Logicbot::Server.new '', '', '', 0
    io = StringIO.new "S,0,0,1,1,1,4,test,test\n"
    server.instance_variable_set :@tcp, io
    server.get_event.must_equal({:type => :sign_update, :pos => [1, 1, 1], :facing => 4, :text => 'test,test'})
  end
  
  it 'can correctly handle a player joining' do
    server = Logicbot::Server.new '', '', '', 0
    io = StringIO.new "N,1,test,test\n"
    server.instance_variable_set :@tcp, io
    server.get_event.must_equal({:type => :player_join, :id => 1, :name => 'test,test'})
    server.players[1].must_equal 'test,test'
  end
  
  it 'can correctly handle a player leaving' do
    server = Logicbot::Server.new '', '', '', 0
    io = StringIO.new "N,1,test,test\nD,1\n"
    server.instance_variable_set :@tcp, io
    server.get_event
    server.get_event.must_equal({:type => :player_leave, :id => 1, :name => 'test,test'})
    server.players[1].must_equal nil
    server.players.length.must_equal 0
  end
  
  it 'can correctly handle itself joining' do
    server = Logicbot::Server.new '', '', '', 0
    io = StringIO.new "N,1,guest1\nN,1,test,test\n"
    server.instance_variable_set :@tcp, io
    server.get_event.must_equal({:type => :player_join, :id => 1, :name => 'guest1'})
    server.get_event.must_equal({:type => :player_join, :id => 1, :name => 'test,test'})
    server.players[1].must_equal 'test,test'
    server.players.length.must_equal 1
  end
  
  it 'can retrieve a block from the server when not in cache' do
    server = Logicbot::Server.new '', '', '', 0
    bidir_io = BidirectionalStringIO.new
    bidir_io.in_io = StringIO.new "B,0,0,5,5,5,10\nC,0,0\n"
    server.instance_variable_set :@tcp, bidir_io
    server.get_block(5, 5, 5).must_equal 10
    bidir_io.out_io.string.must_equal "C,0,0\n"
  end
  
  it 'can retrieve a block from the server when in cache' do
    server = Logicbot::Server.new '', '', '', 0
    server.instance_variable_set :@block_cache, {[5, 5, 5] => 10}
    server.get_block(5, 5, 5).must_equal 10
  end
  
  it 'can set a block' do
    server = Logicbot::Server.new '', '', '', 0
    server.set_block 5, 5, 5, 10
    server.instance_variable_get(:@buffer).must_equal "B,5,5,5,10\n"
  end
  
  it 'can flush the buffer correctly' do
    server = Logicbot::Server.new '', '', '', 0
    bidir_io = BidirectionalStringIO.new    
    server.instance_variable_set :@tcp, bidir_io    
    server.set_block 5, 5, 5, 10
    server.flush_buffer
    bidir_io.out_io.string.must_equal "B,5,5,5,10\n"
  end
  
  it 'can send a chat message' do
    server = Logicbot::Server.new '', '', '', 0
    server.send_chat_message "test"
    server.instance_variable_get(:@buffer).must_equal "T,test\n"
  end
  
  it 'can send a multiline chat message' do
    server = Logicbot::Server.new '', '', '', 0
    server.send_chat_message "test\ntest\n"
    server.instance_variable_get(:@buffer).must_equal "T,test\nT,test\n"
  end
  
  it 'can send a private message' do
    server = Logicbot::Server.new '', '', '', 0
    server.send_private_message "test_player", "test"
    server.instance_variable_get(:@buffer).must_equal "T,@test_player test\n"
  end
  
  it 'can send a multiline private message' do
    server = Logicbot::Server.new '', '', '', 0
    server.send_private_message "test_player", "test\ntest\n"
    server.instance_variable_get(:@buffer).must_equal "T,@test_player test\nT,@test_player test\n"
  end
  
  it 'can set a sign' do
    server = Logicbot::Server.new '', '', '', 0
    server.set_sign 5, 5, 5, 6, 'test'
    server.instance_variable_get(:@buffer).must_equal "S,5,5,5,6,test\n"
  end
  
  it 'can set position' do
    server = Logicbot::Server.new '', '', '', 0
    server.set_position 1.2, 2.3, 3.4, 4.5, 5.6
    server.instance_variable_get(:@buffer).must_equal "P,1.2,2.3,3.4,4.5,5.6\n"
  end
  
  it 'can set light values' do
    server = Logicbot::Server.new '', '', '', 0
    server.set_light 5, 4, 3, 15
    server.instance_variable_get(:@buffer).must_equal "L,5,4,3,15\n"
  end  
end
