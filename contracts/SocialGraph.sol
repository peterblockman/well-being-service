// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./IdentityRegistry.sol";

contract SocialGraph {

    modifier userExist(address _identity) {
        require(users[_identity].identity != address(0), "user not exist");
        _;
    }

    // A user in the social graph
    struct User {
        // The identity of the user 
        // this is the address of Identity smart contract instance
        // deployed for each user
        address identity;
        // friends list
        mapping(address => bool) friends;
        // connection strength with each friend
        mapping(address => uint256) connectionImpact;
    }

    // map identity to user
    mapping(address => User) public users;

    // the IdentityRegistry smart contract
    IdentityRegistry identityRegistry;

    constructor(address _identityRegistry) {
        identityRegistry = IdentityRegistry(_identityRegistry);
    }

     /**
     * Add a user to the social graph
     * @param _identity: the Identity smart contract address of the user
     */
    function addUser(address _identity) public {
        require(_identity != address(0));
        require(users[_identity].identity == address(0));
        users[_identity].identity = _identity;
    }

    /**
     * Add a connection between two users in the social graph
     * @param _userAIdentity: the Identity address of _userA
     * @param _userBIdentity: the Identity address of _userB
     */
    function addConnection(
        address _userAIdentity,
        address _userBIdentity
    ) userExist(_userAIdentity) userExist(_userBIdentity) public {
        require(_userAIdentity != _userBIdentity);
        users[_userAIdentity].friends[_userBIdentity] = true;
        users[_userBIdentity].friends[_userAIdentity] = true;
        users[_userAIdentity].connectionImpact[_userBIdentity] = 1;
        users[_userBIdentity].connectionImpact[_userAIdentity] = 1;
    }

    /**
     * Remove a connection between two users in the social graph
     * @param _userAIdentity: the Identity address of _userA
     * @param _userBIdentity: the Identity address of _userB
     */
    function removeConnection(address _userAIdentity, address _userBIdentity) userExist(_userAIdentity) userExist(_userBIdentity) public {
        require(_userAIdentity != _userBIdentity);
        users[_userAIdentity].friends[_userBIdentity] = false;
        users[_userBIdentity].friends[_userAIdentity] = false;
        delete users[_userAIdentity].connectionImpact[_userBIdentity];
        delete users[_userBIdentity].connectionImpact[_userAIdentity];
    }

    /**
     * allow users to rate the well-being impact of their connections.
     * For example, users could rate their connections on a scale from 1 to 5, 
     * with 1 being a very negative impact on well-being and 5 being a very positive impact
     * @param _identity: the Identity address of the user
     * @param _friendIdentity: the Identity address of the user's friend
     * @param _rating: rating score of the connection. Scale from 1 to 5.
     */
    function rateConnectionImpact(
        address _identity,
        address _friendIdentity, 
        uint8 _rating
    ) userExist(_identity) userExist(_friendIdentity) public {
        require(identityRegistry.identityExists(_identity), "user identity not exist");
        require(identityRegistry.identityExists(_friendIdentity), "user's friend identity not exist");
        require(_rating >= 1 && _rating <= 5, "rating invalid");

        User storage user = users[_identity];

        // Ensure that the caller and the friend are connected in the social graph
        require(user.friends[_friendIdentity] = true, "not friend");

        // Update the well-being impact rating for the connection
        user.connectionImpact[_friendIdentity] = _rating;
    }

    function isFriend(address _identity, address _friendIdentity) external view returns (bool) {
        return users[_identity].friends[_friendIdentity];
    }

    function getConnectionImpact(address _identity, address _friendIdentity) external view returns (uint256) {
        return users[_identity].connectionImpact[_friendIdentity];
    }
}