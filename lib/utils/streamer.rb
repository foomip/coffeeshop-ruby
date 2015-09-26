class Streamer
  include Enumerable

  def initialize x
    @x = x
  end

  def each
    loop do
      @x.each { |y| yield y }
    end
  end
end
