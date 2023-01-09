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
     * Makes an offer to purchase a listing
     * @param _userAddress: wallet address of a user
     */
    function _getIdentityOfAUser(address _userAddress) private view returns (address){
        address userIdentity = identityRegistry.getIdentityOfAUser(_userAddress);
        require(userIdentity != address(0), "identity not exist");
        return userIdentity;
    }

     /**
     * Add a user to the social graph
     * @param _identity: the Identity smart contract address of the user
     */
    function _addUser(address _identity) private {
        require(_identity != address(0));
        require(users[_identity].identity == address(0));
        users[_identity].identity = _identity;
    }


    function register() external {
        address userIdentity = _getIdentityOfAUser(msg.sender);
        _addUser(userIdentity);
    }

    /**
     * Add a connection between two users in the social graph
     * @param _friendIdentity: the Identity address of a friend
     */
    function addConnection(
        address _friendIdentity
    ) userExist(_friendIdentity) external {
        address _userIdentity = _getIdentityOfAUser(msg.sender);
        require(_userIdentity != _friendIdentity, "same identity");
        users[_userIdentity].friends[_friendIdentity] = true;
        users[_friendIdentity].friends[_userIdentity] = true;
        users[_userIdentity].connectionImpact[_friendIdentity] = 1;
        users[_friendIdentity].connectionImpact[_userIdentity] = 1;
    }


    /**
     * Remove a connection between two users in the social graph
     * @param _friendIdentity: the Identity address of a friend
     */
    function removeConnection(address _friendIdentity) userExist(_friendIdentity) external {
        address _userIdentity = _getIdentityOfAUser(msg.sender);
        require(_userIdentity != _friendIdentity, "same identity");
        users[_userIdentity].friends[_friendIdentity] = false;
        users[_friendIdentity].friends[_userIdentity] = false;
        delete users[_userIdentity].connectionImpact[_friendIdentity];
        delete users[_friendIdentity].connectionImpact[_userIdentity];
    }

    /**
     * allow users to rate the well-being impact of their connections.
     * For example, users could rate their connections on a scale from 1 to 5, 
     * with 1 being a very negative impact on well-being and 5 being a very positive impact
     * @param _friendIdentity: the Identity address of the user's friend
     * @param _rating: rating score of the connection. Scale from 1 to 5.
     */
    function rateConnectionImpact(
        address _friendIdentity, 
        uint8 _rating
    ) userExist(_friendIdentity) public {
        address _userIdentity = _getIdentityOfAUser(msg.sender);
        require(_userIdentity != _friendIdentity, "same identity");
        require(identityRegistry.identityExists(_friendIdentity), "user's friend identity not exist");
        require(_rating >= 1 && _rating <= 5, "rating invalid");

        User storage user = users[_userIdentity];

        // Ensure that the caller and the friend are connected in the social graph
        require(user.friends[_friendIdentity] = true, "not friend");

        // Update the well-being impact rating for the connection
        user.connectionImpact[_friendIdentity] = _rating;
    }

    function isFriend(address _userIdentity, address _friendIdentity) external view returns (bool) {
        return users[_userIdentity].friends[_friendIdentity];
    }

    function getConnectionImpact(address _identity, address _friendIdentity) external view returns (uint256) {
        return users[_identity].connectionImpact[_friendIdentity];
    }

    
}