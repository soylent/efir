pragma solidity ^0.6.0;

contract TestErrors {
    function testException() pure public { TestErrors(0).testException(); }

    function testOutOfStack() pure public { testOutOfStack(); }
}
