# frozen_string_literal: true

require 'securerandom'

pkey = Efir::PKey.new(ENV.fetch('EFIR_KEY'))

test 'that it can derive public key from private key' do
  pk = pkey.public_key

  assert_equal 64, pk.bytesize
end

test 'that it can sign data and generate a recovery id' do
  r, s, recid = pkey.sign(SecureRandom.bytes(8))

  assert r > 0
  assert s > 0
  assert recid == 0 || recid == 1
end

test 'that it checks private key' do
  assert_raise(ArgumentError) { Efir::PKey.new('m') }
  assert_raise(ArgumentError) { Efir::PKey.new('0') }
end
