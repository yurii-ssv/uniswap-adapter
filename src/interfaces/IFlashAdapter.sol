// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IFlashAdapter {
    struct Call {
        address target;
        uint256 value;
        bytes callData;
    }

    struct FlashContext {
        address pool;
        address token0;
        address token1;
        uint256 amount0;
        uint256 amount1;
    }

    event FlashExecuted(
        address indexed pool,
        uint256 amount0,
        uint256 amount1
    );

    error Unauthorized();
    error ZeroAddress();
    error FlashInProgress();
    error NoFlashContext();
    error CallFailed(bytes reason);

    function flash(
        address pool,
        uint256 amount0,
        uint256 amount1,
        Call[] calldata calls
    ) external;
}