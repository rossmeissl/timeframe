module Ykk # :nodoc: all
  def ykk(*arys, &blk) # YKK: a better zipper
    return zip(*arys) unless block_given?
    zip(*arys).collect { |a| yield a }
  end
end
