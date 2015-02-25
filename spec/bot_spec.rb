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

require 'minitest/spec'
require 'minitest/autorun'

require_relative '../lib/logicbot'

describe Logicbot::Bot do
  it 'can prepare channels' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.prepare_channel 'test'
    bot.channels['test'].must_equal false
  end

  it 'can toggle channels' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.prepare_channel 'test'
    bot.toggle_channel 'test'
    bot.channels['test'].must_equal true
  end

  it 'can resolve relative channels' do
    Logicbot::Bot.new('', '', '', 0).resolve_channel([0, 0, 0], 'u').must_equal '0,1,0'
    Logicbot::Bot.new('', '', '', 0).resolve_channel([0, 0, 0], 'd').must_equal '0,-1,0'
    Logicbot::Bot.new('', '', '', 0).resolve_channel([0, 0, 0], 'n').must_equal '1,0,0'
    Logicbot::Bot.new('', '', '', 0).resolve_channel([0, 0, 0], 's').must_equal '-1,0,0'
    Logicbot::Bot.new('', '', '', 0).resolve_channel([0, 0, 0], 'e').must_equal '0,0,1'
    Logicbot::Bot.new('', '', '', 0).resolve_channel([0, 0, 0], 'w').must_equal '0,0,-1'                    
  end
  
  it 'can unresolve relative channels' do
    Logicbot::Bot.new('', '', '', 0).unresolve_channel([0, 0, 0], '0,1,0').must_equal 'u'
    Logicbot::Bot.new('', '', '', 0).unresolve_channel([0, 0, 0], '0,-1,0').must_equal 'd'
    Logicbot::Bot.new('', '', '', 0).unresolve_channel([0, 0, 0], '1,0,0').must_equal 'n'
    Logicbot::Bot.new('', '', '', 0).unresolve_channel([0, 0, 0], '-1,0,0').must_equal 's'
    Logicbot::Bot.new('', '', '', 0).unresolve_channel([0, 0, 0], '0,0,1').must_equal 'e'
    Logicbot::Bot.new('', '', '', 0).unresolve_channel([0, 0, 0], '0,0,-1').must_equal 'w'                    
  end
end
