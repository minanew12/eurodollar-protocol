// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: © 2023 Rhinefield Technologies Limited

pragma solidity ^0.8.21;

import {Pausable} from "oz/security/Pausable.sol";
import {AccessControl} from "oz/access/AccessControl.sol";
import {Math} from "oz/utils/math/Math.sol";

/**
 * @author  Rhinefield Technologies Limited
 * @title   YieldOracle
 * @notice  The YieldOracle contract provides the EUI yield accrual price mechanism.
 */
contract YieldOracle is Pausable, AccessControl {
    uint256 public constant MIN_PRICE = 1e18; // Minimum EUIEUD price
    uint256 public maxPriceIncrease; // Guardrail to limit how much the price can be increased in a single update
    uint256 public lastUpdate; // Timestamp of the last price update
    uint256 public delay; // Guardrail to limit how often the oracle can be updated

    uint256 private _oldPrice;
    uint256 private _currentPrice;

    // These next two are used as a gas optimisation to avoid the pause check in the "hot"
    // convert functions
    uint256 private _oldPricePaused;
    uint256 private _currentPricePaused;

    // Roles
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    /**
     * @notice  Constructor to initialize the YieldOracle contract.
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _oldPrice = MIN_PRICE;
        _currentPrice = MIN_PRICE;
        maxPriceIncrease = 1e17;
        delay = 1 hours;
        lastUpdate = block.timestamp;
    }

    /**
     * @notice Pauses the contract functionality.
     * @notice This function can only be called by an account with the `PAUSE_ROLE`.
     * @dev Updates variables for gas optimization.
     */
    function pause() public onlyRole(PAUSE_ROLE) {
        _pause();

        _oldPricePaused = _oldPrice;
        _currentPricePaused = _currentPrice;
        _oldPrice = 0;
        _currentPrice = 0;
    }

    /**
     * @notice Unpauses the contract functionality.
     * @notice This function can only be called by an account with the `PAUSE_ROLE`.
     */
    function unpause() public onlyRole(PAUSE_ROLE) {
        _unpause();

        _oldPrice = _oldPricePaused;
        _currentPrice = _currentPricePaused;
        _oldPricePaused = 0;
        _currentPricePaused = 0;
    }

    /**
     * @notice Returns the old price of EUI in EUD.
     * @return Returns the old price of EUI in EUD.
     */
    function oldPrice() public view returns (uint256) {
        uint256 oldPrice_ = _oldPrice;
        if (oldPrice_ > 0) return oldPrice_;
        return _oldPricePaused;
    }

    /**
     * @notice Returns the current price of EUI in EUD.
     * @return Returns the current price of EUI in EUD.
     */
    function currentPrice() public view returns (uint256) {
        uint256 currentPrice_ = _currentPrice;
        if (currentPrice_ > 0) return currentPrice_;
        return _currentPricePaused;
    }

    /**
     * @notice Updates the price of the YieldOracle contract.
     * @param newPrice The new price to be set.
     * @return bool Returns true if the price is successfully updated.
     */
    function updatePrice(uint256 newPrice) external onlyRole(ORACLE_ROLE) whenNotPaused returns (bool) {
        require(block.timestamp >= lastUpdate + delay, "YieldOracle: price can only be updated after the delay period");
        // solc doesn't seem to be able to do taint-analysis on the currentPrice
        // so we cache the value here
        uint256 currentPrice_ = _currentPrice;
        // We can assume the currentPrice is at least MIN_PRICE given other write paths,
        // and the price increase check requires the delta to be positive,
        // we can simply use the currentPrice_ here to compare
        require(newPrice >= currentPrice_, "YieldOracle: price must be greater than or equal to the current price");
        require(newPrice - currentPrice_ <= maxPriceIncrease, "YieldOracle: price increase exceeds maximum allowed");
        lastUpdate = block.timestamp;
        _oldPrice = currentPrice_;
        _currentPrice = newPrice;
        return true;
    }

    /**
     * @notice Sets the maximum price increase allowed for the YieldOracle.
     * @param maxPriceIncrease_ The new maximum price increase value.
     * @return A boolean indicating whether the operation was successful.
     */
    function setMaxPriceIncrease(uint256 maxPriceIncrease_) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        maxPriceIncrease = maxPriceIncrease_;
        return true;
    }

    /**
     * @notice Sets the delay for the YieldOracle contract.
     * @param delay_ The new delay value to be set.
     * @return bool Returns true if the delay was successfully set.
     */
    function setDelay(uint256 delay_) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        delay = delay_;
        return true;
    }

    /**
     * @notice Allows the admin to update the current price of the YieldOracle.
     * @param price The new price to be set.
     * @return A boolean indicating whether the update was successful or not.
     */
    function adminUpdateCurrentPrice(uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        require(price >= MIN_PRICE, "YieldOracle: price must be greater than or equal to MIN_PRICE");

        if (paused()) {
            _currentPricePaused = price;
        } else {
            _currentPrice = price;
        }

        return true;
    }

    /**
     * @dev Allows the admin to update the old price of the YieldOracle contract.
     * @param price The new old price to be set.
     * @return A boolean indicating whether the update was successful or not.
     */
    function adminUpdateOldPrice(uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        require(price >= MIN_PRICE, "YieldOracle: price must be greater than or equal to MIN_PRICE");

        if (paused()) {
            _oldPricePaused = price;
        } else {
            _oldPrice = price;
        }

        return true;
    }

    /**
     * @notice Function to calculate the equivalent amount of EUI tokens for a given amount of EUD tokens.
     * @param eudAmount The amount of EUD tokens for which the equivalent EUI tokens need to be calculated.
     * @return uint256 The equivalent amount of EUI tokens based on the current price from the yield oracle.
     */
    function fromEudToEui(uint256 eudAmount) public view returns (uint256) {
        uint256 currentPrice_ = _currentPrice;
        require(currentPrice_ != 0, "Pausable: paused");

        return Math.mulDiv(eudAmount, 10 ** 18, currentPrice_);
    }

    /**
     * @notice Function to calculate the equivalent amount of EUD tokens for a given amount of EUI tokens.
     * @param euiAmount The amount of EUI tokens for which the equivalent EUD tokens need to be calculated.
     * @return uint256 The equivalent amount of EUD tokens based on the old price from the yield oracle.
     */
    function fromEuiToEud(uint256 euiAmount) public view returns (uint256) {
        uint256 oldPrice_ = _oldPrice;
        require(oldPrice_ != 0, "Pausable: paused");

        return Math.mulDiv(euiAmount, oldPrice_, 10 ** 18);
    }
}
