// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./RoleControl.sol";

/**
 * @author  Fenris
 * @title   EUIAllowlist
 * @dev     A contract that manages an allowlist of addresses using RoleControl for access control.
 * @dev     Addresses on the allowlist are granted specific permissions within the system.
 * @dev     The contract allows adding and removing addresses from the allowlist based on the `ALLOWLIST_ROLE`.
 */
contract Allowlist is RoleControl {
    mapping(address => bool) private _allowlist;

    // event
    event addedToAllowlist(address indexed account);
    event removedFromAllowlist(address indexed account);

    /**
     * @notice  This function is called internally to add an address to the allowlist.
     * @notice  The address must not be already on the allowlist.
     * @notice  Emits an `addedToAllowlist` event upon successful addition.
     * @dev     Internal function to add an address to the allowlist.
     * @param   account The address to be added to the allowlist.
     */
    function _addToAllowlist(address account) internal {
        require(!_allowlist[account], "account is already in allowlist");
        _allowlist[account] = true;
        emit addedToAllowlist(account);
    }

    function addToAllowlist(
        address[] memory accounts
    ) external onlyRole(ALLOWLIST_ROLE) {
        for (uint256 i; i < accounts.length; i++) {
            _addToAllowlist(accounts[i]);
        }
    }

    function _removeFromAllowlist(address account) internal {
        require(_allowlist[account], "account is not in allowlist");
        _allowlist[account] = false;
        emit removedFromAllowlist(account);
    }

    /**
     * @notice  This function is accessible only to accounts with the `ALLOWLIST_ROLE`.
     * @notice  The address must be currently on the allowlist.
     * @notice  Emits a `removedFromAllowlist` event upon successful removal.
     * @dev     Allows the `ALLOWLIST_ROLE` to remove an address from the allowlist.
     * @param   accounts The address to be removed from the allowlist.
     */
    function removeFromAllowlist(
        address[] memory accounts
    ) external onlyRole(ALLOWLIST_ROLE) {
        for (uint256 i; i < accounts.length; i++) {
            _removeFromAllowlist(accounts[i]);
        }
    }

    /**
     * @notice  This function allows querying the allowlist status of an address.
     * @dev     Checks if an address is on the allowlist.
     * @param   account The address to be checked for allowlisting status.
     * @return  bool    A boolean value indicating whether the address is on the allowlist (true) or not (false).
     */
    function isAllowed(address account) public view returns (bool) {
        return _allowlist[account];
    }
}
