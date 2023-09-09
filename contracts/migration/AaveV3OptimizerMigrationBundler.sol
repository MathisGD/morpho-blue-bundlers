// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {IMorpho as IAaveV3Optimizer} from "@morpho-aave-v3/interfaces/IMorpho.sol";

import {Types} from "@morpho-aave-v3/libraries/Types.sol";

import {MigrationBundler} from "./MigrationBundler.sol";

/// @title AaveV3OptimizerMigrationBundler
/// @author Morpho Labs
/// @custom:contact security@morpho.xyz
/// @notice Contract allowing to migrate a position from AaveV3 Optimizer to Morpho Blue easily.
contract AaveV3OptimizerMigrationBundler is MigrationBundler {
    /* IMMUTABLES */

    IAaveV3Optimizer public immutable AAVE_V3_OPTIMIZER;

    /* CONSTRUCTOR */

    constructor(address morpho, address aaveV3Optimizer) MigrationBundler(morpho) {
        AAVE_V3_OPTIMIZER = IAaveV3Optimizer(aaveV3Optimizer);
    }

    /* ACTIONS */

    function aaveV3OptimizerRepay(address underlying, uint256 amount) external payable {
        _approveMaxTo(underlying, address(AAVE_V3_OPTIMIZER));

        AAVE_V3_OPTIMIZER.repay(underlying, amount, _initiator);
    }

    function aaveV3OptimizerWithdraw(address underlying, uint256 amount, address receiver, uint256 maxIterations)
        external
        payable
    {
        AAVE_V3_OPTIMIZER.withdraw(underlying, amount, _initiator, receiver, maxIterations);
    }

    function aaveV3OptimizerWithdrawCollateral(address underlying, uint256 amount, address receiver) external payable {
        AAVE_V3_OPTIMIZER.withdrawCollateral(underlying, amount, _initiator, receiver);
    }

    function aaveV3OptimizerApproveManagerWithSig(
        bool isAllowed,
        uint256 nonce,
        uint256 deadline,
        Types.Signature calldata signature
    ) external payable {
        AAVE_V3_OPTIMIZER.approveManagerWithSig(_initiator, address(this), isAllowed, nonce, deadline, signature);
    }
}
