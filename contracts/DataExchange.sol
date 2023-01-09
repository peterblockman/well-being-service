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
    // All listings on the marketplace
    Listing[] public allListings;
    // All offers on the marketplace
    Offer[] public allOffers;
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
        require(_price > 0);

        uint256 listingId = listingIdCounter + 1;
        listingIdCounter++;
        Listing memory listing = Listing({
            seller: msg.sender, 
            description: _description, 
            price: _price, 
            decryptionKey: "", // decryptionKey only revealed after payment
            status: LisingtingStatus.ACTIVE
        });
        allListings.push(listing);

        listings[listingId] = listing;
    }
    
    function _getIdentityOfAUser(address userAddress) private view returns (address){
        address sellerIdentity = identityRegistry.getIdentityOfAUser(userAddress);
        require(sellerIdentity != address(0), "identity not exist");
        return sellerIdentity;
    }
    /**
     * Makes an offer to purchase a listing
     * @param _listingId: the id of a listing
     * @param _price: the offering price
     */
    function makeOffer(uint256 _listingId, uint256 _price) payable public {
        require(_listingId > 0 && _listingId <= allListings.length, "invalid _listingId");
        require(_price == msg.value && _price > 0, "invalid price");

        uint256 listingPrice = listings[_listingId].price;
        require(msg.value >= listingPrice, "offering price smaller than listing price");
        address sellerIdentity = _getIdentityOfAUser(msg.sender);
        require(sellerIdentity != listings[_listingId].seller, "you can not make offer to your listing");

        Offer memory offer = Offer({
            buyer: sellerIdentity, 
            listingId: _listingId, 
            price: _price, 
            status: OfferStatus.PENDING
        });

        offerIdCounter++;
        allOffers.push(offer);
        offers[offerIdCounter] = offer;

        listingToOffer[_listingId].push(offer);
    }

    /**
     * @notice this is a naive approach. Do not use it in production.
     * Release the decryption key
     * @param listingId: id of a listing
     */
    function _releaseDecryptionKey(uint256 listingId, bytes32 _decryptionKey) private {
        listings[listingId].decryptionKey = _decryptionKey;
    }

    /**
     * Accepts an offer to purchase a listing
     * @param _offerId: id of an offer
     * @param _decryptionKey: the encryption key for data to sell
     */
    function acceptOffer(uint256 _offerId, bytes32 _decryptionKey) public {
        require(_offerId > 0 && _offerId <= allOffers.length, "invalid _offerId");
        address buyerIdentity = _getIdentityOfAUser(msg.sender);

        Offer storage offer = offers[_offerId];
        require(offer.status == OfferStatus.PENDING, "invalid offer status");
        require(buyerIdentity != offer.buyer, "you can not accept your offer");
        require(listings[offer.listingId].seller == buyerIdentity, "does not have the permission");
        offer.status = OfferStatus.ACCEPTED;

        // update listing status
        listings[offer.listingId].status = LisingtingStatus.SOLD;

        // release decryptionKey
        // naive approach. Do not use it in production.
        _releaseDecryptionKey(offer.listingId, _decryptionKey);
    }

    /**
     * Releases payment for a listing from escrow
     * @param _offerId: id of an offer
     */
    function releasePayment(uint256 _offerId) public {
        require(_offerId > 0 && _offerId <= allOffers.length);
        Offer storage offer = offers[_offerId];
        require(offer.status == OfferStatus.ACCEPTED);

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
        require(offer.status == OfferStatus.PAYMENT_RELEASED);
        require(offer.buyer == sellerIdentity);

        (bool sent,) = sellerIdentity.call{value: offer.price}("");
        require(sent, "Failed to send Ether");

        // offer.status = OfferStatus.COMPLETED;
        listings[offer.listingId].status = LisingtingStatus.COMPLETED;
    }

    /**
     * get the encryption key to enc
     * @param _offerId: id of an offer
     */
    function getDecryptionKey(uint256 _offerId) external returns (bytes32) {
        Offer storage offer = offers[_offerId];
        require(offer.status == OfferStatus.PAYMENT_RELEASED, "payment not released");

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
