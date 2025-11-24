// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/console.sol";
import "forge-std/Script.sol";

import { FlashLoanAdapterFactory } from "../src/AdapterFactory.sol";

contract DeployFactoryUsingCreate2Script is Script {
    function run() external {
        bytes32 salt = vm.envOr("FACTORY_SALT", bytes32(keccak256("FACTORY")));

        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        console.log("Deployer:", deployer);
        console.log("Salt:", vm.toString(salt));
        console.log("Chain:", block.chainid);

        bytes memory code = type(FlashLoanAdapterFactory).creationCode;

        vm.startBroadcast(pk);

        address deployed = _deployCreate2(salt, code);

        vm.stopBroadcast();

        console.log("Factory deployed at:", deployed);
    }

    function _deployCreate2(bytes32 salt, bytes memory code) internal returns (address addr){
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }

    function computeAddress(
        address deployer,
        bytes32 salt,
        bytes32 codeHash
    ) public pure returns (address) {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            deployer,
                            salt,
                            codeHash
                        )
                    )
                )
            )
        );
    }
}