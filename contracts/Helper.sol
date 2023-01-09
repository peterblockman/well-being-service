// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;


contract Helper  {
    function hash(string memory _string) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_string));
    }
}