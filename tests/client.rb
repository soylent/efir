# frozen_string_literal: true

scope 'client' do
  client = Efir::Client.new(ENV.fetch('EFIR_URL'))

  test 'that it can send a request and return the response' do
    assert client.request('web3_sha3', '0x00').start_with?('0xbc')
  end

  test 'that it handles error responses' do
    assert_raise(Efir::Error) { client.request('web3_sha3') }
  end
ensure
  client&.close
end

test 'that it handles connection errors' do
  assert_raise(Efir::Error) do
    Efir::Client.new('http://127.0.0.1:65634', open_timeout: 1e-6)
  end
end

test 'that it checks network url' do
  assert_raise(Efir::Error) { Efir::Client.new('') }
  assert_raise(Efir::Error) { Efir::Client.new('`') }
end
