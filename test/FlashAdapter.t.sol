// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IUniswapV3FlashCallback } from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";

import "forge-std/Test.sol";
import "../src/interfaces/IFlashAdapter.sol";
import "../src/FlashAdapter.sol";
import "./mock/MockPool.sol";

contract FlashAdapterTest is Test {
    FlashAdapter internal adapter;
    MockPool internal pool;
    Target internal target;

    address internal owner = address(0xBEEF);
    address internal uniswapFactory = address(0xFEEB);

    address internal token0 = address(0xAAA);
    address internal token1 = address(0xBBB);

    IFlashAdapter.Call[] internal calls;

    function setUp() public {
        adapter = new FlashAdapter(owner, uniswapFactory);
        pool = new MockPool(uniswapFactory, token0, token1);
        target = new Target();
    }

    function testConstructor() public {
        assertEq(adapter.OWNER(), owner);
        assertEq(adapter.FACTORY(), uniswapFactory);
    }

    function testConstructorRevertsIfOwnerZeroAddress() public {
        vm.expectRevert(IFlashAdapter.ZeroAddress.selector);
        adapter = new FlashAdapter(address(0), uniswapFactory);
    }

    function testConstructorRevertsIfFactoryZeroAddress() public {
        vm.expectRevert(IFlashAdapter.ZeroAddress.selector);
        adapter = new FlashAdapter(owner, address(0));
    }

    function testFlashExecutesCallbackAndAdditionalCalls() public {
        calls.push(IFlashAdapter.Call({
            target: address(target),
            value: 0,
            callData: abi.encodeWithSelector(Target.foo.selector)
        }));

        vm.expectCall(
            address(target),
            abi.encodeWithSelector(Target.foo.selector)
        );

        vm.expectCall(
            address(adapter),
            abi.encodeWithSelector(
                IUniswapV3FlashCallback.uniswapV3FlashCallback.selector
            )
        );

        vm.prank(owner);
        adapter.flash(address(pool), 0, 0, calls);
    }

    function testFlashRevertsIfCallerNotOwner() public {
        vm.expectRevert(IFlashAdapter.Unauthorized.selector);

        adapter.flash(address(pool), 0, 0, calls);
    }

    function testFlashRevertsIfPoolZeroAddress() public {
        vm.expectRevert(IFlashAdapter.ZeroAddress.selector);

        vm.prank(owner);
        adapter.flash(address(0), 0, 0, calls);
    }

}

contract Target {
    event FooCalled();
    event BarCalled();

    function foo() external {
        emit FooCalled();
    }
    function bar() external {
        emit BarCalled();
    }

    function revertOnCall() external pure {
        revert("FAIL");
    }
}