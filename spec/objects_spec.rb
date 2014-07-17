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

require_relative '../lib/logicbot'

describe Logicbot::Objects::AND do
  it 'can correctly return true' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => true, 'b' => true, 'out' => false}
    Logicbot::Objects::AND.new(bot, [0, 0, 0], ['a', 'b'], 'out').update
    bot.channels['out'].must_equal true
  end
  
  it 'can correctly return false on one input being false' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => true, 'b' => false, 'out' => false}
    Logicbot::Objects::AND.new(bot, [0, 0, 0], ['a', 'b'], 'out').update
    bot.channels['out'].must_equal false
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => false, 'b' => true, 'out' => false}
    Logicbot::Objects::AND.new(bot, [0, 0, 0], ['a', 'b'], 'out').update
    bot.channels['out'].must_equal false    
  end
  
  it 'can correctly return false on both inputs being false' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => false, 'b' => false, 'out' => false}
    Logicbot::Objects::AND.new(bot, [0, 0, 0], ['a', 'b'], 'out').update
    bot.channels['out'].must_equal false
  end  
end

describe Logicbot::Objects::OR do
  it 'can correctly return true on both inputs being true' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => true, 'b' => true, 'out' => false}
    Logicbot::Objects::OR.new(bot, [0, 0, 0], ['a', 'b'], 'out').update
    bot.channels['out'].must_equal true
  end
  
  it 'can correctly return true on one input being true' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => true, 'b' => false, 'out' => false}
    Logicbot::Objects::OR.new(bot, [0, 0, 0], ['a', 'b'], 'out').update
    bot.channels['out'].must_equal true
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => false, 'b' => true, 'out' => false}
    Logicbot::Objects::OR.new(bot, [0, 0, 0], ['a', 'b'], 'out').update
    bot.channels['out'].must_equal true
  end
  
  it 'can correctly return false on both inputs being false' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => false, 'b' => false, 'out' => false}
    Logicbot::Objects::OR.new(bot, [0, 0, 0], ['a', 'b'], 'out').update
    bot.channels['out'].must_equal false
  end  
end

describe Logicbot::Objects::NOT do
  it 'can correctly return true on input being false' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => false, 'out' => false}
    Logicbot::Objects::NOT.new(bot, [0, 0, 0], ['a'], 'out').update
    bot.channels['out'].must_equal true
  end
  
  it 'can correctly return false on input being true' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => true, 'out' => false}
    Logicbot::Objects::NOT.new(bot, [0, 0, 0], ['a'], 'out').update
    bot.channels['out'].must_equal false
  end  
end

describe Logicbot::Objects::XOR do
  it 'can correctly return false on both inputs being true' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => true, 'b' => true, 'out' => false}
    Logicbot::Objects::XOR.new(bot, [0, 0, 0], ['a', 'b'], 'out').update
    bot.channels['out'].must_equal false
  end
  
  it 'can correctly return true on one input being true' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => true, 'b' => false, 'out' => false}
    Logicbot::Objects::XOR.new(bot, [0, 0, 0], ['a', 'b'], 'out').update
    bot.channels['out'].must_equal true
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => false, 'b' => true, 'out' => false}
    Logicbot::Objects::XOR.new(bot, [0, 0, 0], ['a', 'b'], 'out').update
    bot.channels['out'].must_equal true
  end
  
  it 'can correctly return false on both inputs being false' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => false, 'b' => false, 'out' => false}
    Logicbot::Objects::XOR.new(bot, [0, 0, 0], ['a', 'b'], 'out').update
    bot.channels['out'].must_equal false
  end  
end
