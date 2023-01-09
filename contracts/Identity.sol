// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

import "https://github.com/ERC725Alliance/ERC725/blob/develop/implementations/contracts/custom/OwnableUnset.sol";
import "https://github.com/ERC725Alliance/ERC725/blob/develop/implementations/contracts/ERC725YCore.sol";
import "./IdentityRegistry.sol";

contract Identity is ERC725YCore {
	IdentityRegistry identityRegistry;

    bytes32 public nameKey;
    bytes32 public ageKey;
    /**
     * @notice Sets the owner of the contract
     * @param newOwner the owner of the contract. It is the user's wallet smart contract
     */
    constructor(address newOwner, address identityRegistry_, string memory name, uint256 age) {
        // the user's wallet address
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        OwnableUnset._setOwner(newOwner);
        setData(keccak256(abi.encodePacked("name")), bytes(name));
        setData(keccak256(abi.encodePacked("age")), abi.encodePacked(age));
        nameKey = hash("name");
        ageKey = hash("age");
        identityRegistry = IdentityRegistry(identityRegistry_);
        identityRegistry.addIdentity(newOwner, address(this));
    }
    function hash(string memory _string) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_string));
    }
}