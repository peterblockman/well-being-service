// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

import "./IdentityRegistry.sol";

contract DataExchange {
    enum LisingtingStatus{ ACTIVE, SOLD, KEY_RELEASED, COMPLETED }
    enum OfferStatus{ PENDING, ACCEPTED, PAYMENT_RELEASED, COMPLETED}

    // A listing in the market place
    struct Listing {
        // Seller address (an identity smart contract address)
        address seller;
        // The type of data being sold
        string description;
        // The price of the data
        uint256 price;
        // The decryption key for the data (stored off-chain)
        bytes32 decryptionKey;
        // The current status of the listing 
        LisingtingStatus status;
    }

    // An offer to purchase data
    struct Offer {
        // The address of the user who made the offer (an identity smart contract address)
        address buyer;
        // The listing being purchased
        uint256 listingId;
        // The price offered for the data
        uint256 price;
        // The current status of the offer (pending, accepted, etc.)
        OfferStatus status;
    }

    // Reputation score for a user
    struct Reputation {
        // The address of the user
        address user;
        // The user's reputation score
        uint256 score;
        // The number of transactions the user has participated in
        uint256 numTransactions;
    }
  
    // Map listing ID to listing
    mapping (uint256 => Listing) public listings;
    // Map offer ID to offer
    mapping (uint256 => Offer) public offers;
    // Map listing id to offer array
    mapping (uint256 => Offer[]) public listingToOffer;
    // Map user address to reputation score
    mapping (address => Reputation) public reputations;
    // next listing id
    uint256 public listingIdCounter;
    // next offer Id
    uint256 public offerIdCounter;

   // the IdentityRegistry smart contract
    IdentityRegistry identityRegistry;

    constructor(address _identityRegistry) {
        identityRegistry = IdentityRegistry(_identityRegistry);
    }

     /**
     * Creates a new listing on the marketplace
     * @param _description: the description of data
     * @param _price: the listing price
     */
    function createListing(string memory _description, uint256 _price) public {
        require(_price > 0, "invalid price");
        address sellerIdentity = _getIdentityOfAUser(msg.sender);

        uint256 listingId = listingIdCounter + 1;
        listingIdCounter++;
        Listing memory listing = Listing({
            seller: sellerIdentity, 
            description: _description, 
            price: _price, 
            decryptionKey: "", // decryptionKey only revealed after payment
            status: LisingtingStatus.ACTIVE
        });

        listings[listingId] = listing;
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
     * Makes an offer to purchase a listing
     * @param _listingId: the id of a listing
     * @param _price: the offering price
     */
    function makeOffer(uint256 _listingId, uint256 _price) payable public {
        require(_listingId > 0 && _listingId <= listingIdCounter, "invalid _listingId");
        require(_price == msg.value && _price > 0, "invalid price");

        require(msg.value >= listings[_listingId].price, "offering price smaller than listing price");
        address buyerIdentity = _getIdentityOfAUser(msg.sender);
        require(buyerIdentity != listings[_listingId].seller, "you can not make offer to your listing");

        Offer memory offer = Offer({
            buyer: buyerIdentity, 
            listingId: _listingId, 
            price: _price, 
            status: OfferStatus.PENDING
        });

        offerIdCounter++;
        offers[offerIdCounter] = offer;

        listingToOffer[_listingId].push(offer);
    }

    
    /**
     * Accepts an offer to purchase a listing
     * @param _offerId: id of an offer
     */
    function acceptOffer(uint256 _offerId) public {
        require(_offerId > 0 && _offerId <= offerIdCounter, "invalid _offerId");
        address sellerIdentity = _getIdentityOfAUser(msg.sender);

        Offer storage offer = offers[_offerId];
        require(offer.status == OfferStatus.PENDING, "invalid offer status");
        require(sellerIdentity != offer.buyer, "you can not accept your offer");
        require(listings[offer.listingId].seller == sellerIdentity, "does not have the permission");
        // update offer status
        offer.status = OfferStatus.ACCEPTED;

        // update listing status
        listings[offer.listingId].status = LisingtingStatus.SOLD;
    }

    /**
     * @notice this is a naive approach. Do not use it in production.
     * Release the decryption key
     * @param _offerId: id of an offer
     * @param _decryptionKey: the encryption key for the data 
     */
    function releaseDecryptionKey(uint256 _offerId, bytes32 _decryptionKey) external {
        address sellerIdentity = _getIdentityOfAUser(msg.sender);
        Offer memory offer = offers[_offerId];
        require(offer.status == OfferStatus.PAYMENT_RELEASED, "invalid offer status");

        require(listings[offer.listingId].seller == sellerIdentity, "does not have permission");
        listings[offer.listingId].decryptionKey = _decryptionKey;
        listings[offer.listingId].status = LisingtingStatus.KEY_RELEASED;

    }


    /**
     * Releases payment for a listing from escrow
     * @param _offerId: id of an offer
     */
    function releasePayment(uint256 _offerId) public {
        require(_offerId > 0 && _offerId <= offerIdCounter, "invalid _offerId");
        Offer storage offer = offers[_offerId];
        require(offer.status == OfferStatus.ACCEPTED, "invalid offer status");
        address buyerIdentity = _getIdentityOfAUser(msg.sender);
        require(buyerIdentity == offer.buyer, "do not have permission");

        Reputation storage reputation = reputations[offer.buyer];
        reputations[offer.buyer].score = reputation.score + 1;
        reputations[offer.buyer].numTransactions = reputation.numTransactions + 1;


        offer.status = OfferStatus.PAYMENT_RELEASED;
    }

    /**
     * withdraw payment after the payment accepted
     * @param _offerId: id of an offer
     */
    function withdrawPayment(uint256 _offerId) external {
        address sellerIdentity = _getIdentityOfAUser(msg.sender);
        
        Offer memory offer = offers[_offerId];
        require(offer.status == OfferStatus.PAYMENT_RELEASED, "invalid offer status");
        require( listings[offer.listingId].seller == sellerIdentity, "do not have permission");

        (bool sent,) = msg.sender.call{value: offer.price}("");
        require(sent, "Failed to send Ether");

        listings[offer.listingId].status = LisingtingStatus.COMPLETED;
    }

    /**
     * get the encryption key to enc
     * @param _offerId: id of an offer
     */
    function getDecryptionKey(uint256 _offerId) external returns (bytes32) {
        Offer storage offer = offers[_offerId];
        require(offer.status == OfferStatus.PAYMENT_RELEASED || offer.status == OfferStatus.COMPLETED , "payment not released");
        address buyerIdentity = _getIdentityOfAUser(msg.sender);
        require(buyerIdentity == offer.buyer, "do not have permission");

        offer.status = OfferStatus.COMPLETED;

        return listings[offer.listingId].decryptionKey;
    }

    /**
     * Returns a list of all offers made on a particular listing
     * @param _listingId: id of an listing
     */
    function getOffersOfAListing(uint256 _listingId) public view returns (Offer[] memory) {
        return listingToOffer[_listingId];
    }

}
