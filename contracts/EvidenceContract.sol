import "./strings.sol";

pragma solidity ^0.4.4;

/*
 *       Copyright� (2018-2020) WeBank Co., Ltd.
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
    using strings for *;
    // block number map, hash as key, block number (in uint256 converted string) as value
    mapping(string => string) changed;
    // hash map, extra id as key
    mapping(string => string) extraKeyMapping;

    // Attribute keys
    string constant private ATTRIB_KEY_SIGNINFO = "info";
    string constant private ATTRIB_KEY_EXTRA = "extra";
    
    // Delimeters
    string constant private DELIMETER_ATTRIB = "|";

    // Error codes
    uint256 constant private RETURN_CODE_SUCCESS = 0;
    uint256 constant private RETURN_CODE_FAILURE_NOT_EXIST = 500600;

    // Both hash and signer are used as identification key
    event EvidenceAttributeChanged(
        string hash,
        address signer,
        string key,
        string value,
        uint256 updated,
        string previousBlock
    );

    function getLatestRelatedBlock(
        string hash
    ) 
        public 
        constant 
        returns (string) 
    {
        return changed[hash];
    }

    /**
     * Create evidence. Here, hash value is the key; signInfo is the base64 signature;
     * and extra is the compact json of blob: {"credentialId":"aacc1122-324b.."}
     * This allows append operation from other signer onto a same hash, so no permission check.
     */
    function createEvidence(
        string hash,
        string sig,
        string extra,
        uint256 updated
    )
        public
    {
        EvidenceAttributeChanged(hash, msg.sender, ATTRIB_KEY_SIGNINFO, sig, updated, changed[hash]);
        EvidenceAttributeChanged(hash, msg.sender, ATTRIB_KEY_EXTRA, extra, updated, changed[hash]);
        changed[hash] = uint2str(block.number);
    }
    
    function batchCreateEvidence(
        string hash,
        string sig,
        string extra,
        uint256 updated
    )
        public
    {
        var delim = DELIMETER_ATTRIB.toSlice();
        var hashs = hash.toSlice();
        var segSize = hashs.count(delim) + 1;
        var allPreviousBlockSlice = "".toSlice();
        // Construct the previousBlock with DELIMETER_ATTRIB and set the changed[hash]
        for (uint256 index = 0; index < segSize; index ++) {
            string memory currentHash = hashs.split(delim).toString();
            if (index == 0) {
                allPreviousBlockSlice = changed[currentHash].toSlice();
            } else {
                allPreviousBlockSlice = (allPreviousBlockSlice.concat(delim).toSlice()).concat(changed[currentHash].toSlice()).toSlice();
            }
            changed[currentHash] = uint2str(block.number);
        }
        string memory result = allPreviousBlockSlice.toString();
        // Construct the event and leave decoding job to SDK guys
        EvidenceAttributeChanged(hash, msg.sender, ATTRIB_KEY_SIGNINFO, sig, updated,
            result);
        EvidenceAttributeChanged(hash, msg.sender, ATTRIB_KEY_EXTRA, extra, updated,
            result);
    }

    /**
     * Create evidence by extra key. Here, hash value is the key; signInfo is the base64 signature;
     * and extra is the compact json of blob: {"credentialId":"aacc1122-324b.."};
     * hash can be find by extrarKey, extrarKey is business ID in business system.
     * This allows append operation from other signer onto a same hash, so no permission check.
     */
    function createEvidenceWithExtraKey(
        string hash,
        string sig,
        string extra,
        uint256 updated,
        string extraKey
    )
        public
    {
        createEvidence(hash, sig, extra, updated);
        extraKeyMapping[extraKey] = hash;
    }

    /**
     * Aribitrarily append attributes to an existing hash evidence, e.g. revoke status.
     */
    function setAttribute(
        string hash,
        string key,
        string value,
        uint256 updated
    )
        public
    {
        if (!isHashExist(hash)) {
            return;
        }
        if (isEqualString(key, ATTRIB_KEY_SIGNINFO)) {
            return;
        }
        EvidenceAttributeChanged(hash, msg.sender, key, value, updated, changed[hash]);
        changed[hash] = uint2str(block.number);
    }

    function isHashExist(string hash) public constant returns (bool) {
        if (isEqualString(changed[hash], "")) {
            return false;
        }
        return true;
    }

    function isEqualString(string a, string b) private constant returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(a) == keccak256(b);
        }
    }

    function getHashByExtraKey(
        string extraKey
    )
        public
        constant
        returns (string)
    {
        return extraKeyMapping[extraKey];
    }

    function uint2str(uint i) private constant returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0) {
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
}