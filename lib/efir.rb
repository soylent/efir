# frozen_string_literal: true

require 'efir/client'
require 'efir/bytes'
require 'efir/pkey'

class Efir
  Error = Class.new(StandardError)
  TimeoutError = Class.new(Error)
  RevertError = Class.new(Error)

  Tx = Struct.new(
    :nonce,
    :gas_price,
    :gas_limit,
    :to,
    :value,
    :init_or_data,
    :v,
    :r,
    :s,
    keyword_init: true
  )

  private_constant :Tx

  def initialize(url:, key:, chain_id: nil)
    @client = Client.new(url)
    @pkey = PKey.new(key)
    @chain_id = chain_id(chain_id)
    @gas_price = suggested_gas_price
    @address = address
  end

  def send_tx(init_or_data_hex, to: nil, value: 0, timeout: 60)
    tx = Tx.new(
      nonce: tx_count,
      gas_price: @gas_price,
      gas_limit: gas_limit(to, init_or_data_hex),
      to: to ? Bytes.unhex(to) : 0,
      value: value,
      init_or_data: Bytes.unhex(init_or_data_hex),
      v: @chain_id,
      r: 0,
      s: 0
    )

    # Sign
    msg_rlp = Bytes.rlp(tx.values)
    msg_hash = keccak256(msg_rlp, unhex: true)

    r, s, recid = @pkey.sign(msg_hash)

    tx.v = @chain_id * 2 + 35 + recid
    tx.r = r
    tx.s = s

    # Send
    tx_rlp = Bytes.rlp(tx.values)
    tx_rlp_hex = Bytes.hex(tx_rlp)
    tx_hash = @client.request('eth_sendRawTransaction', tx_rlp_hex)

    receipt = tx_receipt(tx_hash, timeout: timeout)

    status = receipt.fetch('status')
    raise Error, 'transaction failure' if status == '0x0' # Failure

    receipt
  end

  def call(addr, func)
    sig_hash4 = keccak256("#{func}()")[0, 10]

    send_tx(sig_hash4, to: addr)
  end

  def close
    @client.close
  end

  private

  def chain_id(val)
    val ||= @client.request('eth_chainId').to_i(16)
    begin
      cid = Integer(val)
    rescue ArgumentError
      raise Error, "invalid chain id: #{val.inspect}"
    end
    raise Error, "invalid chain id: #{val.inspect}" unless cid.positive?
    cid
  end

  def suggested_gas_price
    @client.request('eth_gasPrice').to_i(16)
  end

  def gas_limit(to, data)
    data = data.prepend('0x') unless data.start_with?('0x')

    begin
      @client.request('eth_estimateGas', to: to, data: data).to_i(16)
    rescue Error
      reason_hex = @client.request('eth_call', { to: to, data: data }, 'latest')
      revert_string = decode_revert_string(reason_hex)
      raise RevertError, revert_string if revert_string
      raise
    end
  end

  def address
    pk_hash = keccak256(@pkey.public_key)

    pk_hash[-40..-1].prepend('0x')
  end

  def tx_count(block: 'latest')
    cnt = @client.request('eth_getTransactionCount', @address, block)
    cnt.to_i(16)
  end

  def keccak256(str, unhex: false)
    str_hex = Bytes.hex(str)
    hash_hex = @client.request('web3_sha3', str_hex)

    unhex ? Bytes.unhex(hash_hex) : hash_hex
  end

  def tx_receipt(tx_hash, timeout:)
    elapsed_time = 0
    loop do
      receipt = @client.request('eth_getTransactionReceipt', tx_hash)
      return receipt if receipt
      raise TimeoutError, "transaction timeout: #{tx_hash}" if elapsed_time >= timeout
      elapsed_time += sleep(5)
    end
  end

  def decode_revert_string(hex)
    return unless hex.bytesize % 64 == 10
    # 0x08c379a0 is keccak256("Error(string)")[0, 10]
    return unless hex.start_with?('0x08c379a0')

    offset = hex[10, 64].to_i(16)
    len = hex[74, 64].to_i(16)
    str = hex[74 + offset * 2, len * 2]

    Bytes.unhex(str)
  end
end
