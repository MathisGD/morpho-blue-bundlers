// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {Math} from "@morpho-utils/math/Math.sol";
import {ErrorsLib} from "./libraries/ErrorsLib.sol";
import {SafeTransferLib, ERC20} from "solmate/src/utils/SafeTransferLib.sol";

import {BaseSelfMulticall} from "./BaseSelfMulticall.sol";
import {BaseCallbackReceiver} from "./BaseCallbackReceiver.sol";

/// @title BaseBundler
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @notice Enables calling multiple functions in a single call to the same contract (self) as well as calling other
/// Bundler contracts.
/// @dev Every Bundler must inherit from this contract.
/// @dev Every bundler inheriting from this contract must have their external functions payable as they will be
/// delegate called by the `multicall` function (which is payable, and thus might pass a non-null ETH value). It is
/// recommended not to rely on `msg.value` as the same value can be reused for multiple calls.
/// @dev Assumes that any tokens left on the contract can be seized by anyone.
abstract contract BaseBundler is BaseSelfMulticall, BaseCallbackReceiver {
    using SafeTransferLib for ERC20;

    /* EXTERNAL */

    /// @notice Executes a series of calls in a single transaction to self.
    function multicall(uint256 deadline, bytes[] calldata data) external payable lockInitiator {
        require(block.timestamp <= deadline, ErrorsLib.DEADLINE_EXPIRED);

        _multicall(data);
    }

    /* ACTIONS */

    /// @notice Transfers the minimum between the given `amount` and the bundler's balance of native asset from the
    /// bundler to `recipient`.
    /// @dev Pass in `type(uint256).max` to transfer all.
    function nativeTransfer(address recipient, uint256 amount) external payable {
        require(recipient != address(0), ErrorsLib.ZERO_ADDRESS);
        require(recipient != address(this), ErrorsLib.BUNDLER_ADDRESS);

        amount = Math.min(amount, address(this).balance);

        require(amount != 0, ErrorsLib.ZERO_AMOUNT);

        SafeTransferLib.safeTransferETH(recipient, amount);
    }

    /// @notice Transfers the minimum between the given `amount` and the bundler's balance of `asset` from the bundler
    /// to `recipient`.
    /// @dev Pass in `type(uint256).max` to transfer all.
    function erc20Transfer(address asset, address recipient, uint256 amount) external payable {
        require(recipient != address(0), ErrorsLib.ZERO_ADDRESS);
        require(recipient != address(this), ErrorsLib.BUNDLER_ADDRESS);

        amount = Math.min(amount, ERC20(asset).balanceOf(address(this)));

        require(amount != 0, ErrorsLib.ZERO_AMOUNT);

        ERC20(asset).safeTransfer(recipient, amount);
    }

    /// @notice Transfers the given `amount` of `asset` from sender to this contract via ERC20 transferFrom.
    /// @notice Warning: should only be called via the bundler's `multicall` function.
    /// @dev Pass in `type(uint256).max` to transfer all.
    function erc20TransferFrom(address asset, uint256 amount) external payable {
        amount = Math.min(amount, ERC20(asset).balanceOf(_initiator));

        require(amount != 0, ErrorsLib.ZERO_AMOUNT);

        ERC20(asset).safeTransferFrom(_initiator, address(this), amount);
    }
}