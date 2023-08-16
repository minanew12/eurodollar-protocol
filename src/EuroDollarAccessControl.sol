// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "openzeppelin-contracts/contracts/access/AccessControl.sol";

/**
 * @author  Fenris
 * @title   EuroDollarAccessControl
 * @dev     A contract that manages access control using the AccessControl library.
 * @dev     The contract defines different roles (PAUSE_ROLE, MINT_ROLE, UPGRADER_ROLE, BURN_ROLE, BLOCKLIST_ROLE, ALLOWLIST_ROLE, ORACLE_ROLE, and FREEZER_ROLE)
 * @dev     It allows the contract owner to grant or revoke specific roles to other accounts.
 */

contract EuroDollarAccessControl is AccessControl {
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant BLOCKLIST_ROLE = keccak256("BLOCKLIST_ROLE");
    bytes32 public constant ALLOWLIST_ROLE = keccak256("ALLOWLIST_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    /**
     * @notice  The constructor sets up the contract with the specified address having the DEFAULT_ADMIN_ROLE.
     * @notice  The DEFAULT_ADMIN_ROLE is the highest-level role with full access control.
     * @dev     Constructor to initialize the EuroDollarAccessControl contract.
     * @param   account The address of the account that will initially hold the DEFAULT_ADMIN_ROLE.
     */
    constructor(address account) {
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    // ADMIN_ROLE
    /**
     * @notice  This function allows the role admin to grant the DEFAULT_ADMIN_ROLE to another account.
     * @dev     Grants the DEFAULT_ADMIN_ROLE to a specified account.
     * @param   account The address to be granted the DEFAULT_ADMIN_ROLE.
     */
    function grantAdminRole(address account) external {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @notice  This function allows the role admin to revoke the DEFAULT_ADMIN_ROLE from another account.
     * @dev     Revokes the DEFAULT_ADMIN_ROLE from a specified account.
     * @param   account The address to revoke the DEFAULT_ADMIN_ROLE from.
     */
    function revokeAdminRole(address account) external {
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    // PAUSE_ROLE
    /**
     * @notice  This function allows the role admin to grant the PAUSE_ROLE to another account.
     * @dev     Grants the PAUSE_ROLE to a specified account.
     * @param   account The address to be granted the PAUSE_ROLE.
     */
    function grantPauseRole(address account) external {
        grantRole(PAUSE_ROLE, account);
    }

    /**
     * @notice  This function allows the role admin to revoke the PAUSE_ROLE from another account.
     * @dev     Revokes the PAUSE_ROLE from a specified account.
     * @param   account The address to revoke the PAUSE_ROLE from.
     */
    function revokePauseRole(address account) external {
        revokeRole(PAUSE_ROLE, account);
    }

    // MINT_ROLE
    /**
     * @notice  This function allows the role admin to grant the MINT_ROLE to another account.
     * @dev     Grants the MINT_ROLE to a specified account.
     * @param   account The address to be granted the MINT_ROLE.
     */
    function grantMintRole(address account) external {
        grantRole(MINT_ROLE, account);
    }

    /**
     * @notice  This function allows the role admin to revoke the MINT_ROLE from another account.
     * @dev     Revokes the MINT_ROLE from a specified account.
     * @param   account The address to revoke the MINT_ROLE from.
     */
    function revokeMintRole(address account) external {
        revokeRole(MINT_ROLE, account);
    }

    // UPGRADER_ROLE
    /**
     * @notice  This function allows the role admin to grant the UPGRADER_ROLE to another account.
     * @dev     Grants the UPGRADER_ROLE to a specified account.
     * @param   account The address to be granted the UPGRADER_ROLE.
     */
    function grantUpgraderRole(address account) external {
        grantRole(UPGRADER_ROLE, account);
    }

    /**
     * @notice  This function allows the role admin to revoke the UPGRADER_ROLE from another account.
     * @dev     Revokes the UPGRADER_ROLE from a specified account.
     * @param   account The address to revoke the UPGRADER_ROLE from.
     */
    function revokeUpgraderRole(address account) external {
        revokeRole(UPGRADER_ROLE, account);
    }

    // BURN_ROLE
    /**
     * @notice  This function allows the role admin to grant the BURN_ROLE to another account.
     * @dev     Grants the BURN_ROLE to a specified account.
     * @param   account The address to be granted the BURN_ROLE.
     */
    function grantBurnRole(address account) external {
        grantRole(BURN_ROLE, account);
    }

    /**
     * @notice  This function allows the role admin to revoke the BURN_ROLE from another account.
     * @dev     Revokes the BURN_ROLE from a specified account.
     * @param   account The address to revoke the BURN_ROLE from.
     */
    function revokeBurnRole(address account) external {
        revokeRole(BURN_ROLE, account);
    }

    // BLOCKLIST_ROLE
    /**
     * @notice  This function allows the role admin to grant the BLOCKLIST_ROLE to another account.
     * @dev     Grants the BLOCKLIST_ROLE to a specified account.
     * @param   account The address to be granted the BLOCKLIST_ROLE.
     */
    function grantBlocklistRole(address account) external {
        grantRole(BLOCKLIST_ROLE, account);
    }

    /**
     * @notice  This function allows the role admin to revoke the BLOCKLIST_ROLE from another account.
     * @dev     Revokes the BLOCKLIST_ROLE from a specified account.
     * @param   account The address to revoke the BLOCKLIST_ROLE from.
     */
    function revokeBlocklistRole(address account) external {
        revokeRole(BLOCKLIST_ROLE, account);
    }

    // ALLOWLIST_ROLE
    /**
     * @notice  This function allows the role admin to grant the ALLOWLIST_ROLE to another account.
     * @dev     Grants the ALLOWLIST_ROLE to a specified account.
     * @param   account The address to be granted the ALLOWLIST_ROLE.
     */
    function grantAllowlistRole(address account) external {
        grantRole(ALLOWLIST_ROLE, account);
    }

    /**
     * @notice  This function allows the role admin to revoke the ALLOWLIST_ROLE from another account.
     * @dev     Revokes the ALLOWLIST_ROLE from a specified account.
     * @param   account The address to revoke the ALLOWLIST_ROLE from.
     */
    function revokeAllowlistRole(address account) external {
        revokeRole(ALLOWLIST_ROLE, account);
    }

    // ORACLE_ROLE
    /**
     * @notice  This function allows the role admin to grant the ORACLE_ROLE to another account.
     * @dev     Grants the ORACLE_ROLE to a specified account.
     * @param   account The address to be granted the ORACLE_ROLE.
     */
    function grantOracleRole(address account) external {
        grantRole(ORACLE_ROLE, account);
    }

    /**
     * @notice  This function allows the role admin to revoke the ORACLE_ROLE from another account.
     * @dev     Revokes the ORACLE_ROLE from a specified account.
     * @param   account The address to revoke the ORACLE_ROLE from.
     */
    function revokeOracleRole(address account) external {
        revokeRole(ORACLE_ROLE, account);
    }

    // FREEZER_ROLE
    /**
     * @notice  This function allows the role admin to grant the FREEZER_ROLE to another account.
     * @dev     Grants the FREEZER_ROLE to a specified account.
     * @param   account The address to be granted the FREEZER_ROLE.
     */
    function grantFreezelistRole(address account) external {
        grantRole(FREEZER_ROLE, account);
    }

    /**
     * @notice  This function allows the role admin to revoke the FREEZER_ROLE from another account.
     * @dev     Revokes the FREEZER_ROLE from a specified account.
     * @param   account The address to revoke the FREEZER_ROLE from.
     */
    function revokeFreezelistRole(address account) external {
        revokeRole(FREEZER_ROLE, account);
    }

    // WITHDRAW_ROLE
    /**
     * @notice  This function allows the role admin to grant the WITHDRAW_ROLE to another account.
     * @dev     Grants the WITHDRAW_ROLE to a specified account.
     * @param   account The address to be granted the WITHDRAW_ROLE.
     */
    function grantWithdrawRole(address account) external {
        grantRole(WITHDRAW_ROLE, account);
    }

    /**
     * @notice  This function allows the role admin to revoke the WITHDRAW_ROLE from another account.
     * @dev     Revokes the WITHDRAW_ROLE from a specified account.
     * @param   account The address to revoke the WITHDRAW_ROLE from.
     */
    function revokeWithdrawRole(address account) external {
        revokeRole(WITHDRAW_ROLE, account);
    }
}
