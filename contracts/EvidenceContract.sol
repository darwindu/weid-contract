pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

/*
 *       Copyright© (2018-2020) WeBank Co., Ltd.
 *
 *       This file is part of weidentity-contract.
 *
 *       weidentity-contract is free software: you can redistribute it and/or modify
 *       it under the terms of the GNU Lesser General Public License as published by
 *       the Free Software Foundation, either version 3 of the License, or
 *       (at your option) any later version.
 *
 *       weidentity-contract is distributed in the hope that it will be useful,
 *       but WITHOUT ANY WARRANTY; without even the implied warranty of
 *       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *       GNU Lesser General Public License for more details.
 *
 *       You should have received a copy of the GNU Lesser General Public License
 *       along with weidentity-contract.  If not, see <https://www.gnu.org/licenses/>.
 */

contract EvidenceContract {

    // block number map, hash as key
    mapping(bytes32 => uint256) changed;
    // hash map, extra id string as key, hash as value
    mapping(string => bytes32) extraKeyMapping;

    // Error codes
    uint256 constant private RETURN_CODE_SUCCESS = 0;
    uint256 constant private RETURN_CODE_FAILURE_NOT_EXIST = 500600;

    // Evidence attribute change event
    event EvidenceAttributeChanged(
        bytes32[] hash,
        address signer,
        string[] sigs,
        string[] logs,
        uint256 updated,
        uint256[] previousBlock
    );

    function getLatestRelatedBlock(
        bytes32 hash
    ) 
        public 
        constant 
        returns (uint256) 
    {
        return changed[hash];
    }

    /**
     * Create evidence. Here, hash value is the key; signInfo is the base64 signature;
     * and extra is the compact json of blob: {"credentialId":"aacc1122-324b.."}
     * This allows append operation from other signer onto a same hash, so no permission check.
     */
    function createEvidence(
        bytes32[] hash,
        string[] sig,
        string[] log,
        uint256 updated
    )
        public
    {
        uint256 sigSize = hash.length;
        bytes32[] memory hashs = new bytes32[](sigSize);
        string[] memory sigs = new string[](sigSize);
        string[] memory logs = new string[](sigSize);
        uint256[] memory previousBlocks = new uint256[](sigSize);
        for (uint256 i = 0; i < sigSize; i++) {
            bytes32 thisHash = hash[i];
            hashs[i] = thisHash;
            sigs[i] = sig[i];
            logs[i] = log[i];
            previousBlocks[i] = changed[thisHash];
            changed[thisHash] = block.number;
        }
        emit EvidenceAttributeChanged(hashs, msg.sender, sigs, logs, updated, previousBlocks);
    }

    /**
     * Create evidence by extra key. Here, hash value is the key; signInfo is the base64 signature;
     * and extra is the compact json of blob: {"credentialId":"aacc1122-324b.."};
     * hash can be find by extrarKey, extrarKey is business ID in business system.
     * This allows append operation from other signer onto a same hash, so no permission check.
     */
    function createEvidenceWithExtraKey(
        bytes32[] hash,
        string[] sig,
        string[] log,
        uint256 updated,
        string[] extraKey
    )
        public
    {
        uint256 sigSize = hash.length;
        bytes32[] memory hashs = new bytes32[](sigSize);
        string[] memory sigs = new string[](sigSize);
        string[] memory logs = new string[](sigSize);
        uint256[] memory previousBlocks = new uint256[](sigSize);
        for (uint256 i = 0; i < sigSize; i++) {
            bytes32 thisHash = hash[i];
            hashs[i] = thisHash;
            sigs[i] = sig[i];
            logs[i] = log[i];
            previousBlocks[i] = changed[thisHash];
            changed[thisHash] = block.number;
            extraKeyMapping[extraKey[i]] = thisHash;
        }
        emit EvidenceAttributeChanged(hashs, msg.sender, sigs, logs, updated, previousBlocks);
    }

    function isHashExist(bytes32 hash) public constant returns (bool) {
        if (changed[hash] != 0) {
            return true;
        }
        return false;
    }

    function getHashByExtraKey(
        string extraKey
    )
        public
        constant
        returns (bytes32)
    {
        return extraKeyMapping[extraKey];
    }
}