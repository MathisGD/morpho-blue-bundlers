# Morpho Blue Bundlers

[Morpho Blue](https://github.com/morpho-labs/morpho-blue) is a new lending primitive that offers better rates, high capital efficiency and extended flexibility to lenders & borrowers. `morpho-blue-bundlers` hosts the logic that builds alongside the core protocol like MetaMorpho and bundlers.

## Structure

![image](https://github.com/morpho-labs/morpho-blue-bundlers/assets/3147812/23ec25d2-3280-4644-bda6-8044aaea8b4f)

Each Bundler is a domain-specific abstract layer of contract that implements some functions that can be bundled in a single call by EOAs to a single contract. They all inherit from [`BaseBundler`](./src/BaseBundler.sol) that enables bundling multiple function calls into a single `multicall(bytes[] calldata data)` call to the end bundler contract. Each chain-specific bundler is available under their chain-specific folder (e.g. [`ethereum`](./src/ethereum/)).

Some chain-specific domains are also scoped to the chain-specific folder, because they are not expected to be used on any other chain (e.g. DAI and its specific `permit` function is only available on Ethereum - see [`EthereumPermitBundler`](./src/ethereum/EthereumPermitBundler.sol)).

User-end bundlers are provided in each chain-specific folder, instanciating all the intermediary domain-specific bundlers and associated parameters (such as chain-specific protocol addresses, e.g. [`EthereumBundler`](./src/ethereum/EthereumBundler.sol)).

## Usage

Install dependencies with `yarn`.

The first time running the tests with `yarn test:forge` will build Morpho Blue.
