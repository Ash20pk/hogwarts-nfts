// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

error HogwartsNFT__WithdrawalFailed();

contract HogwartsNFT is VRFConsumerBaseV2, ERC721URIStorage, Ownable {
    // NFT variables
    mapping(uint256 => address) public s_requestIdToSender; // a mapping from requestId to the address that made that request
    mapping(address => House) public s_addressToHouse; // new mapping to map address to the house they got
    mapping(address => bool) private s_minted; // mapping a boolean to the address if they have already minted the NFT


    uint256 private s_tokenCounter;
    string[] internal houseTokenURIs = [
        "ipfs://QmXja2QBKsNW9qnw9kKfcm25rJTomwAVJUrXekYFJnVwbg/Gryffindor.json",
        "ipfs://QmXja2QBKsNW9qnw9kKfcm25rJTomwAVJUrXekYFJnVwbg/Hufflepuff.json",
        "ipfs://QmXja2QBKsNW9qnw9kKfcm25rJTomwAVJUrXekYFJnVwbg/Ravenclaw.json",
        "ipfs://QmXja2QBKsNW9qnw9kKfcm25rJTomwAVJUrXekYFJnVwbg/Slytherin.json"
    ]; // [Gryffindor, Hufflepuff, Ravenclaw, Slytherin]

    enum House {
        Gryffindor, // 0th item
        Hufflepuff, // 1st item
        Ravenclaw, // 2nd item
        Slytherin // 3rd item
    }

    // Chainlink VRF variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId; // get subscription ID from vrf.chain.link
    bytes32 private immutable i_keyHash;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    // Events
    event NftRequested(uint256 indexed requestId, address requester);
    event NftMinted(House house, address minter);
    event AlreadyMinted(bool s_minted, House house);

    constructor(
        address vrfCoordinatorV2Address,
        uint64 subId,
        bytes32 keyHash,
        uint32 callbackGasLimit
    )
        VRFConsumerBaseV2(vrfCoordinatorV2Address)
        ERC721("Hogwarts NFT", "HP")
    {
        s_tokenCounter = 0;

        // VRF variables 
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2Address);
        i_subscriptionId = subId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
    }

    function requestNFT() public payable returns (uint256 requestId) {
        
        // Check if user has already minted an NFT
        if (s_minted[msg.sender] == true) {
            revert("You are already in a house");
        }

        requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash, 
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        ); 

        s_requestIdToSender[requestId] = msg.sender; // map the caller to their respective requestIDs.

        // emit an event
        emit NftRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override
    {
        // Step 1 - figure out nftOwner
        address nftOwner = s_requestIdToSender[requestId]; // map the requestId to whoever sent the request for Randomness

        // Step 2 - mint the NFT
        uint256 tokenId = s_tokenCounter; // assign unique tokenId

        //select a house based on the random number
        uint256 randomNumber = (randomWords[0] % 4); // get a random number between 0 - 4 

        House house = House(randomNumber); // select a house

        //Map the house to the address of the requester
        address sender = s_requestIdToSender[requestId];
        s_addressToHouse[sender] = house;

        _safeMint(nftOwner, tokenId); // finally, mint the NFT using _safeMint function

        // set Token URI of that particular NFT
        _setTokenURI(tokenId, houseTokenURIs[uint256(house)]); // takes tokenID and tokenURI

        s_minted[s_requestIdToSender[requestId]] = true; // Mark user as having minted an NFT

        s_tokenCounter += 1; // increment the token count

        // emit event
        emit NftMinted(house, nftOwner);
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");

        if (!success) {
            revert HogwartsNFT__WithdrawalFailed();
        }
    }

    // View Functions

    function getTokenURIs(uint256 index) public view returns (string memory) {
        return houseTokenURIs[index];
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}