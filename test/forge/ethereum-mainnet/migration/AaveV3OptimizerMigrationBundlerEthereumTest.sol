// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IMorpho as IAaveV3Optimizer} from "@morpho-aave-v3/interfaces/IMorpho.sol";

import {Types} from "@morpho-aave-v3/libraries/Types.sol";
import {AaveV3OptimizerAuthorization} from "../../helpers/SigUtils.sol";

import "src/migration/AaveV3OptimizerMigrationBundler.sol";

import "./helpers/EthereumMigrationTest.sol";

contract AaveV3MigrationBundlerEthereumTest is EthereumMigrationTest {
    using SafeTransferLib for ERC20;
    using MarketParamsLib for MarketParams;
    using MorphoLib for IMorpho;
    using MorphoBalancesLib for IMorpho;

    AaveV3OptimizerMigrationBundler bundler;

    uint256 collateralSupplied = 10_000 ether;
    uint256 borrowed = 1 ether;

    function setUp() public override {
        super.setUp();

        _initMarket(DAI, WETH);

        vm.label(AAVE_V3_OPTIMIZER, "Aave V3 Optimizer");

        bundler = new AaveV3OptimizerMigrationBundler(address(morpho), address(AAVE_V3_OPTIMIZER));
        vm.label(address(bundler), "Aave V3 Optimizer Migration Bundler");
    }

    function testMigrateBorrowerWithOptimizerPermit(uint256 privateKey) public {
        address user;
        (privateKey, user) = _getUserAndKey(privateKey);

        _provideLiquidity(borrowed);

        deal(marketParams.collateralToken, user, collateralSupplied + 1);

        vm.startPrank(user);
        ERC20(marketParams.collateralToken).safeApprove(AAVE_V3_OPTIMIZER, collateralSupplied + 1);
        IAaveV3Optimizer(AAVE_V3_OPTIMIZER).supplyCollateral(marketParams.collateralToken, collateralSupplied + 1, user);
        IAaveV3Optimizer(AAVE_V3_OPTIMIZER).borrow(marketParams.loanToken, borrowed, user, user, 15);
        vm.stopPrank();

        bytes[] memory data = new bytes[](1);
        bytes[] memory callbackData = new bytes[](7);

        callbackData[0] = _morphoSetAuthorizationWithSigCall(privateKey, address(bundler), true, 0);
        callbackData[1] = _morphoBorrowCall(borrowed, address(bundler));
        callbackData[2] = _morphoSetAuthorizationWithSigCall(privateKey, address(bundler), false, 1);
        callbackData[3] = _aaveV3OptimizerRepayCall(marketParams.loanToken, borrowed);
        callbackData[4] = _aaveV3OptimizerApproveManagerCall(privateKey, address(bundler), true, 0);
        callbackData[5] =
            _aaveV3OptimizerWithdrawCollateralCall(marketParams.collateralToken, collateralSupplied, address(bundler));
        callbackData[6] = _aaveV3OptimizerApproveManagerCall(privateKey, address(bundler), false, 1);
        data[0] = _morphoSupplyCollateralCall(collateralSupplied, user, abi.encode(callbackData));

        vm.prank(user);
        bundler.multicall(SIGNATURE_DEADLINE, data);

        _assertBorrowerPosition(collateralSupplied, borrowed, user, address(bundler));
    }

    function testMigrateUSDTBorrowerWithOptimizerPermit(uint256 privateKey) public {
        address user;
        (privateKey, user) = _getUserAndKey(privateKey);

        uint256 amountUsdt = collateralSupplied / 1e10;

        ERC4626Mock vaultUSDT = new ERC4626Mock(USDT, "USDT Vault", "V");
        _initMarket(address(vaultUSDT), WETH);
        oracle.setPrice(1e46);

        _provideLiquidity(borrowed);

        deal(USDT, user, amountUsdt + 1);

        console2.log(ERC20(USDT).allowance(user, AAVE_V3_OPTIMIZER));

        vm.startPrank(user);
        ERC20(USDT).safeApprove(AAVE_V3_OPTIMIZER, amountUsdt + 1);
        console2.log(ERC20(USDT).allowance(user, AAVE_V3_OPTIMIZER));
        IAaveV3Optimizer(AAVE_V3_OPTIMIZER).supplyCollateral(USDT, amountUsdt + 1, user);
        IAaveV3Optimizer(AAVE_V3_OPTIMIZER).borrow(marketParams.loanToken, borrowed, user, user, 15);
        vm.stopPrank();

        uint256 erc4626Amount = vaultUSDT.previewDeposit(amountUsdt);

        bytes[] memory data = new bytes[](1);
        bytes[] memory callbackData = new bytes[](8);

        callbackData[0] = _morphoSetAuthorizationWithSigCall(privateKey, address(bundler), true, 0);
        callbackData[1] = _morphoBorrowCall(borrowed, address(bundler));
        callbackData[2] = _morphoSetAuthorizationWithSigCall(privateKey, address(bundler), false, 1);
        callbackData[3] = _aaveV3OptimizerRepayCall(marketParams.loanToken, borrowed);
        callbackData[4] = _aaveV3OptimizerApproveManagerCall(privateKey, address(bundler), true, 0);
        callbackData[5] = _aaveV3OptimizerWithdrawCollateralCall(USDT, amountUsdt, address(bundler));
        callbackData[6] = _aaveV3OptimizerApproveManagerCall(privateKey, address(bundler), false, 1);
        callbackData[7] = _erc4626DepositCall(address(vaultUSDT), amountUsdt, address(bundler));
        data[0] = _morphoSupplyCollateralCall(erc4626Amount, user, abi.encode(callbackData));

        vm.prank(user);
        bundler.multicall(SIGNATURE_DEADLINE, data);

        _assertBorrowerPosition(erc4626Amount, borrowed, user, address(bundler));
    }

    function testMigrateSupplierWithOptimizerPermit(uint256 privateKey, uint256 supplied) public {
        address user;
        (privateKey, user) = _getUserAndKey(privateKey);
        supplied = bound(supplied, 100, 100 ether);

        deal(marketParams.loanToken, user, supplied + 1);

        vm.startPrank(user);
        ERC20(marketParams.loanToken).safeApprove(AAVE_V3_OPTIMIZER, supplied + 1);
        IAaveV3Optimizer(AAVE_V3_OPTIMIZER).supply(marketParams.loanToken, supplied + 1, user, 15);
        vm.stopPrank();

        bytes[] memory data = new bytes[](4);

        data[0] = _aaveV3OptimizerApproveManagerCall(privateKey, address(bundler), true, 0);
        data[1] = _aaveV3OptimizerWithdraw(marketParams.loanToken, supplied, address(bundler), 15);
        data[2] = _aaveV3OptimizerApproveManagerCall(privateKey, address(bundler), false, 1);
        data[3] = _morphoSupplyCall(supplied, user, hex"");

        vm.prank(user);
        bundler.multicall(SIGNATURE_DEADLINE, data);

        _assertSupplierPosition(supplied, user, address(bundler));
    }

    function testMigrateSupplierToVaultWithOptimizerPermit(uint256 privateKey, uint256 supplied) public {
        address user;
        (privateKey, user) = _getUserAndKey(privateKey);
        supplied = bound(supplied, 100, 100 ether);

        deal(marketParams.loanToken, user, supplied + 1);

        vm.startPrank(user);
        ERC20(marketParams.loanToken).safeApprove(AAVE_V3_OPTIMIZER, supplied + 1);
        IAaveV3Optimizer(AAVE_V3_OPTIMIZER).supply(marketParams.loanToken, supplied + 1, user, 15);
        vm.stopPrank();

        bytes[] memory data = new bytes[](4);

        data[0] = _aaveV3OptimizerApproveManagerCall(privateKey, address(bundler), true, 0);
        data[1] = _aaveV3OptimizerWithdraw(marketParams.loanToken, supplied, address(bundler), 15);
        data[2] = _aaveV3OptimizerApproveManagerCall(privateKey, address(bundler), false, 1);
        data[3] = _erc4626DepositCall(address(suppliersVault), supplied, user);

        vm.prank(user);
        bundler.multicall(SIGNATURE_DEADLINE, data);

        _assertVaultSupplierPosition(supplied, user, address(bundler));
    }

    function _aaveV3OptimizerApproveManagerCall(uint256 privateKey, address manager, bool isAllowed, uint256 nonce)
        internal
        view
        returns (bytes memory)
    {
        bytes32 digest = SigUtils.toTypedDataHash(
            IAaveV3Optimizer(AAVE_V3_OPTIMIZER).DOMAIN_SEPARATOR(),
            AaveV3OptimizerAuthorization(vm.addr(privateKey), manager, isAllowed, nonce, SIGNATURE_DEADLINE)
        );

        Types.Signature memory sig;
        (sig.v, sig.r, sig.s) = vm.sign(privateKey, digest);

        return abi.encodeCall(
            AaveV3OptimizerMigrationBundler.aaveV3OptimizerApproveManagerWithSig,
            (isAllowed, nonce, SIGNATURE_DEADLINE, sig)
        );
    }

    function _aaveV3OptimizerRepayCall(address underlying, uint256 amount) internal pure returns (bytes memory) {
        return abi.encodeCall(AaveV3OptimizerMigrationBundler.aaveV3OptimizerRepay, (underlying, amount));
    }

    function _aaveV3OptimizerWithdraw(address underlying, uint256 amount, address receiver, uint256 maxIterations)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeCall(
            AaveV3OptimizerMigrationBundler.aaveV3OptimizerWithdraw, (underlying, amount, receiver, maxIterations)
        );
    }

    function _aaveV3OptimizerWithdrawCollateralCall(address underlying, uint256 amount, address receiver)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeCall(
            AaveV3OptimizerMigrationBundler.aaveV3OptimizerWithdrawCollateral, (underlying, amount, receiver)
        );
    }
}
