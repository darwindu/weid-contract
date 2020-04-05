pragma solidity ^0.4.4;
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

    // Evidence Sign event
    event EvidenceSigned(
        bytes32[] hash,
        address signer,
        bytes32[] r,
        bytes32[] s,
        uint8[] v,
        uint256[] previousBlock
    );

    // Evidence Logged event
    event EvidenceLogged(
        bytes32[] hash,
        address signer,
        bytes32[] logs,
        uint256[] logSize,
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
        bytes32[] r,
        bytes32[] s,
        uint8[] v,
        bytes32[] log,
        uint256[] logSize
    )
        public
    {
        createSignEvent(hash, r, s, v);
        createLogEvent(hash, log, logSize);
    }
    
    function createSignEvent(
        bytes32[] hash,
        bytes32[] r,
        bytes32[] s,
        uint8[] v
    )
        private
    {
        uint256 sigSize = hash.length;
        bytes32[] memory hashs = new bytes32[](sigSize);
        bytes32[] memory rs = new bytes32[](sigSize);
        bytes32[] memory ss = new bytes32[](sigSize);
        uint8[] memory vs = new uint8[](sigSize);
        uint256[] memory previousBlocks = new uint256[](sigSize);
        for (uint256 i = 0; i < sigSize; i++) {
            hashs[i] = hash[i];
            rs[i] = r[i];
            ss[i] = s[i];
            vs[i] = v[i];
            previousBlocks[i] = changed[hash[i]];
            changed[hash[i]] = block.number;
        }
        EvidenceSigned(hashs, msg.sender, rs, ss, vs, previousBlocks);
    }
    
    function createLogEvent(
        bytes32[] hash,
        bytes32[] log,
        uint256[] logSize
    )
        private
    {
        uint256 hashSize = hash.length;
        bytes32[] memory hashs = new bytes32[](hashSize);
        uint256[] memory logSizes = new uint256[](hashSize);
        uint256[] memory previousBlocks = new uint256[](hashSize);
        for (uint256 i = 0; i < hashSize; i++) {
            hashs[i] = hash[i];
            logSizes[i] = logSize[i];
            previousBlocks[i] = changed[hash[i]];
            changed[hash[i]] = block.number;
        }
        uint256 logTotalLength = log.length;
        bytes32[] memory logs = new bytes32[](logTotalLength);
        for (i = 0; i < logTotalLength; i++) {
            logs[i] = log[i];
        }
        EvidenceLogged(hashs, msg.sender, logs, logSizes,  previousBlocks);
    }
    
    /**
     * Create evidence by extra key. Here, hash value is the key; signInfo is the base64 signature;
     * and extra is the compact json of blob: {"credentialId":"aacc1122-324b.."};
     * hash can be find by extrarKey, extrarKey is business ID in business system.
     * This allows append operation from other signer onto a same hash, so no permission check.
     */
    function createEvidenceWithExtraKey(
        bytes32 hash,
        bytes32 r,
        bytes32 s,
        uint8 v,
        bytes32[] log,
        uint256 logSize,
        string extraKey
    )
        public
    {
        bytes32[] memory hashs = new bytes32[](1);
        bytes32[] memory rs = new bytes32[](1);
        bytes32[] memory ss = new bytes32[](1); 
        uint8[] memory vs = new uint8[](1);
        uint256[] memory logSizes = new uint256[](1);
        hashs[0] = hash;
        rs[0] = r;
        ss[0] = s;
        vs[0] = v;
        logSizes[0] = logSize;
        uint256 logTotalLength = log.length;
        bytes32[] memory logs = new bytes32[](logTotalLength);
        for (uint256 i = 0; i < logTotalLength; i++) {
            logs[i] = log[i];
        }
        createEvidence(hashs, rs, ss, vs, logs, logSizes);
        extraKeyMapping[extraKey] = hash;
    }

    function addLog(
        bytes32[] hash,
        bytes32[] log,
        uint256[] logSize
    )
        public
    {
        createLogEvent(hash, log, logSize);
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