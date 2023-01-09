// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

import "https://github.com/ERC725Alliance/ERC725/blob/develop/implementations/contracts/custom/OwnableUnset.sol";
import "https://github.com/ERC725Alliance/ERC725/blob/develop/implementations/contracts/ERC725YCore.sol";
import "./IdentityRegistry.sol";

contract Identity is ERC725YCore {
	IdentityRegistry identityRegistry;

    /**
     * @notice Sets the owner of the contract
     * @param _newOwner the owner of the contract. It is the user's wallet smart contract
     * @param _identityRegistry the address of the IdentityRegistry smart contract
     * @param _name user'S first name
     * @param _age user's age
     */
    constructor(address _newOwner, address _identityRegistry, string memory _name, uint256 _age) {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        OwnableUnset._setOwner(_newOwner);
        // set name and age
        setData(keccak256(abi.encodePacked("name")), bytes(_name));
        setData(keccak256(abi.encodePacked("age")), abi.encodePacked(_age));
        // add identity
        identityRegistry = IdentityRegistry(_identityRegistry);
        identityRegistry.addIdentity(_newOwner, address(this));
    }
}