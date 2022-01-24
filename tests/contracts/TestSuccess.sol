pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

contract TestSuccess {
    function testSuccess() pure public {
        require(true, "expected success");
    }
}
