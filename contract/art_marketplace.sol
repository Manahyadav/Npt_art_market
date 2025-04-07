// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenizedArtMarketplace {
    string public name = "TokenizedArt";
    string public symbol = "TART";
    uint256 public totalSupply;
    uint256 public marketplaceFee = 2; // 2% fee

    struct Art {
        uint256 tokenId;
        address artist;
        string tokenURI;
        uint256 price;
    }

    mapping(uint256 => Art) public artCollection;
    mapping(address => uint256[]) public ownedTokens;
    mapping(uint256 => address) public tokenOwner;

    // Event for when an artwork is minted
    event ArtMinted(address indexed artist, uint256 tokenId, string tokenURI);

    // Event for when an artwork is purchased
    event ArtPurchased(address indexed buyer, uint256 tokenId, uint256 price);

    // Mint new artwork (NFT)
    function mintArt(string memory tokenURI, uint256 price) public {
        uint256 tokenId = totalSupply;
        artCollection[tokenId] = Art(tokenId, msg.sender, tokenURI, price);
        tokenOwner[tokenId] = msg.sender;
        ownedTokens[msg.sender].push(tokenId);
        totalSupply++;

        emit ArtMinted(msg.sender, tokenId, tokenURI);
    }

    // Purchase artwork (NFT)
    function purchaseArt(uint256 tokenId) public payable {
        Art storage artwork = artCollection[tokenId];
        require(artwork.price > 0, "This artwork is not for sale.");
        require(msg.value >= artwork.price, "Insufficient funds to purchase the art.");

        address seller = artwork.artist;
        uint256 fee = (artwork.price * marketplaceFee) / 100;
        uint256 sellerAmount = artwork.price - fee;

        // Transfer the marketplace fee
        payable(address(this)).transfer(fee);

        // Transfer the remaining funds to the seller
        payable(seller).transfer(sellerAmount);

        // Transfer the artwork NFT to the buyer
        tokenOwner[tokenId] = msg.sender;

        // Remove token from seller's list and add it to buyer's list
        removeTokenFromOwner(seller, tokenId);
        ownedTokens[msg.sender].push(tokenId);

        emit ArtPurchased(msg.sender, tokenId, artwork.price);
    }

    // Update the price of an artwork
    function updatePrice(uint256 tokenId, uint256 newPrice) public {
        require(tokenOwner[tokenId] == msg.sender, "Only the owner can update the price.");
        artCollection[tokenId].price = newPrice;
    }

    // Helper function to remove token from seller's list
    function removeTokenFromOwner(address owner, uint256 tokenId) internal {
        uint256[] storage tokens = ownedTokens[owner];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
    }

    // Withdraw contract balance (only for the marketplace owner)
    function withdrawBalance() public {
        // The contract owner should withdraw the balance
        // For now, this is accessible by anyone, but you can add access control logic.
        payable(address(this)).transfer(address(this).balance);
    }

    // Fetch list of tokens owned by a specific address
    function getOwnedTokens(address owner) public view returns (uint256[] memory) {
        return ownedTokens[owner];
    }

    // Fetch token URI
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return artCollection[tokenId].tokenURI;
    }
}
