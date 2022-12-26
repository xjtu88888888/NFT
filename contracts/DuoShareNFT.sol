//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract DouShareNFT is ERC721, Ownable {
    uint256 public mintPrice; 
    uint256 public totalSupply; 
    uint256 public maxSupply;
    uint256 private reservednft;   
    uint256 public maxPerWallet; 
    bool public isPublicMintEnabled;
    string internal baseTokenUri;
    bool public blindBoxOpened = false;
    string private blindTokenURI;         
    mapping(address => uint256) public walletMints; 
    mapping(address => bool) private isBlacklisted; 
    mapping(address => bool) private isWhitelisted; 
    constructor() payable ERC721("DouShareNFT", "Doushare") {
        reservednft = 3;        
        mintPrice = 0.001 ether;
        totalSupply = 0;
        maxSupply = 10;
        maxPerWallet = 2;
        blindTokenURI = "https://gateway.pinata.cloud/ipfs/Qmec5eVJGqB9eJqhRQMDEfspx8HzxKy3S12zntBcEpMhFo/0";   
    }
    
    //default settings for tax and trading markets.
    function contractURI() public view returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmRH4D24RJgdb1uUJ4th1d7DFRhsnGusRDXYqzc2DtXqi4";
    }


     function setIsPublicMintEnabled(bool isPublicMintEnabled_)
        external
        onlyOwner
    {
        isPublicMintEnabled = isPublicMintEnabled_;
    }   

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }
    
    //set blind boxstatus
    function setBlindBoxOpened(bool _status) 
        public
        onlyOwner
    {
        blindBoxOpened = _status;
    }    

    // blindbox open or not?
    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId_), "Token dose not exist!");
        if (blindBoxOpened) {
            //string memory baseURI = _baseURI();
            return
                bytes(baseTokenUri).length > 0
                    ? string(
                        abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json")
                    )
                    : "Admin have not set BaseURI !";
        } else {
            return blindTokenURI;
        }       
    }

    // Just in case Eth does some crazy stuff,count in Wei :)
    function setNewMintPrice(uint256 _newPrice) public onlyOwner() {
        mintPrice = _newPrice  ;
    }


    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance
        }("");
        require(success, "withdraw failed!");
    }

    // We do have giveAway,but not too much :)
    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= reservednft, "Exceeds reserved supply" );
        
        for(uint256 j=0; j < _amount; j++){
            uint256 newTokenId2 = totalSupply + 1;           
            totalSupply++;
            _safeMint( _to, newTokenId2 );
        }
        reservednft -= _amount;
    }

    //Set blacklist wallet
    function setBlacklistAddress(address account, bool value) public onlyOwner() {
        isBlacklisted[account] = value;        
    }

    //Set whitelist wallet
    function setWhitelistAddress(address account, bool value) public onlyOwner() {
        isWhitelisted[account] = value;        
    }

    function mint(uint256 quantity_) public payable {
        require(!isBlacklisted[msg.sender], "Blacklisted Address");      

       // require(isPublicMintEnabled, "minting not enabled");

        if(!isPublicMintEnabled)
            {
            require(isWhitelisted[msg.sender], "Not On the Whitelist.");     
            }

        require(msg.value >= quantity_ * mintPrice, "wrong mint value");
        require(totalSupply + quantity_ <= maxSupply-reservednft, "sold out");   
             
		uint256 quantity_1 = walletMints[msg.sender]+ quantity_;
        require(quantity_1 <= maxPerWallet, "exceed max wallet");
        for (uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }
    }
}