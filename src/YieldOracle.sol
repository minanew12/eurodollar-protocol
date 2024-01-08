// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: © 2023 Rhinefield Technologies Limited

pragma solidity ^0.8.21;

import {Pausable} from "oz/security/Pausable.sol";
import {AccessControl} from "oz/access/AccessControl.sol";
import {Math} from "oz/utils/math/Math.sol";

error InsufficientUpdateDelay();
error InsufficientCommitDelay();
error PriceOutOfBounds();
error DelayOutOfBounds();

uint256 constant MIN_PRICE = 1e18; // Minimum EUIEUD price
uint256 constant NO_PRICE = 0; // Sentinel value to indicate empty

/**
 * @author  Rhinefield Technologies Limited
 * @title   YieldOracle
 * @notice  The YieldOracle contract provides the EUI yield accrual price mechanism.
 */
contract YieldOracle is AccessControl {
    uint256 public maxPriceIncrease; // Guardrail to limit how much the price can be increased in a single update
    uint256 public lastUpdate; // Timestamp of the last price update

    uint256 public updateDelay;
    uint256 public commitDelay;

    uint256 public previousPrice; // When we go from EUI to EUD
    uint256 public currentPrice; // When we go from EUD to EUI
    uint256 public nextPrice;

    // Roles
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    /**
     * @notice  Constructor to initialize the YieldOracle contract.
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        previousPrice = MIN_PRICE;
        currentPrice = MIN_PRICE;
        nextPrice = NO_PRICE;
        maxPriceIncrease = 0.1e18;

        updateDelay = 1 days;
        commitDelay = 1 hours;

        lastUpdate = block.timestamp;
    }

    /**
     * @notice Updates the price of the YieldOracle contract.
     * @param price The new price to be set.
     * @return bool Returns true if the price is successfully updated.
     */
    function updatePrice(uint256 price) external onlyRole(ORACLE_ROLE) returns (bool) {
        // Enforce at least updateDelay between updates
        if (block.timestamp < lastUpdate + updateDelay) {
            revert InsufficientUpdateDelay();
        }

        // If the previous update has not yet been committed, commit now to preserve
        // the invariant that previousPrice <= currentPrice <= nextPrice
        if (nextPrice != NO_PRICE) {
            commitPrice();
        }

        // Save value (solc lacking taint analysis here?)
        uint256 _currentPrice = currentPrice;

        // price \in [currentPrice, currentPrice + maxPriceIncrease] (both inclusive)
        if (price < _currentPrice || price - _currentPrice > maxPriceIncrease) {
            revert PriceOutOfBounds();
        }

        nextPrice = price;
        lastUpdate = block.timestamp;
        return true;
    }

    function commitPrice() public returns (bool) {
        // Save values (solc lacking taint analysis here?)
        uint256 _nextPrice = nextPrice;
        uint256 _currentPrice = currentPrice;

        // nextPrice must be set and
        if (_nextPrice == NO_PRICE || _nextPrice < _currentPrice) {
            revert PriceOutOfBounds();
        }

        if (block.timestamp < lastUpdate + commitDelay) {
            revert InsufficientCommitDelay();
        }

        previousPrice = currentPrice;
        currentPrice = nextPrice;
        nextPrice = NO_PRICE;

        return true;
    }

    /**
     * @notice Sets the maximum price increase allowed for the YieldOracle.
     * @param maxPriceIncrease_ The new maximum price increase value.
     * @return A boolean indicating whether the operation was successful.
     */
    function adminUpdateMaxPriceIncrease(uint256 maxPriceIncrease_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        maxPriceIncrease = maxPriceIncrease_;
        return true;
    }

    /**
     * @notice Sets the delay for the YieldOracle contract.
     * @param delay The new delay value to be set.
     * @return bool Returns true if the delay was successfully set.
     */
    function adminCommitDelay(uint256 delay) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        if (delay > updateDelay) {
            revert DelayOutOfBounds();
        }

        commitDelay = delay;
        return true;
    }

    /**
     * @notice Sets the delay for the YieldOracle contract.
     * @param delay The new delay value to be set.
     * @return bool Returns true if the delay was successfully set.
     */
    function adminUpdateDelay(uint256 delay) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        if (delay < commitDelay) {
            revert DelayOutOfBounds();
        }

        updateDelay = delay;
        return true;
    }

    /**
     * @notice Allows the admin to update the current price of the YieldOracle.
     * @param price The new price to be set.
     * @return A boolean indicating whether the update was successful or not.
     */
    function adminUpdateCurrentPrice(uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        if (price < MIN_PRICE || price < previousPrice) {
            revert PriceOutOfBounds();
        }

        currentPrice = price;

        return true;
    }

    /**
     * @dev Allows the admin to update the previous price of the YieldOracle contract.
     * @param price The new old price to be set.
     * @return A boolean indicating whether the update was successful or not.
     */
    function adminUpdatePreviousPrice(uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        if (price < MIN_PRICE || price > currentPrice) {
            revert PriceOutOfBounds();
        }

        previousPrice = price;

        return true;
    }

    function adminResetNextPrice() external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        nextPrice = 0;
        return true;
    }

    /**
     * @notice Function to calculate the equivalent amount of EUI tokens for a given amount of EUD tokens.
     * @param eudAmount The amount of EUD tokens for which the equivalent EUI tokens need to be calculated.
     * @return uint256 The equivalent amount of EUI tokens based on the current price from the yield oracle.
     */
    function fromEudToEui(uint256 eudAmount) public view returns (uint256) {
        return Math.mulDiv(eudAmount, 10 ** 18, currentPrice);
    }

    /**
     * @notice Function to calculate the equivalent amount of EUD tokens for a given amount of EUI tokens.
     * @param euiAmount The amount of EUI tokens for which the equivalent EUD tokens need to be calculated.
     * @return uint256 The equivalent amount of EUD tokens based on the old price from the yield oracle.
     */
    function fromEuiToEud(uint256 euiAmount) public view returns (uint256) {
        return Math.mulDiv(euiAmount, previousPrice, 10 ** 18);
    }
}
