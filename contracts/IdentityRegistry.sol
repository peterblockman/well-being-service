// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;


contract IdentityRegistry {
    // map identity to exists
    mapping(address => bool) public identities;
    //　Map a user's wallet address to identity
    mapping(address => address) public userWalletToIdentity;


    /**
     * Add an identity
     * @param _userAddress: the user's wallet address
     * @param _identity: the Identity smart contract address of the user
     */
    function addIdentity( address _userAddress, address _identity) external {
        require(identities[_identity] == false, "identity exists");
        identities[_identity] = true;
        userWalletToIdentity[_userAddress] = _identity;
    }

    /**
     * Remove an identity
     * @param _identity: the Identity smart contract address of the user
     */
    function removeIdentity(address _identity) external {
        require(identities[_identity] == true, "identity not exists");
        identities[_identity] = false;
    }


    /**
     * Check if an identity exists
     * @param _identity: the Identity smart contract address of the user
     */
    function identityExists(address _identity) public view returns (bool){
        return identities[_identity];
    }

    /**
     * get identity of a user
     * @param _userAddress: the user's wallet address
     */
    function getIdentityOfAUser(address _userAddress) public view returns (address){
        return userWalletToIdentity[_userAddress];
    }

}