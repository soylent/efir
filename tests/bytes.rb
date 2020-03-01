# encoding: binary
# frozen_string_literal: true

test 'that it can rlp encode' do
  inp_out = [
    [0x0, "\x80"],
    [0x7F, "\x7F"],
    [0x80, "\x81\x80"],
    ["\x00", "\x00"],
    ["\x7F", "\x7F"],
    ["\x80" * 0, "\x80"],
    ["\x80" * 1, "\x81\x80"],
    ["\x80" * 55, "\xb7" + "\x80" * 55],
    ["\x80" * 56, "\xb8\x38" + "\x80" * 56],
    ["\x80" * 256, "\xb9\x01\x00" + "\x80" * 256],
    [[0], "\xC1\x80"],
    [["\x7F"] * 0, "\xC0"],
    [["\x7F"] * 1, "\xC1\x7F"],
    [["\x7F"] * 55, "\xF7" + "\x7F" * 55],
    [["\x7F"] * 56, "\xF8\x38" + "\x7F" * 56],
    [["\x7F"] * 256, "\xF9\x01\x00" + "\x7F" * 256],
    [[["\x7F"]], "\xC2\xC1\x7F"]
  ]

  inp_out.each do |inp, out|
    res = Efir::Bytes.rlp(inp)

    assert_equal(out, res)
  end
end

test 'that it can hex encode and decode a value' do
  assert_equal '0x00', Efir::Bytes.hex("\x00")
  assert_equal '00', Efir::Bytes.hex("\x00", prefix: false)
  assert_equal "\x00", Efir::Bytes.unhex('0x00')
  assert_equal '', Efir::Bytes.unhex('0x')
  assert_equal 'x', Efir::Bytes.unhex(Efir::Bytes.hex('x'))
end

test 'that it convert an int to a byte string' do
  assert_equal "\x00", Efir::Bytes.bytes(0)
  assert_equal "\x0A", Efir::Bytes.bytes(10)
  assert_equal "\x01\x00", Efir::Bytes.bytes(256)
  assert_equal "\x00\x01", Efir::Bytes.bytes(1, size: 2)
end
