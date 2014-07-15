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
  module Objects 
    class Base
      attr_accessor :in_channels, :out_channel, :needs_update, :metadata
      def initialize bot, pos, in_channels, out_channel, needs_update = false, metadata = 0
        @bot = bot
        @pos = pos
        @in_channels = in_channels
        @out_channel = out_channel
        @needs_update = needs_update
        @metadata = metadata
      end
      
      def update; end
    end
    
    class Toggle < Base
      ID = 0
      PARAMS = 1
      PARAM_FORMAT = [0, 1]
    end
    
    class Lamp < Base
      ID = 1
      PARAMS = 1
      PARAM_FORMAT = [1, 0]
      
      def update
        @bot.buffer += "L,#{@pos.join(',')},#{if @bot.channels[@in_channels[0]] then 15 else 0 end}\n"
      end
    end
    
    class AND < Base
      ID = 2
      PARAMS = 3
      PARAM_FORMAT = [2, 1]
      
      def update
        @bot.channels[@out_channel] = (@bot.channels[@in_channels[0]] and @bot.channels[@in_channels[1]])
        @bot.mark_channel_for_update @out_channel
      end
    end
    
    class OR < Base
      ID = 3
      PARAMS = 3
      PARAM_FORMAT = [2, 1]

      def update
        @bot.channels[@out_channel] = (@bot.channels[@in_channels[0]] or @bot.channels[@in_channels[1]])
        @bot.mark_channel_for_update @out_channel
      end      
    end
    
    class NOT < Base
      ID = 4
      PARAMS = 2
      PARAM_FORMAT = [1, 1]
      
      def update
        @bot.channels[@out_channel] = !@bot.channels[@in_channels[0]]
        @bot.mark_channel_for_update @out_channel
      end      
    end
    
    class XOR < Base
      ID = 5
      PARAMS = 3
      PARAM_FORMAT = [2, 1]
      
      def update
        @bot.channels[@out_channel] = (@bot.channels[@in_channels[0]] ^ @bot.channels[@in_channels[1]])
        @bot.mark_channel_for_update @out_channel
      end
    end
    
    class Indicator < Base
      ID = 6
      PARAMS = 1
      PARAM_FORMAT = [1, 0]
      
      def update
        @bot.buffer += "B,#{@pos.join(',')},0\nB,#{@pos.join(',')},#{if @bot.channels[@in_channels[0]] then 34 else 43 end}\n"
      end      
    end
    
    TYPES = {
      'toggle' => Toggle,
      'lamp'   => Lamp,
      'and'    => AND,
      'or'     => OR,
      'not'    => NOT,
      'xor'    => XOR,
      'indicator' => Indicator
    }    
  end
end  
