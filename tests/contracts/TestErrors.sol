// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestErrors {
    function testException() pure public { TestErrors(address(0)).testException(); }

    function testOutOfStack() pure public { testOutOfStack(); }
}
