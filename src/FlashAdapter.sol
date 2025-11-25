// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { IUniswapV3FlashCallback } from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IFlashAdapter } from "./interfaces/IFlashAdapter.sol";

contract FlashAdapter is IUniswapV3FlashCallback, IFlashAdapter {
    address public immutable OWNER;
    address public immutable FACTORY;

    FlashContext private ctx;

    modifier onlyOwner() {
        if (msg.sender != OWNER) {
            revert Unauthorized();
        }
        _;
    }

    constructor(address _owner, address _uniswapFactory) {
        if (_owner == address(0) || _uniswapFactory == address(0)) {
            revert ZeroAddress();
        }

        OWNER = _owner;
        FACTORY = _uniswapFactory;
    }

    /// @notice Start a flash loan on any Uniswap V3 pool
    function flash(
        address pool,
        uint256 amount0,
        uint256 amount1,
        Call[] calldata calls
    ) external onlyOwner {
        if (pool == address(0)) {
            revert ZeroAddress();
        }

        if (ctx.pool != address(0)) {
            revert FlashInProgress();
        }

        address token0 = IUniswapV3Pool(pool).token0();
        address token1 = IUniswapV3Pool(pool).token1();

        ctx = FlashContext(pool, token0, token1, amount0, amount1);

        bytes memory data = abi.encode(calls);

        IUniswapV3Pool(pool).flash(address(this), amount0, amount1, data);

        delete ctx;
    }

    function execute(Call[] calldata calls) onlyOwner external {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool ok, bytes memory result) =
                                        calls[i].target.call{value: calls[i].value}(calls[i].callData);
            if (!ok) {
                revert CallFailed(result);
            }
        }
    }

    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override {
        FlashContext memory c = ctx;

        if (msg.sender != c.pool) {
            revert Unauthorized();
        }

        if (c.pool == address(0)) {
            revert NoFlashContext();
        }

        Call[] memory calls = abi.decode(data, (Call[]));

        for (uint256 i = 0; i < calls.length; i++) {
            (bool ok, bytes memory result) =
                                        calls[i].target.call{value: calls[i].value}(calls[i].callData);
            if (!ok) {
                revert CallFailed(result);
            }
        }

        uint256 amount0Owed = c.amount0 + fee0;
        uint256 amount1Owed = c.amount1 + fee1;

        if (amount0Owed > 0) IERC20(c.token0).transfer(c.pool, amount0Owed);
        if (amount1Owed > 0) IERC20(c.token1).transfer(c.pool, amount1Owed);

        delete ctx;
    }

    receive() external payable {}
}