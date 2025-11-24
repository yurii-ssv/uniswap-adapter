// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { FlashAdapter } from "./FlashAdapter.sol";

contract FlashLoanAdapterFactory {
    function createAdapter(
        address owner,
        address uniswapFactory,
        bytes32 salt
    ) external returns (address adapter) {
        adapter = getAdapterAddress(owner, uniswapFactory, salt);

        if (_isDeployed(adapter)) {
            return adapter;
        }

        bytes memory bytecode = abi.encodePacked(
            type(FlashAdapter).creationCode,
            abi.encode(owner, uniswapFactory)
        );

        address deployed;
        assembly {
            deployed := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(deployed) { revert(0, 0) }
        }

        return deployed;
    }

    function getAdapterAddress(
        address owner,
        address uniswapFactory,
        bytes32 salt
    ) public view returns (address) {
        bytes memory bytecode = abi.encodePacked(
            type(FlashAdapter).creationCode,
            abi.encode(owner, uniswapFactory)
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );

        return address(uint160(uint(hash)));
    }

    function _isDeployed(address a) internal view returns (bool) {
        return a.code.length > 0;
    }
}