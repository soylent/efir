# frozen_string_literal: true

class Efir
  module Bytes
    NONE = "\x80".b
    private_constant :NONE

    def self.rlp(val)
      return NONE if val == 0
      if val.respond_to?(:each)
        res = val.reduce(+'') { |r, v| r << rlp(v) }
        rlp_len(res.bytesize, 0xC0) << res
      else
        val = bytes(val) if val.respond_to?(:to_int)
        if val.bytesize == 1 && val[0].ord < 0x80
          val
        else
          rlp_len(val.bytesize, 0x80) << val
        end
      end
    end

    def self.rlp_len(size, offset)
      if size < 56
        (size + offset).chr
      else
        sizeb = bytes(size)
        (sizeb.size + offset + 55).chr << sizeb
      end
    end

    private_class_method :rlp_len

    def self.hex(str, prefix: true)
      res = str.unpack1('H*')
      prefix ? res.prepend('0x') : res
    end

    def self.unhex(str)
      str = str.start_with?('0x') ? str[2..-1] : str
      [str].pack('H*')
    end

    def self.bytes(int, size: nil, padding: "\x00")
      hex = int.to_s(16)
      hex.prepend('0') if hex.size.odd?
      res = [hex].pack('H*')
      size ? res.rjust(size, padding) : res
    end
  end
end
