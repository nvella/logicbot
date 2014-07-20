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
      COLOUR = nil # A COLOUR value of nil means no block replace.
      NEEDS_UPDATE_AFTER_BREAK = false # object is updated after break if true
      
      attr_accessor :in_channels, :out_channel, :needs_update, :metadata, :signs
      def initialize bot, pos, in_channels, out_channel, needs_update = false, metadata = 0
        @bot = bot
        @pos = pos
        @in_channels = in_channels
        @out_channel = out_channel
        @needs_update = needs_update
        @metadata = metadata
        @signs = [''] * 6 # [block_face] = sign_text
        @last_state = nil
      end
      
      def update; force_update; end
      
      def force_update; end
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
      NEEDS_UPDATE_AFTER_BREAK = true
      
      def update
        if @last_state != @bot.channels[@in_channels[0]] then
          force_update
        end
      end
      
      def force_update
        @bot.server.set_light *@pos, if @bot.channels[@in_channels[0]] then 15 else 0 end
        @last_state = @bot.channels[@in_channels[0]]
      end
    end
    
    class AND < Base
      ID = 2
      PARAMS = 3
      PARAM_FORMAT = [2, 1]
      COLOUR = 32
      
      def update
        if @last_state != (@bot.channels[@in_channels[0]] and @bot.channels[@in_channels[1]]) then
          force_update
        end
      end
      
      def force_update
        @bot.channels[@out_channel] = (@bot.channels[@in_channels[0]] and @bot.channels[@in_channels[1]])
        @bot.mark_channel_for_update @out_channel
        @last_state = @bot.channels[@out_channel]
      end
    end
    
    class OR < Base
      ID = 3
      PARAMS = 3
      PARAM_FORMAT = [2, 1]
      COLOUR = 59

      def update
        if @last_state != (@bot.channels[@in_channels[0]] or @bot.channels[@in_channels[1]]) then
          force_update
        end
      end
      
      def force_update
        @bot.channels[@out_channel] = (@bot.channels[@in_channels[0]] or @bot.channels[@in_channels[1]])
        @bot.mark_channel_for_update @out_channel
        @last_state = @bot.channels[@out_channel]
      end
    end
    
    class NOT < Base
      ID = 4
      PARAMS = 2
      PARAM_FORMAT = [1, 1]
      COLOUR = 53
      
      def update
        if @last_state != !@bot.channels[@in_channels[0]] then
          force_update
        end
      end
      
      def force_update
        @bot.channels[@out_channel] = !@bot.channels[@in_channels[0]]
        @bot.mark_channel_for_update @out_channel
        @last_state = @bot.channels[@out_channel]
      end
    end
    
    class XOR < Base
      ID = 5
      PARAMS = 3
      PARAM_FORMAT = [2, 1]
      COLOUR = 45      
      
      def update
        if @last_state != (@bot.channels[@in_channels[0]] ^ @bot.channels[@in_channels[1]]) then
          force_update
        end
      end
      
      def force_update
        @bot.channels[@out_channel] = (@bot.channels[@in_channels[0]] ^ @bot.channels[@in_channels[1]])
        @bot.mark_channel_for_update @out_channel
        @last_state = @bot.channels[@out_channel]
      end
    end
    
    class Indicator < Base
      ID = 6
      PARAMS = 1
      PARAM_FORMAT = [1, 0]
      NEEDS_UPDATE_AFTER_BREAK = true
      
      def update
        if @last_state != @bot.channels[@in_channels[0]] then
          force_update
        end
      end
      
      def force_update
        @bot.server.set_block *@pos, 0
        @bot.server.set_block *@pos, if @bot.channels[@in_channels[0]] then 34 else 43 end
        @last_state = @bot.channels[@in_channels[0]]
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
