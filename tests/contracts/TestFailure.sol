// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestFailure {
    function testFailure() public pure {
        require(false, "expected failure");
    }
}
