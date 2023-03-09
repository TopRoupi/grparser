class Lzw
  def self.compress(uncompressed)
    dict_size = 256

    dictionary = {} of String => Int32
    (0...dict_size).each do |i|
      dictionary[i.chr.to_s] = i
    end

    w = ""
    result = [] of String | Int32
    uncompressed.chars.each do |c|
      wc = w + c.to_s
      if dictionary.has_key?(wc.to_s)
        w = wc
      else
        result << dictionary[w.to_s]
        dictionary[wc.to_s] = dict_size
        dict_size += 1
        w = c
      end
    end

    result << dictionary[w.to_s] unless w.to_s.empty?
    result
  end

  def self.decompress(compressed)
    dict_size = 256

    dictionary = {} of String | Int32 => Int32 | String
    (0...dict_size).each do |i|
      dictionary[i.chr.to_s] = i
    end

    w = result = compressed.shift
    compressed.each do |k|
      if dictionary.has_key?(k)
        entry = dictionary[k]
      elsif k == dict_size
        entry = w.to_s + w.to_s[0, 1]
      else
        raise "Bad compressed k: #{k}"
      end
      result += entry.to_s

      dictionary[dict_size] = w.to_s + entry.to_s[0, 1]
      dict_size += 1

      w = entry
    end
    result
  end
end
