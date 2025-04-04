// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./DexInteraction.sol";

contract StablecoinIndex is ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address[] public stablecoins;
    uint256[] public proportions;

    DexInteraction public dexInteraction;
    uint256 public mintingFee;
    uint256 public redemptionFee;
    address public feeRecipient;
    address public WETH;

    event ContractUpgraded(address indexed oldImplementation, address indexed newImplementation);
    event DexInteractionUpdated(address indexed oldDex, address indexed newDex);

    /// @notice Initializer function (replaces constructor)
    function initialize(
        address[] memory _stablecoins,
        uint256[] memory _proportions,
        address _dexInteraction,
        address _feeRecipient,
        address _WETH
    ) external initializer {
        __ERC20_init("IndexedStablecoin", "ISC");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        require(_stablecoins.length == _proportions.length, "Mismatched lengths");

        stablecoins = _stablecoins;
        proportions = _proportions;
        dexInteraction = DexInteraction(_dexInteraction);
        feeRecipient = _feeRecipient;
        WETH = _WETH;

        mintingFee = 3e16; // 3%
        redemptionFee = 3e16; // 3%
    }

    /// @notice Required function for UUPS upgrades
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    /// to upgrade the DexInteraction contract
    function setDexInteraction(address _newDexInteraction) external onlyOwner {
    require(_newDexInteraction != address(0), "Invalid address");
    emit DexInteractionUpdated(address(dexInteraction), _newDexInteraction);
    dexInteraction = DexInteraction(_newDexInteraction);
    }

    function mint(uint256 amount) external {
        uint256 scaledAmount = amount * 10**18;
        uint256 totalCost = dexInteraction.getMintingCost(amount, stablecoins, proportions);

        require(IERC20Upgradeable(WETH).transferFrom(msg.sender, address(this), totalCost), "Failed to transfer WETH");
        IERC20Upgradeable(WETH).approve(address(dexInteraction), totalCost);

        dexInteraction.mintWithToken(totalCost, stablecoins, proportions, 100);

        uint256 fee = (scaledAmount * mintingFee) / 1e18;
        _mint(msg.sender, scaledAmount - fee);
        _mint(feeRecipient, fee);
    }

    function redeem(uint256 amount) external {
        uint256 scaledAmountRedemption = amount * 10**18;
        uint256 fee = (scaledAmountRedemption * redemptionFee) / 1e18;
        uint256 amountAfterFee = scaledAmountRedemption - fee;

        require(transferFrom(msg.sender, address(this), scaledAmountRedemption), "Failed to transfer ISC");

        _burn(address(this), amountAfterFee);
        _mint(feeRecipient, fee);

        dexInteraction.executeRedemption(amountAfterFee, stablecoins, proportions, msg.sender);
    }
}
