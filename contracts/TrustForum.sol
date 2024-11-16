// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity >=0.8.12 <0.9.0;

import "fhevm/lib/TFHE.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "fhevm/gateway/GatewayCaller.sol";

contract TrustForum is Ownable2Step, GatewayCaller {
    uint64 public totalVoteCnt;
    mapping(address => uint64) internal decryVoteCnts;
    mapping(address => euint64) internal encryVoteCnts;
    euint64 private totalVoteCntEncry;


    constructor() Ownable(msg.sender) {}

    function init() external onlyOwner {
        TFHE.allow(totalVoteCntEncry, owner());
        TFHE.allow(totalVoteCntEncry, address(this));
    }

    function voteMock(address topic, uint64 likes, bytes calldata inputProof) public {
        decryVoteCnts[topic] += likes;
    }

    function voteTopic(address topic, einput likes, bytes calldata inputProof) public {
        euint64 userLikes = TFHE.asEuint64(likes, inputProof);

        if (TFHE.isInitialized(encryVoteCnts[topic])) {
            TFHE.allow(encryVoteCnts[topic], address(this));
            TFHE.allow(encryVoteCnts[topic], owner());
            encryVoteCnts[topic] = TFHE.add(encryVoteCnts[topic], userLikes);
        } else {
            encryVoteCnts[topic] = userLikes;
        }

        totalVoteCntEncry = TFHE.add(totalVoteCntEncry, userLikes);
        TFHE.allow(totalVoteCntEncry, address(this));
        TFHE.allow(totalVoteCntEncry, owner());
    }

    function revealTotalResults() public onlyOwner {
        euint64 totalvoteCnt = totalVoteCntEncry;
        TFHE.allow(totalvoteCnt, address(this));
        uint256[] memory cts = new uint256[](1);
        cts[0] = Gateway.toUint256(totalvoteCnt);

        Gateway.requestDecryption(cts, this.decryptionTotalCallback.selector, 0, block.timestamp + 100, false);
    }

    /**
     * @notice Callback function to handle decrypted results from the gateway
     * @param totalVoteCntDecrypted Decrypted totalVoteCnt
     * @return True if the callback is successful
     */
    function decryptionTotalCallback(
        uint256 /*requestID*/,
        uint64 totalVoteCntDecrypted
    ) public onlyGateway returns (bool) {
        totalVoteCnt = totalVoteCntDecrypted;
        return true;
    }

    function revealUserVotingResult(address topic) public onlyOwner {
        eaddress encUser = TFHE.asEaddress(topic);
        euint64 encCount = encryVoteCnts[topic];
        TFHE.allow(encUser, address(this));
        TFHE.allow(encCount, address(this));
        uint256[] memory cts = new uint256[](0);
        cts[0] = Gateway.toUint256(encUser);
        cts[0] = Gateway.toUint256(encCount);
        Gateway.requestDecryption(cts, this.decryptionUserCallback.selector, 0, block.timestamp + 100, false);
    }

    function decryptionUserCallback(
        uint256 /*requestID*/,
        address topic,
        uint64 voteCount
    ) public onlyGateway returns (bool) {
        // Update plaintext tallies with decrypted values
        decryVoteCnts[topic] = voteCount;
        return true;
    }

    function getOwnEncryptedVoteCount() public view returns (euint64) {
        return encryVoteCnts[msg.sender];
    }
    function getUserEncryptedVoteCount(address topic) public view returns (euint64) {
        return encryVoteCnts[topic];
    }
    function getEncryptedInFavorVoteCount() public view returns (euint64) {
        return totalVoteCntEncry;
    }
    function getDecryptedVoteCount(address topic) public view returns (uint64) {
        return decryVoteCnts[topic];
    }
}
