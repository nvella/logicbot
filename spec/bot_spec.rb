require 'minitest/spec'
require 'minitest/autorun'

require_relative '../lib/logicbot'

describe Logicbot::Bot do
  it "can resolve relative channels" do
    Logicbot::Bot.new('', '', '', 0).resolve_channel([0, 0, 0], 'u').must_equal '0,1,0'
    Logicbot::Bot.new('', '', '', 0).resolve_channel([0, 0, 0], 'd').must_equal '0,-1,0'
    Logicbot::Bot.new('', '', '', 0).resolve_channel([0, 0, 0], 'n').must_equal '1,0,0'
    Logicbot::Bot.new('', '', '', 0).resolve_channel([0, 0, 0], 's').must_equal '-1,0,0'
    Logicbot::Bot.new('', '', '', 0).resolve_channel([0, 0, 0], 'e').must_equal '0,0,1'
    Logicbot::Bot.new('', '', '', 0).resolve_channel([0, 0, 0], 'w').must_equal '0,0,-1'                    
  end
  
  it "can unresolve relative channels" do
    Logicbot::Bot.new('', '', '', 0).unresolve_channel([0, 0, 0], '0,1,0').must_equal 'u'
    Logicbot::Bot.new('', '', '', 0).unresolve_channel([0, 0, 0], '0,-1,0').must_equal 'd'
    Logicbot::Bot.new('', '', '', 0).unresolve_channel([0, 0, 0], '1,0,0').must_equal 'n'
    Logicbot::Bot.new('', '', '', 0).unresolve_channel([0, 0, 0], '-1,0,0').must_equal 's'
    Logicbot::Bot.new('', '', '', 0).unresolve_channel([0, 0, 0], '0,0,1').must_equal 'e'
    Logicbot::Bot.new('', '', '', 0).unresolve_channel([0, 0, 0], '0,0,-1').must_equal 'w'                    
  end
end
