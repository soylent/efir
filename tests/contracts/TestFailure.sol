pragma solidity ^0.6.0;

contract TestFailure {
    function testFailure() public pure {
        require(false, "expected failure");
    }
}
