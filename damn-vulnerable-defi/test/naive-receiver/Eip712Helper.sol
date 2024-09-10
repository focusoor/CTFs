// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {BasicForwarder} from "../../src/naive-receiver/BasicForwarder.sol";
import { console } from "forge-std/console.sol";

/// @title Helper contract to compute EIP712 digest
/// @author focusoor
/// @dev taken and addapted from Solady's EIP712.sol. Goal -> inject forwarder address in the domain separator to get the right digest
contract Eip712Helper is BasicForwarder {

    function hashTypedData(Request calldata request, address forwarder) external view returns (bytes32 digest) {
        bytes32 structHash = getDataHash(request);

        bytes32 separator;

        (string memory name, string memory version) = _domainNameAndVersion();
        bytes32 nameHash = keccak256(bytes(name));
        bytes32 versionHash = keccak256(bytes(version));
        assembly {
            let m := mload(0x40) // Load the free memory pointer.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), nameHash)
            mstore(add(m, 0x40), versionHash)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), forwarder)
            separator := keccak256(m, 0xa0)
        }

        digest = separator;

        assembly {
            // Compute the digest.
            mstore(0x00, 0x1901000000000000) // Store "\x19\x01".
            mstore(0x1a, digest) // Store the domain separator.
            mstore(0x3a, structHash) // Store the struct hash.
            digest := keccak256(0x18, 0x42)
            // Restore the part of the free memory slot that was overwritten.
            mstore(0x3a, 0)
        }
    }
}
