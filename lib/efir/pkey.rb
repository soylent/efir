# frozen_string_literal: true

require 'openssl'
require 'efir/bytes'

class Efir
  class PKey
    def initialize(key)
      @key = OpenSSL::PKey::EC.new('secp256k1')
      key_hex = key.start_with?('0x') ? key[2..-1] : key
      begin
        @key.private_key = OpenSSL::BN.new(key_hex, 16)
      rescue OpenSSL::BNError
        raise ArgumentError, 'invalid key'
      end
      @key.public_key = @key.group.generator.mul(@key.private_key)
      begin
        @key.check_key
      rescue OpenSSL::PKey::ECError
        raise ArgumentError, 'invalid key'
      end
    end

    def public_key
      @key.public_key.to_octet_string(:uncompressed)[1..-1]
    end

    def sign(data)
      sig_asn1 = @key.dsa_sign_asn1(data)

      order = @key.group.order

      r, s = OpenSSL::ASN1.decode(sig_asn1).value.map!(&:value)
      s = order - s if s > (order >> 1)

      rid = recid(data, r, s)

      [r, s, rid]
    end

    private

    def recid(data, r, s)
      xy1_compressed = Bytes.bytes(r, size: 32).prepend("\x02")
      xy1 = OpenSSL::PKey::EC::Point.new(@key.group, xy1_compressed)

      data_hex = Bytes.hex(data, prefix: false)
      z = OpenSSL::BN.new(data_hex, 16)

      ir = r.mod_inverse(@key.group.order)
      pk1 = xy1.mul(s, -z).mul(ir)

      pk1 == @key.public_key ? 0 : 1
    end
  end
end
