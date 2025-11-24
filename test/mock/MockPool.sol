// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV3FlashCallback } from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";

contract MockPool {
    address public immutable overrideFactory;
    address public immutable overrideToken0;
    address public immutable overrideToken1;

    constructor(address _factory, address _token0, address _token1) {
        overrideFactory = _factory;
        overrideToken0 = _token0;
        overrideToken1 = _token1;
    }

    function factory() external view returns (address) {
        return overrideFactory;
    }

    function token0() external view returns (address) {
        return overrideToken0;
    }

    function token1() external view returns (address) {
        return overrideToken1;
    }

    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        IUniswapV3FlashCallback(msg.sender).uniswapV3FlashCallback(
            0,
            0,
            data
        );
    }
}