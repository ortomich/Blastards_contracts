// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";
import "./IBlast.sol";

contract Blastards is ERC721A, Ownable {

    /// ============ STORAGE ============

    address private constant BLAST = 0x4300000000000000000000000000000000000002;

    string private baseURIUnrevealed;
    string private baseURIRevealed;
    bool private revealed;

    uint256 constant public MAX_SUPPLY = 5000;

    uint256 constant public WL_PRICE = 0.014 ether;
    uint256 constant public ACTIVE_PRICE = 0.016 ether;
    uint256 constant public PUBLIC_PRICE = 0.018 ether;

    uint256 public saleStartTimestampWL;
    uint256 public saleStartTimestampActive;
    uint256 public saleStartTimestampPublic;

    mapping(address => uint256) public mintedCount;

    bytes32 public merkleRootWL;
    bytes32 public merkleRootActive;

    /// ============ CONSTRUCTOR ============

    constructor(
        uint256 _saleStartTimestampWL,
        uint256 _saleStartTimestampActive,
        uint256 _saleStartTimestampPublic,
        string memory _baseURIUnrevealed,
        bytes32 _merkleRootWL,
        bytes32 _merkleRootActive
    ) ERC721A("BLASTARDS", "BLRD") Ownable(msg.sender) {
        // IBlast(BLAST).configureAutomaticYield();
        // IBlast(BLAST).configureClaimableGas();

        saleStartTimestampWL = _saleStartTimestampWL;
        saleStartTimestampActive = _saleStartTimestampActive;
        saleStartTimestampPublic = _saleStartTimestampPublic;

        baseURIUnrevealed = _baseURIUnrevealed;

        merkleRootWL = _merkleRootWL;
        merkleRootActive = _merkleRootActive;
        _mint(msg.sender, 200);
    }

    /// ============ MAIN ============

    function mintWL(bytes32[] memory _merkleproof) public payable {
        require(msg.sender == tx.origin, "No contracts");
        require(block.timestamp >= saleStartTimestampWL, "WL sale has not started");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleproof, merkleRootWL, leaf), "Merkle proof verification failed");

        require(mintedCount[msg.sender] == 0, "Quantity must be less than max mint per wallet");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Quantity must be less than max supply");
        require(msg.value >= WL_PRICE, "Ether value sent is not correct");

        mintedCount[msg.sender] += 1;
        _mint(msg.sender, 1);
    }

    function mintActive(bytes32[] memory _merkleproof) public payable {
        require(msg.sender == tx.origin, "No contracts");
        require(block.timestamp >= saleStartTimestampActive, "Active sale has not started");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleproof, merkleRootActive, leaf), "Merkle proof verification failed");

        require(mintedCount[msg.sender] == 0, "Quantity must be less than max mint per wallet");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Quantity must be less than max supply");
        require(msg.value >= ACTIVE_PRICE, "Ether value sent is not correct");

        mintedCount[msg.sender] += 1;
        _mint(msg.sender, 1);
    }

    function mintPublic() public payable {
        require(msg.sender == tx.origin, "No contracts");
        require(block.timestamp >= saleStartTimestampPublic, "Public sale has not started");
        require(mintedCount[msg.sender] == 0, "Quantity must be less than max mint per wallet");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Quantity must be less than max supply");
        require(msg.value >= PUBLIC_PRICE, "Ether value sent is not correct");

        mintedCount[msg.sender] += 1;
        _mint(msg.sender, 1);
    }

    /// ============ ONLY OWNER ============

    function setSaleStartTimestampWL(uint256 _saleStartTimestampWL) external onlyOwner {
        saleStartTimestampWL = _saleStartTimestampWL;
    }

    function setSaleStartTimestampActive(uint256 _saleStartTimestampActive) external onlyOwner {
        saleStartTimestampActive = _saleStartTimestampActive;
    }

    function setSaleStartTimestampPublic(uint256 _saleStartTimestampPublic) external onlyOwner {
        saleStartTimestampPublic = _saleStartTimestampPublic;
    }

    function setMerkleRootWL(bytes32 _merkleRootWL) external onlyOwner {
        merkleRootWL = _merkleRootWL;
    }

    function setMerkleRootActive(bytes32 _merkleRootActive) external onlyOwner {
        merkleRootActive = _merkleRootActive;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function reveal(string calldata _baseURIRevealed) external onlyOwner {
        require(!revealed, "Already revealed");
        baseURIRevealed = _baseURIRevealed;
        revealed = true;
    }

    function updateRevealedBaseURI(string calldata _baseURIRevealed) external onlyOwner {
        require(revealed, "Not revealed yet");
        baseURIRevealed = _baseURIRevealed;
    }

    function setbaseURIUnrevealed(string calldata _baseURIUnrevealed) external onlyOwner {
        baseURIUnrevealed = _baseURIUnrevealed;
    }

    function setbaseURIRevealed(string calldata _baseURIRevealed) external onlyOwner {
        baseURIRevealed = _baseURIRevealed;
    }

    /// ============ METADATA ============

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        if (revealed) {
            return string(abi.encodePacked(baseURIRevealed, _toString(tokenId)));
        } else {
            return baseURIUnrevealed;
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function claimAllGas(address recipientOfGas) external onlyOwner {
        IBlast(BLAST).claimAllGas(address(this), recipientOfGas);
    }

    function claimAllYield(address recipient) external onlyOwner {
		IBlast(BLAST).claimAllYield(address(this), recipient);
    }

}
