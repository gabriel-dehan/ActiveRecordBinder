class Class
  def subclasses
    ObjectSpace.each_object(Class).select {  |klass| klass < self }
  end
end

class String
  def colorize code
    colors = { red: 31, green: 32, orange: 33, purple: 34, rose: 35 }
    code = colors[code]  unless code.kind_of? Numeric
    "\e[#{code}m#{self}\e[0m"
  end
end
