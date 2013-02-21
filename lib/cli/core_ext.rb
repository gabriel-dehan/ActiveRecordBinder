class Class
  # Public: Handy ! Returns all subclasses of a specific class.
  #
  # Returns an Array of Classes.
  def subclasses
    ObjectSpace.each_object(Class).select {  |klass| klass < self }
  end
end

class String
  # Public: Colorize a string for a Unix terminal.
  #
  # code - The color code: a Numeric [0-255] or a Symbol [:red, :green, :orange, :purple, :rose].
  #
  # Returns a colorized string.
  def colorize code
    colors = { red: 31, green: 32, orange: 33, purple: 34, rose: 35 }
    code = colors[code]  unless code.kind_of? Numeric
    "\e[#{code}m#{self}\e[0m"
  end
end
