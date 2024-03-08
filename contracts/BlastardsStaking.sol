// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC721A.sol";
import "./IBlast.sol";

contract BlastardsStaking is Ownable {

    address private constant BLAST = 0x4300000000000000000000000000000000000002;

    IERC721A public blastards;

    mapping(address => uint256) public pointsInternal;
    mapping(address => uint256) public lastSnapshot;
    mapping(address => uint256[]) public stakedTokens;
    mapping(uint256 => address) public stakedBy;

    constructor(address _blastards) Ownable(msg.sender) {
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
            blastards.safeTransferFrom(address(this), msg.sender, nftIds[i]);
        }
    }

    function points(address account) public view returns (uint256) {
        return pointsInternal[account] + (
            block.timestamp - lastSnapshot[account] / 1 hours * stakedTokens[account].length * // 1 point for every staked nft per hour
            ((block.timestamp - lastSnapshot[account]) / 30 days * 5 + 10) * // +50% for every month
            getBalanceMultiplier(stakedTokens[account].length) / 10
        );
    }

    function getBalanceMultiplier(uint256 tokenAmount) internal pure returns (uint256) {
        if (tokenAmount >= 51) {
            return 177;
        } else if (tokenAmount >= 41) {
            return 145;
        } else if (tokenAmount >= 21) {
            return 95;
        } else if (tokenAmount >= 11) {
            return 45;
        } else if (tokenAmount >= 6) {
            return 20;
        } else if (tokenAmount >= 3) {
            return 8;
        } else if (tokenAmount >= 2) {
            return 2;
        } else if (tokenAmount >= 1) {
            return 1;
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

}
