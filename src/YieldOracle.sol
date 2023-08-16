// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "./RoleControl.sol";

/**
 * @author  Fenris
 * @title   YieldOracle
 * @dev     A contract that implements a yield oracle for EuroInvest (EUI) based on epoch-based pricing.
 * @dev     The oracle provides price data to determine how much EuroDollar (EUD) is needed to flip to EUI tokens for each epoch.
 * @dev     The oracle allows price updates based on the `ORACLE_ROLE` and pausing functionality using the `PAUSE_ROLE`.
 */
contract YieldOracle is Pausable, RoleControl {
    uint256 public epoch;
    uint256 public price; // max price increase of EUD (compare with the previous epoch price) to buy 10^<EUI.decimals()> EUI
    mapping(uint256 => uint256) private _epochToPrice; // how much EUD to buy 10^(EUI.decimals()) EUI

    /**
     * @notice  The constructor sets up the contract with the specified access control address, initial prices, and the maximum price increase.
     * @dev     Constructor to initialize the YieldOracle contract.
     * @param   accessControlAddress The address of the EuroDollarAccessControl contract for role-based access control.
     * @param   priceEpoch0 The initial price for the first epoch (epoch 0).
     * @param   priceEpoch1 The price for the second epoch (epoch 1).
     * @param   price_ The maximum price increase allowed between epochs to buy EUI tokens.
     */
    constructor(
        address accessControlAddress,
        uint256 priceEpoch0,
        uint256 priceEpoch1,
        uint256 price_
    ) Pausable() {
        __RoleControl_init(accessControlAddress);
        _epochToPrice[epoch] = priceEpoch0;
        epoch += 1;
        _epochToPrice[epoch] = priceEpoch1;
        price = price_;
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
    }

    /**
     * @notice  This function can only be called by an account with the `PAUSE_ROLE`.
     * @notice  It resumes certain functionalities of the contract that were previously paused.
     * @notice  Once unpaused, the contract regains its full functionality.
     * @dev     Unpauses the contract functionality.
     */
    function unpause() public onlyRole(PAUSE_ROLE) {
        _unpause();
    }

    /**
     * @notice  This function allows querying the price for a specific epoch.
     * @dev     Function to get the price for a specific epoch.
     * @param   epoch_  The epoch for which the price is queried.
     * @return  uint256 The price for the given epoch to flip tokens.
     */
    function getPrice(uint256 epoch_) external view returns (uint256) {
        return _epochToPrice[epoch_];
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
    function updatePrice(
        uint256 newPrice
    ) external onlyRole(ORACLE_ROLE) whenNotPaused returns (bool) {
        require(
            newPrice - _epochToPrice[epoch] <= price,
            "New price exceeds the allowed limit"
        );
        require(
            newPrice >= _epochToPrice[epoch],
            "New price must greater than next price"
        );
        epoch += 1;
        _epochToPrice[epoch] = newPrice;
        return true;
    }

    /**
     * @notice  This function is accessible only to accounts with the `ADMIN_ROLE`.
     * @notice  It allows overwriting the price for a specific epoch, which is useful for correcting data or manual adjustments.
     * @notice  The target epoch must exist (less than or equal to the current epoch).
     * @dev     Function to overwrite the price for a specific epoch.
     * @param   targetEpoch The epoch for which the price will be overwritten.
     * @param   newPrice The new price for the specified epoch.
     */
    function overwritePrice(
        uint256 targetEpoch,
        uint256 newPrice
    ) external onlyRole(ADMIN_ROLE) {
        require(targetEpoch <= epoch, "Epoch does not exist");
        _epochToPrice[targetEpoch] = newPrice;
    }

    /**
     * @notice  This function is accessible only to accounts with the `ADMIN_ROLE`.
     * @notice  It allows setting the maximum price increase to prevent large fluctuations in price updates.
     * @dev     Function to set the maximum price increase allowed between epochs.
     * @param   newMaxPriceIncrease The new maximum price increase allowed in EUD.
     * @return  bool    A boolean indicating the success of the update.
     */
    function setMaxPriceIncrease(
        uint256 newMaxPriceIncrease
    ) external onlyRole(ADMIN_ROLE) returns (bool) {
        price = newMaxPriceIncrease;
        return true;
    }
}
