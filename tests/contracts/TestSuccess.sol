pragma solidity ^0.6.0;

contract TestSuccess {
    function testSuccess() pure public {
        require(true, "expected success");
    }
}
