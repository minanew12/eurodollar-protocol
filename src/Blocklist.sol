// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./RoleControl.sol";

/**
 * @author  Fenris
 * @title   Blocklist
 * @dev     A contract that manages a blocklist of addresses using RoleControl for access control.
 * @dev     Addresses on the blocklist are restricted from performing certain actions within the system.
 * @dev     The contract allows adding and removing addresses from the blocklist based on the `BLOCKLIST_ROLE`.
 * @dev     The contract also interacts with a sanctions list contract to handle special cases.
 */
contract Blocklist is RoleControl {
    mapping(address => bool) public _blocklist;

    // event
    event addedToBlocklist(address indexed account);
    event removedFromBlocklist(address indexed account);

    /**
     * @notice  This function is called internally to add an address to the blocklist.
     * @notice  The address must not be already on the blocklist.
     * @notice  Emits an `addedToBlocklist` event upon successful addition.
     * @dev     Internal function to add an address to the blocklist.
     * @param   account The address to be added to the blocklist.
     */
    function _addToBlocklist(address account) internal {
        require(!_blocklist[account], "account is already in blocklist");
        _blocklist[account] = true;
        emit addedToBlocklist(account);
    }

    /**
     * @notice  This function is accessible only to accounts with the `BLOCKLIST_ROLE`.
     * @notice  It iterates through the provided addresses and calls the internal `_addToBlocklist` function for each one.
     * @dev     Allows the `BLOCKLIST_ROLE` to add multiple addresses to the blocklist at once.
     * @param   accounts An array of addresses to be added to the blocklist.
     */
    function addToBlocklist(
        address[] memory accounts
    ) external onlyRole(BLOCKLIST_ROLE) {
        for (uint256 i; i < accounts.length; i++) {
            _addToBlocklist(accounts[i]);
        }
    }

    function _removeFromBlocklist(address account) internal {
        require(_blocklist[account], "account is not blocked");
        _blocklist[account] = false;
        emit removedFromBlocklist(account);
    }

    /**
     * @notice  This function is accessible only to accounts with the `BLOCKLIST_ROLE`.
     * @notice  The address must be currently on the blocklist.
     * @notice  Emits a `removedFromBlocklist` event upon successful removal.
     * @dev     Allows the `BLOCKLIST_ROLE` to remove an address from the blocklist.
     * @param   accounts An array of addresses to be removed from the blocklist.
     */

    function removeFromBlocklist(
        address[] memory accounts
    ) external onlyRole(BLOCKLIST_ROLE) {
        for (uint256 i; i < accounts.length; i++) {
            _removeFromBlocklist(accounts[i]);
        }
    }
    /**
     * @notice  This function allows querying the blocklist status of an address.
     * @notice  It also takes into account whether the address is on the sanctions list to handle special cases.
     * @dev     Checks if an address is on the blocklist.
     * @param   account The address to be checked for blocklisting status.
     * @return  bool A boolean value indicating whether the address is on the blocklist (true) or not (false).
     */
    function isBlocked(address account) public view returns (bool) {
        return _blocklist[account];
    }
}