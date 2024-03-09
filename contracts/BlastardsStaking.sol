// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IERC721A.sol";
import "./IBlast.sol";

interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract BlastardsStaking is OwnableUpgradeable {

    address private constant BLAST = 0x4300000000000000000000000000000000000002;

    IERC721A public blastards;

    mapping(address => uint256) public pointsInternal;
    mapping(address => uint256) public lastSnapshot;
    mapping(address => uint256[]) public stakedTokens;
    mapping(uint256 => address) public stakedBy;

    function initialize(
        address _blastards
    ) external initializer {
        __Ownable_init();

        IBlast(BLAST).configureAutomaticYield();
        IBlast(BLAST).configureClaimableGas();
        blastards = IERC721A(_blastards);
    }

    function stake(uint256[] calldata nftIds) external {
        pointsInternal[msg.sender] += points(msg.sender);
        lastSnapshot[msg.sender] = block.timestamp;
        for (uint256 i = 0; i < nftIds.length; i++) {
            require(blastards.ownerOf(nftIds[i]) == msg.sender, "Not owner");
            blastards.safeTransferFrom(msg.sender, address(this), nftIds[i]);
            stakedBy[nftIds[i]] = msg.sender;
            stakedTokens[msg.sender].push(nftIds[i]);
        }
    }

    function unstake(uint256[] calldata nftIds) external {
        pointsInternal[msg.sender] += points(msg.sender);
        lastSnapshot[msg.sender] = block.timestamp;
        for (uint256 i = 0; i < nftIds.length; i++) {
            require(stakedBy[nftIds[i]] == msg.sender, "Not staked by you");

            for (uint256 j = 0; j < stakedTokens[msg.sender].length; j++) {
                if (stakedTokens[msg.sender][j] == nftIds[i]) {
                    stakedTokens[msg.sender][j] = stakedTokens[msg.sender][stakedTokens[msg.sender].length - 1];
                    stakedTokens[msg.sender].pop();
                    break;
                }
            }

            blastards.safeTransferFrom(address(this), msg.sender, nftIds[i]);
        }
    }

    function points(address account) public view returns (uint256) {

        if (lastSnapshot[account] == 0) {
            return 0;
        }

        if (stakedTokens[account].length == 0) {
            return pointsInternal[account];
        }

        return pointsInternal[account] + (
            (block.timestamp - lastSnapshot[account]) / 1 hours * // get number of hours since last snapshot
            ((block.timestamp - lastSnapshot[account]) / 30 days * 5 + 10) * // +50% for every month
            getBalanceMultiplier(stakedTokens[account].length) / 100 // div as Balance multiplier for 1e, and month multiplier for 1e
        );
    }

    function getBalanceMultiplier(uint256 tokenAmount) internal pure returns (uint256) {
        if (tokenAmount >= 51) {
            return 1770;
        } else if (tokenAmount >= 41) {
            return 1450;
        } else if (tokenAmount >= 21) {
            return 950;
        } else if (tokenAmount >= 11) {
            return 450;
        } else if (tokenAmount >= 6) {
            return 200;
        } else if (tokenAmount >= 3) {
            return 80;
        } else if (tokenAmount >= 2) {
            return 25;
        } else if (tokenAmount >= 1) {
            return 10;
        } else{
            return 0;
        }
    }


    function claimAllGas(address recipientOfGas) external onlyOwner {
        IBlast(BLAST).claimAllGas(address(this), recipientOfGas);
    }

    function claimAllYield(address recipient) external onlyOwner {
		IBlast(BLAST).claimAllYield(address(this), recipient);
    }

      function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return ERC721A__IERC721Receiver.onERC721Received.selector;
    }

}
