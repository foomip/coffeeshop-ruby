class Streamer
  include Enumerable

  def initialize x
    @x = x
    @pos = 0
  end

  def each
    loop do
      @pos = 0 if @pos >= @x.length
      yield @x[@pos]
      @pos += 1
    end
  end
end
