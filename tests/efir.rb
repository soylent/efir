# frozen_string_literal: true

require 'stringio'
require 'pathname'
require 'securerandom'

scope 'contracts' do
  example = Pathname(__dir__).join('contracts', 'Example.json')
  init = JSON.parse(example.read).dig('contracts', 'Example.sol:Example', 'bin')

  test 'that it can create a contract and call a function' do
    efir = Efir.new(url: ENV.fetch('EFIR_URL'), key: ENV.fetch('EFIR_KEY'))

    # Invalid contract bytecode
    assert_raise(Efir::Error) { efir.send_tx('0x01') }

    # Valid contract bytecode
    contract_receipt = efir.send_tx(init)

    addr = contract_receipt['contractAddress']
    assert addr, "receipt: #{contract_receipt}"

    # Invalid function call
    xfunc = SecureRandom.bytes(6)
    assert_raise(Efir::Error) { efir.call(addr, xfunc) }

    # Valid function call
    call_receipt = efir.call(addr, 'hello')
    assert call_receipt, "receipt: #{call_receipt}"
  ensure
    efir&.close
  end
end

test 'that it checks chain id' do
  assert_raise(ArgumentError) { Efir.new(chain_id: 'x') }
  assert_raise(ArgumentError) { Efir.new(chain_id: '-1') }
end
