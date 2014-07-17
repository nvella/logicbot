Dir.entries(File.dirname(__FILE__)).each do |file|
  if file[-8 .. -1] == '_spec.rb' then
    require_relative file
  end
end
