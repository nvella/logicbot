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

describe Logicbot::Objects::Lamp do
  it 'can correctly change light value to 15' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => true}
    Logicbot::Objects::Lamp.new(bot, [0, 0, 0], ['a'], nil).update
    bot.server.instance_variable_get(:@buffer).must_equal "L,0,0,0,15\n"
  end
  
  it 'can correctly change light value to 0 after being 15' do
    bot = Logicbot::Bot.new '', '', '', 0
    lamp = Logicbot::Objects::Lamp.new(bot, [0, 0, 0], ['a'], nil)
    bot.channels = {'a' => true}
    lamp.update
    bot.channels['a'] = false
    lamp.update
    bot.server.instance_variable_get(:@buffer).must_equal "L,0,0,0,15\nL,0,0,0,0\n"
  end
  
  it 'does nothing if changing to 0 after 0' do
    bot = Logicbot::Bot.new '', '', '', 0
    lamp = Logicbot::Objects::Lamp.new(bot, [0, 0, 0], ['a'], nil)
    bot.channels = {'a' => false}
    lamp.update
    lamp.update
    bot.server.instance_variable_get(:@buffer).must_equal "L,0,0,0,0\n"
  end
  
  it 'does nothing if changing to 15 after 15' do
    bot = Logicbot::Bot.new '', '', '', 0
    lamp = Logicbot::Objects::Lamp.new(bot, [0, 0, 0], ['a'], nil)
    bot.channels = {'a' => true}
    lamp.update
    lamp.update
    bot.server.instance_variable_get(:@buffer).must_equal "L,0,0,0,15\n"
  end
end

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
  
  it 'does nothing if update returns the same values as previous update' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => true, 'b' => true, 'out' => false}
    obj = Logicbot::Objects::AND.new(bot, [0, 0, 0], ['a', 'b'], 'out')
    obj.update
    bot.instance_variable_get(:@channels_marked_for_update).include?('out').must_equal true
    bot.instance_variable_set :@channels_marked_for_update, []
    obj.update
    bot.instance_variable_get(:@channels_marked_for_update).include?('out').must_equal false
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
  
  it 'does nothing if update returns the same values as previous update' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => true, 'b' => false, 'out' => false}
    obj = Logicbot::Objects::OR.new(bot, [0, 0, 0], ['a', 'b'], 'out')
    obj.update
    bot.instance_variable_get(:@channels_marked_for_update).include?('out').must_equal true
    bot.instance_variable_set :@channels_marked_for_update, []
    bot.channels = {'a' => false, 'b' => true, 'out' => false}    
    obj.update
    bot.instance_variable_get(:@channels_marked_for_update).include?('out').must_equal false
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
  
  it 'does nothing if update returns the same values as previous update' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => true, 'b' => false, 'out' => false}
    obj = Logicbot::Objects::NOT.new(bot, [0, 0, 0], ['a'], 'out')
    obj.update
    bot.instance_variable_get(:@channels_marked_for_update).include?('out').must_equal true
    bot.instance_variable_set :@channels_marked_for_update, []
    obj.update
    bot.instance_variable_get(:@channels_marked_for_update).include?('out').must_equal false
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
  
  it 'does nothing if update returns the same values as previous update' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => true, 'b' => false, 'out' => false}
    obj = Logicbot::Objects::XOR.new(bot, [0, 0, 0], ['a', 'b'], 'out')
    obj.update
    bot.instance_variable_get(:@channels_marked_for_update).include?('out').must_equal true
    bot.instance_variable_set :@channels_marked_for_update, []
    bot.channels = {'a' => false, 'b' => true, 'out' => false}
    obj.update
    bot.instance_variable_get(:@channels_marked_for_update).include?('out').must_equal false
  end   
end

describe Logicbot::Objects::Indicator do
  it 'can correctly change to true' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => true}
    Logicbot::Objects::Indicator.new(bot, [0, 0, 0], ['a'], nil).update
    bot.server.instance_variable_get(:@buffer).must_equal "B,0,0,0,0\nB,0,0,0,34\n"
  end
  
  it 'can correctly change to false after being true' do
    bot = Logicbot::Bot.new '', '', '', 0
    indicator = Logicbot::Objects::Indicator.new(bot, [0, 0, 0], ['a'], nil)
    bot.channels = {'a' => true}
    indicator.update
    bot.channels['a'] = false
    indicator.update
    bot.server.instance_variable_get(:@buffer).must_equal "B,0,0,0,0\nB,0,0,0,34\nB,0,0,0,0\nB,0,0,0,43\n"
  end
  
  it 'does nothing if changing to false after false' do
    bot = Logicbot::Bot.new '', '', '', 0
    lamp = Logicbot::Objects::Indicator.new(bot, [0, 0, 0], ['a'], nil)
    bot.channels = {'a' => false}
    lamp.update
    lamp.update
    bot.server.instance_variable_get(:@buffer).must_equal "B,0,0,0,0\nB,0,0,0,43\n"
  end
  
  it 'does nothing if changing to 15 after 15' do
    bot = Logicbot::Bot.new '', '', '', 0
    lamp = Logicbot::Objects::Indicator.new(bot, [0, 0, 0], ['a'], nil)
    bot.channels = {'a' => true}
    lamp.update
    lamp.update
    bot.server.instance_variable_get(:@buffer).must_equal "B,0,0,0,0\nB,0,0,0,34\n"
  end
  
  it 'restores signs on update' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => true}
    obj = Logicbot::Objects::Indicator.new(bot, [0, 0, 0], ['a'], nil)
    obj.signs[0] = 'test'
    obj.update
    bot.server.instance_variable_get(:@buffer).must_equal "B,0,0,0,0\nB,0,0,0,34\nS,0,0,0,0,test\n"
  end
end

describe Logicbot::Objects::Door do
  it 'can close' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => false}
    Logicbot::Objects::Door.new(bot, [0, 0, 0], ['a'], nil, false, 15).update
    bot.server.instance_variable_get(:@buffer).must_equal "B,0,0,0,0\nB,0,0,0,15\n"
  end
  
  it 'can open after being closed' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => false}
    obj = Logicbot::Objects::Door.new(bot, [0, 0, 0], ['a'], nil, false, 15)
    obj.update
    bot.server.instance_variable_get(:@buffer).must_equal "B,0,0,0,0\nB,0,0,0,15\n"
    bot.channels = {'a' => true}
    obj.update
    bot.server.instance_variable_get(:@buffer).must_equal "B,0,0,0,0\nB,0,0,0,15\nB,0,0,0,0\n"
  end
  
  it 'does nothing if changing to false after false' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => false}
    obj = Logicbot::Objects::Door.new(bot, [0, 0, 0], ['a'], nil, false, 15)
    obj.update
    obj.update
    bot.server.instance_variable_get(:@buffer).must_equal "B,0,0,0,0\nB,0,0,0,15\n"
  end
  
  it 'does nothing if changing to true after true' do
    bot = Logicbot::Bot.new '', '', '', 0
    bot.channels = {'a' => true}
    obj = Logicbot::Objects::Door.new(bot, [0, 0, 0], ['a'], nil, false, 15)
    obj.update
    obj.update
    bot.server.instance_variable_get(:@buffer).must_equal "B,0,0,0,0\n"
  end
end
