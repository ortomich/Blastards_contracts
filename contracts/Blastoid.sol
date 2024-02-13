// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.20;

import "./IBlast.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Blastoid is ERC721, Ownable {
    using Strings for uint256;

    address private constant BLAST = 0x4300000000000000000000000000000000000002;

    mapping (address => bool) public minted;
    uint256 public totalSupply;

    string public baseUri = "ipfs://QmRGcTpRXDtSs3hs1qNXcMRNZArQgyiTpCCCbbN4woSQny";

    constructor() ERC721("Blastoid", "BLST") Ownable(msg.sender) {
        IBlast(BLAST).configureClaimableGas();
    }

    function mint() external {
        require(!minted[msg.sender]);
        minted[msg.sender] = true;
        _mint(msg.sender, totalSupply + 1);
        totalSupply += 1;
    }

    function claimAllGas(address recipientOfGas) external onlyOwner {
        IBlast(BLAST).claimAllGas(address(this), recipientOfGas);
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        _requireOwned(tokenId);
        return baseUri;
    }

}