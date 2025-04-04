// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./Oracle.sol";


contract DexInteraction {
    IUniswapV2Router02 public immutable uniswapRouter;
    address public immutable WETH;
    Oracle public immutable oracle;

    constructor(address _uniswapRouter,  address _oracle, address _WETH) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        WETH = _WETH;
        // WETH = uniswapRouter.WETH(); // Get WETH address from the router
        oracle = Oracle(_oracle);
    }
    //Event 
    event RedemptionExecuted(address indexed user, uint256 amountOut);

    function getMintingCost(
        uint256 amount,
        address[] memory stablecoins,
        uint256[] memory proportions
    ) external view returns (uint256) {
        uint256 totalCost = 0;
        for (uint256 i = 0; i < stablecoins.length; i++) {
            uint256 requiredAmount = (amount * proportions[i]) / 1e18;
            uint256 price = oracle.getPrice(stablecoins[i]);
            totalCost += requiredAmount * price;
        }
        return totalCost;
    }

    /**
     * @dev Mint stablecoin index by swapping any ERC-20 token for a basket of stablecoins.
     * @param amount Exact amount of input token to use.
     * @param stablecoins Array of stablecoin addresses in the basket.
     * @param proportions Array of proportions for each stablecoin (scaled by 1e18).
     * @param slippageTolerance Maximum allowed slippage percentage (e.g., 1% = 100).
     */
    function mintWithToken(
        uint256 amount,
        address[] memory stablecoins,
        uint256[] memory proportions,
        uint256 slippageTolerance
        // address originalSender
        ) public {
        require(stablecoins.length == proportions.length, "Length mismatch");
        require(
        IERC20(WETH).allowance(msg.sender, address(this)) >= amount,
        "Insufficient allowance: Approve the contract first."
        );

        // Transfer WETH from the user to the contract
        IERC20(WETH).transferFrom(msg.sender, address(this), amount);

        // Approve the router to spend WETH
        IERC20(WETH).approve(address(uniswapRouter), amount);

        uint256 totalStablecoinsMinted = 0;

        for (uint256 i = 0; i < stablecoins.length; i++) {
            uint256 tokenAmount = (amount * proportions[i]) / 1e18;

            // Construct the swap path: [WETH, stablecoin]
            address[] memory path;
            path = new address[](2);
            path[0] = WETH;
            path[1] = stablecoins[i];

            // Calculate minimum output with slippage tolerance
            uint256 amountOutMin = _getAmountOutMin(tokenAmount, slippageTolerance, path);

            // Perform the swap
            uint256[] memory amountsOut = uniswapRouter.swapExactTokensForTokens(
                tokenAmount,
                amountOutMin,
                path,
                address(this), // Protocol holds the stablecoins
                block.timestamp
            );

            // Track total stablecoins acquired
            totalStablecoinsMinted += amountsOut[amountsOut.length - 1];
        }

        // Mint stablecoins to the user via the Index Contract
    }

    /**
     * @dev Calculate the minimum output amount based on slippage tolerance.
     * @param amountIn Input amount for the swap.
     * @param slippageTolerance Maximum allowed slippage percentage.
     * @param path Swap path (e.g., [inputToken, WETH, outputToken]).
     * @return amountOutMin Minimum output amount after applying slippage.
     */
    function _getAmountOutMin(
        uint256 amountIn,
        uint256 slippageTolerance,
        address[] memory path
    ) internal view returns (uint256) {
        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(amountIn, path);
        uint256 expectedOutput = amountsOut[amountsOut.length - 1];
        return (expectedOutput * (10000 - slippageTolerance)) / 10000; // Apply slippage tolerance
    }

    /**
    * @dev Redeem protocol stablecoins for a basket of underlying stablecoins.
    * proportions of the underlying stablecoins to the user.
    * @param amountOut Amount of protocol stablecoin to redeem.
    * @param stablecoins Array of stablecoin addresses in the basket.
    * @param proportions Array of proportions for each stablecoin in the basket (scaled by 1e18).
    */
    function executeRedemption(
        uint256 amountOut,
        address[] memory stablecoins,
        uint256[] memory proportions,
        address user // Pass user explicitly
        ) external payable {
        require(stablecoins.length == proportions.length, "Length mismatch");
        require(amountOut > 0, "Amount must be greater than zero");

        // Validate proportions sum to 1e18
        uint256 totalProportion = 0;
        for (uint256 i = 0; i < proportions.length; i++) {
            totalProportion += proportions[i];
        }
        require(totalProportion == 999900000000000000, "Invalid proportions");

        // Transfer each stablecoin in the basket to the user
        for (uint256 i = 0; i < stablecoins.length; i++) {
            uint256 tokenAmount = (amountOut * proportions[i]) / 1e18;

            // Transfer stablecoin from the protocol's treasury to the user
            IERC20(stablecoins[i]).transfer(user, tokenAmount);
        }

        emit RedemptionExecuted(user, amountOut);
    }


    /**
     * @dev Preview the expected stablecoins minted for a given input token and amount.
     * @param amountIn Exact amount of input token to use.
     * @param stablecoins Array of stablecoin addresses in the basket.
     * @param proportions Array of proportions for each stablecoin (scaled by 1e18).
     * @return expectedMinted Amount of stablecoins expected to be minted.
     */
    function previewMint(
        uint256 amountIn,
        address[] memory stablecoins,
        uint256[] memory proportions
    ) external view returns (uint256 expectedMinted) {
        require(stablecoins.length == proportions.length, "Length mismatch");

        uint256 totalMinted = 0;
        for (uint256 i = 0; i < stablecoins.length; i++) {
            uint256 tokenAmount = (amountIn * proportions[i]) / 1e18;

            // Construct the swap path: [WETH, stablecoin]
            address[] memory path;
            path = new address[](2);
            path[0] = WETH;
            path[1] = stablecoins[i];

            // Get the estimated output for this stablecoin
            uint256[] memory amountsOut = uniswapRouter.getAmountsOut(tokenAmount, path);
            totalMinted += amountsOut[amountsOut.length - 1]; // Add to the total minted
        }

        return totalMinted;
    }
}
