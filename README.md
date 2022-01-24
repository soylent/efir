# efir

Easy way to test and deploy Ethereum contracts.

### Write a contract and tests

```solidity
// Echo.sol

contract Echo {
   function back(uint val) pure public returns (uint) { return val; }
}

contract TestEcho {
   function testThatItCanEchoBackNumbers() public {
       Echo echo = new Echo();
       require(echo.back(1) == 1, "mismatch");
   }
}
```

Test contract names must start with "Test", e.g. `class TestEcho { ... }`.

Test function names must start with "test", e.g. `function testThatItWorks() { ... }`.

### Start your local Ethereum node

* openethereum

      openethereum --chain dev --jsonrpc-cors all

* geth

  Create a developer account from a private key.
  The first account in your keystore will be pre-funded.

      echo "4d5db4107d237df6a3d58ee5f70ae63d73d7658d4026f2eefd2f204c81682cb7" > keyfile.txt
      geth account import --password /dev/null --keystore devkeystore keyfile.txt

  Start geth:

      geth --dev --http --keystore devkeystore

* ganache-cli

      ganache --wallet.accounts 0x4d5db4107d237df6a3d58ee5f70ae63d73d7658d4026f2eefd2f204c81682cb7,100000000000000000000

### Compile and run your tests

    solc --combined-json=abi,bin Echo.sol | efir --test

By default, efir reads the `.env` file to get private key and node URL if the
file exists. Otherwise, it uses the following settings:

    EFIR_KEY=4d5db4107d237df6a3d58ee5f70ae63d73d7658d4026f2eefd2f204c81682cb7
    EFIR_URL=http://127.0.0.1:8545

Please see the Configuration section for more details.

### Deploy a contract

To deploy a contract to your local Ethereum chain:

    efir --deploy Echo Echo.json > echo-local.json

To deploy a contract to Mainnet or any other network, add your private key and
gateway URL to `.env.mainnet`:

    EFIR_KEY=YOUR-PRIVATE-KEY
    EFIR_URL=https://mainnet.infura.io/v3/YOUR-PROJECT-ID

And then run:

    efir --env .env.mainnet --deploy Echo Echo.json > echo-mainnet.json

The JSON output contains the contract address and ABI, so you can easily use it
in your app:

```js
// web3js example

import { address, abi } from "./echo-local.json";

var echo = new web3.eth.Contract(abi, address);

echo.methods.back(7).call(function(error, result) {
  console.log(result); // Outputs 7
});
```

## Installation

    gem install efir

Alternative secure installation method:

1. Add trusted certificate:

       curl -O https://raw.githubusercontent.com/soylent/efir/master/efir.pem
       gem cert --add efir.pem

1. Install efir:

       gem install efir -P HighSecurity

## Configuration

You can set the following environment variables to configure efir.

You can also store them in a `.env` file and use the `--env` option to point to
it.

| key | desc |
|---|---|
| EFIR_KEY | Private key in hex, 0x prefix is optional. Default: `4d5db4107d237df6a3d58ee5f70ae63d73d7658d4026f2eefd2f204c81682cb7` |
| EFIR_URL | Ethereum node URL. Default: `http://127.0.0.1:8545` |
| EFIR_CHAIN_ID | Chain id in base 10. If omitted, efir will send an `eth_chainId` request to get it. If you set a wrong chain id, you will get a misleading error message: "invalid sender" |

Commonly used chains:

| EFIR_CHAIN_ID | chain |
|---|---|
| 1 | Mainnet |
| 3 | Ropsten |
| 4 | Rinkeby |
| 5 | Goerli |
| 17 | Parity dev chain |
| 42 | Kovan |
| 1337 | Geth or Ganache dev chain |

## Development

Pull requests are welcome.

1. Start a local Ethereum node. Please see the "Start your local Ethereum node"
   section.

2. Compile test contracts (requires solc installed):

       rake -C tests/contracts

3. Install development dependencies and run tests:

       gem install cutest -v 1.2.3
       ./test
