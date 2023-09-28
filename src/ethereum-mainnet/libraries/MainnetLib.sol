// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library MainnetLib {
    /// @dev The address of the WETH contract on Ethereum mainnet.
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @dev The address of the stETH contract on Ethereum mainnet.
    address internal constant ST_ETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    /// @dev The address of the wstETH contract on Ethereum mainnet.
    address internal constant WST_ETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    /// @dev The address of AaveV2's lending pool contract on Ethereum mainnet.
    address internal constant AAVE_V2_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    /// @dev The address of DAI on Ethereum mainnet.
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
}
