// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: © 2023 Rhinefield Technologies Limited

pragma solidity ^0.8.21;

import {Pausable} from "oz/security/Pausable.sol";
import {AccessControl} from "oz/access/AccessControl.sol";
import {Math} from "oz/utils/math/Math.sol";

uint256 constant MIN_PRICE = 1e18;

/**
 * @author  Rhinefield Technologies Limited
 * @title   YieldOracle
 * @dev     A contract that implements a yield oracle for EuroInvest (EUI) based on epoch-based pricing.
 * @dev     The oracle provides price data to determine how much EuroDollar (EUD) is needed to flip to EUI tokens for each epoch.
 * @dev     The oracle allows price updates based on the `ORACLE_ROLE` and pausing functionality using the `PAUSE_ROLE`.
 */
contract YieldOracle is Pausable, AccessControl {
    uint256 public maxPriceIncrease;
    uint256 public lastUpdate;
    uint256 public delay;

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
     * @notice  The constructor sets up the contract with the specified access control address, initial prices, and the maximum price increase.
     * @dev     Constructor to initialize the YieldOracle contract.
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _oldPrice = MIN_PRICE;
        _currentPrice = MIN_PRICE;
        maxPriceIncrease = 1e17;
        delay = 1 hours;
        lastUpdate = block.timestamp;
    }

    // Pausable
    /**
     * @notice  This function can only be called by an account with the `PAUSE_ROLE`.
     * @notice  It pauses certain functionalities of the contract, preventing certain actions.
     * @notice  Once paused, certain operations may not be available until the contract is unpaused.
     * @dev     Pauses the contract functionality.
     */
    function pause() public onlyRole(PAUSE_ROLE) {
        _pause();

        _oldPricePaused = _oldPrice;
        _currentPricePaused = _currentPrice;
        _oldPrice = 0;
        _currentPrice = 0;
    }

    /**
     * @notice  This function can only be called by an account with the `PAUSE_ROLE`.
     * @notice  It resumes certain functionalities of the contract that were previously paused.
     * @notice  Once unpaused, the contract regains its full functionality.
     * @dev     Unpauses the contract functionality.
     */
    function unpause() public onlyRole(PAUSE_ROLE) {
        _unpause();

        _oldPrice = _oldPricePaused;
        _currentPrice = _currentPricePaused;
        _oldPricePaused = 0;
        _currentPricePaused = 0;
    }

    function oldPrice() public view returns (uint256) {
        uint256 oldPrice_ = _oldPrice;
        if (oldPrice_ > 0) return oldPrice_;
        return _oldPricePaused;
    }

    function currentPrice() public view returns (uint256) {
        uint256 currentPrice_ = _currentPrice;
        if (currentPrice_ > 0) return currentPrice_;
        return _currentPricePaused;
    }

    /**
     * @notice  This function is accessible only to accounts with the `ORACLE_ROLE`.
     * @notice  The new price must not exceed the allowed price increase compared to the previous epoch's price.
     * @notice  The new price must be greater than or equal to the previous epoch's price.
     * @notice  The epoch number is incremented after successful price update.
     * @dev     Function to update the price for the next epoch.
     * @param   newPrice The new price for the next epoch.
     * @return  bool    A boolean indicating the success of the price update.
     */
    function updatePrice(uint256 newPrice) external onlyRole(ORACLE_ROLE) whenNotPaused returns (bool) {
        require(block.timestamp >= lastUpdate + delay, "YieldOracle: price can only be updated after the delay period");
        // solc doesn't seem to be able to do tain-analysis on the currentPrice
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

    function setMaxPriceIncrease(uint256 maxPriceIncrease_) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        maxPriceIncrease = maxPriceIncrease_;
        return true;
    }

    function setDelay(uint256 delay_) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        delay = delay_;
        return true;
    }

    function adminUpdateCurrentPrice(uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        require(price >= MIN_PRICE, "YieldOracle: price must be greater than or equal to MIN_PRICE");

        if (paused()) {
            _currentPricePaused = price;
        } else {
            _currentPrice = price;
        }

        return true;
    }

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
     * @notice  This function is a read-only function and does not modify any state in the contract.
     * @dev     Function to calculate the equivalent amount of EUI tokens for a given amount of EUD tokens.
     * @param   eudAmount  The amount of EUD tokens for which the equivalent EUI tokens need to be calculated.
     * @return  uint256  The equivalent amount of EUI tokens based on the current price from the yield oracle.
     */
    function fromEudToEui(uint256 eudAmount) public view returns (uint256) {
        uint256 currentPrice_ = _currentPrice;
        require(currentPrice_ != 0, "Pausable: paused");

        return Math.mulDiv(eudAmount, 10 ** 18, currentPrice_);
    }

    /**
     * @notice  This function is a read-only function and does not modify any state in the contract.
     * @dev     Function to calculate the equivalent amount of EUD tokens for a given amount of EUI tokens.
     * @param   euiAmount  The amount of EUI tokens for which the equivalent EUD tokens need to be calculated.
     * @return  uint256  The equivalent amount of EUD tokens based on the previous epoch price from the yield oracle.
     */
    function fromEuiToEud(uint256 euiAmount) public view returns (uint256) {
        uint256 oldPrice_ = _oldPrice;
        require(oldPrice_ != 0, "Pausable: paused");

        return Math.mulDiv(euiAmount, oldPrice_, 10 ** 18);
    }
}
