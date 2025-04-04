# Nautilus Stablecoin Protocol

Nautilus is a stablecoin index fund (ISC).  
It is backed by a basket of on-chain stablecoins.  
This repository contains the Solidity smart contracts for core functionality.

---
## Origin

Nautilus adapts ideas from the 1960 paper “The Case for an Unmanaged Investment Company” by Edward F. Renshaw and Paul J. Feldstein [[34](https://www.jstor.org/stable/4479808)], which advocated passive structures to improve efficiency in investment management. Drawing on this approach, Nautilus uses passive asset management principles to design a stablecoin backed by a diversified basket of on-chain assets aimed at preserving monetary quality.


## Contract List

### IndexContractUp.sol
- Main, upgradeable stablecoin index contract.
- Functions:
  - `mint()`: Accepts stablecoins and mints Nautilus tokens.
  - `redeem()`: Burns Nautilus tokens and returns stablecoins.
  - `updateIndex()`: Updates internal index weights.
- Data:
  - User balances.
  - Composition of underlying stablecoins.
  - Total supply.

### Oracle.sol
- Fetches and stores price data.
- Functions:
  - `updatePrice()`: Updates a stablecoin's price.
  - `getPrice()`: Returns latest stored price.
- Currently hard-coded for Sepolia test net. 

### DexInteraction.sol
- Executes stablecoin swaps via DEXs (Uniswap V2).
- Functions:
  - `swap()`: Swaps between two stablecoins.
  - `getAmountOut()`: Calculates expected output for a swap.
- Used for:
  - Rebalancing the basket.
  - Liquidity operations during mint/redeem.

---

## System Architecture

- Users mint Nautilus by depositing ETH, currently WETH on Sepolia test net.
- Users redeem Nautilus by burning it for underlying stablecoins.
- Prices used in minting and redemption are retrieved from Oracle.sol.
- Basket composition is adjusted by interacting with DexInteraction.sol.

### Data Flows

- Oracle.sol → IndexContractUp.sol: Price data for valuation.
- DexInteraction.sol → IndexContractUp.sol: Rebalancing and swaps.
- Users → IndexContractUp.sol: Minting and redemption.

---

## Deployment Sequence

1. Deploy `Oracle.sol`.
2. Deploy `DexInteraction.sol`.
3. Deploy `IndexContractUp.sol`, linking:
   - Oracle address.
   - DexInteraction address.

_No deployment scripts provided. Use Remix or Hardhat manually._

---

## Contract Interactions

| Contract         | External Dependencies  | Purpose                      |
|------------------|-------------------------|-------------------------------|
| IndexContractUp  | Oracle.sol, DexInteraction.sol | Stablecoin issuance and redemption |
| Oracle           | External price feeds     | Price data management         |
| DexInteraction   | DEX Router (e.g., Uniswap) | Stablecoin swaps              |

---

## Security Model

- **Oracle Integrity:**  
  Trust in external price sources is assumed.

- **DEX Liquidity:**  
  Swaps assume sufficient liquidity on decentralized exchanges.

- **Access Controls:**  
  Current version lacks detailed role-based access control (RBAC).

- **Upgradeability:**  
  No proxy pattern. Contracts are non-upgradeable in current state.

- **External Attack Surfaces:**  
  - Price oracle manipulation.
  - DEX front-running on swaps.

_No audits conducted. Use at own risk._

---

## Future Improvements and Extensions

The current version is minimal. Future technical upgrades include:

- **Dex Aggregator Integration:** Replace DexInteraction with a DEX aggregator for optimized swaps (e.g., 1inch, 0x, Paraswap).
- **Oracle Redundancy:** Add multiple price feeds per asset and medianizer contracts.
- **Access Control:** Implement role-based access control (ADMIN_ROLE, REBALANCER_ROLE, ORACLE_UPDATER_ROLE).
- **Circuit Breakers:** Emergency pause functionality for minting, redemption, and rebalancing.
- **Dynamic Basket Weights:** Adjust stablecoin allocations dynamically based on market data.
- **Slippage Protection:** Implement minimum and maximum slippage tolerances on swaps.
- **Deposit/Redemption Fees:** Add configurable fees directed to a protocol treasury.
- **Auditable Events:** Emit events for price updates, swaps, mints, and redemptions.
- **Asset Qualification Framework:** Formalize criteria for stablecoin inclusion and removal.
- **Portfolio Optimization:** Implement optimization algorithm to dynamically adjust stablecoin weights and improve basket stability and resilience (see below).

All extensions are optional but recommended for production deployment.

---

## Research Background

Portfolio optimization and stablecoin monetary quality analysis in Nautilus draw from two research efforts:

### 1. Stablecoin Basket Optimization (Hierarchical Risk Parity)

- Based on:  
  Marcos López de Prado, *"Building Diversified Portfolios that Perform Well Out-of-Sample"*, Journal of Portfolio Management, 2016.  
  [DOI Link](https://doi.org/10.3905/jpm.2016.42.4.059)

- Nautilus is to use Hierarchical Risk Parity (HRP) to optimize stablecoin weights, reducing risk through clustering highly correlated assets and improving peg robustness.

- More detailed implementation:  
  [StablecoinHRP GitHub Repository](https://github.com/elliotjames-paschal/StablecoinHRP)

---

### 2. Stablecoin Distance to No Questions Asked (NQA) Status and Monetary Quality Analysis

- Based on:  
  Gary Gorton, Chase Ross, and Sharon Ross, *"Making Money"*, NBER Working Paper, 2023.  
  [SSRN Link](https://ssrn.com/abstract=4021072)

- Nautilus draws from the No Questions Asked (NQA) framework to evaluate stablecoin quality as money. The distance to NQA measures market confidence in maintaining a stable peg and liquidity under stress.
  
- Extended in:  
  Elliot Paschal, *"A New Money Landscape"*, 2024.  
  [PDF Paper](https://github.com/elliotjames-paschal/TheNewMoneyLandscape/blob/main/A%20New%20Money%20Landscape%20-%20Elliot%20Paschal.pdf)  
  [StablecoinNQA GitHub Repository](https://github.com/elliotjames-paschal/TheNewMoneyLandscape)


- Key concepts applied:
  - Distance to No Questions Asked (NQA)
  - Convenience yield comparison
  - Stablecoin vs fiat liquidity metrics

---

## Website

The Nautilus project website is available [here](https://www.nautstable.com).

> **Note:** This is an early testing version.  
> If you would like to interact with the protocol, please email [paschal0@chicagobooth.edu] to receive the correct WETH token address for testnet interaction.

---
