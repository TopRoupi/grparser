require "greyparser/encoder"
require "greyparser/lzw"

 class Compressor
  def self.compress(string)
    compressed = Lzw.compress(string)
    Encoder.encode(compressed)
  end

  def self.decompress(string)
    decoded = Encoder.decode(string)
    Lzw.decompress(decoded)
  end
end

