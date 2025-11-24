// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";

import { FlashLoanAdapterFactory } from "../src/AdapterFactory.sol";
import { FlashAdapter } from "../src/FlashAdapter.sol";

contract FlashLoanAdapterFactoryTest is Test {
    FlashLoanAdapterFactory internal factory;

    address internal owner = address(0xBEEF);
    address internal uniswapFactory = address(0xFAFA);

    bytes32 internal salt = keccak256("some salt");

    function setUp() public {
        factory = new FlashLoanAdapterFactory();
    }

    function testGetAdapterAddressDeterministic() public {
        address expected = factory.getAdapterAddress(owner, uniswapFactory, salt);

        bytes memory bytecode = abi.encodePacked(
            type(FlashAdapter).creationCode,
            abi.encode(owner, uniswapFactory)
        );

        bytes32 codeHash = keccak256(bytecode);

        bytes32 create2Hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(factory),
                salt,
                codeHash
            )
        );

        address calc = address(uint160(uint(create2Hash)));
        assertEq(expected, calc, "predicted address mismatch");
    }

    function testCreateAdapterDeploysAtPredictedAddress() public {
        address predicted = factory.getAdapterAddress(owner, uniswapFactory, salt);

        address deployed = factory.createAdapter(owner, uniswapFactory, salt);

        assertEq(deployed, predicted, "Adapter deployed at wrong address");
        assertTrue(deployed.code.length > 0, "Adapter not deployed");
    }


    function testCreateAdapterDoesNotReDeployIfExists() public {
        address first = factory.createAdapter(owner, uniswapFactory, salt);

        address second = factory.createAdapter(owner, uniswapFactory, salt);

        assertEq(first, second, "");
    }
}