// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../interfaces/IEuroDollarAccessControl.sol";

/**
 * @author  Fenris
 * @title   RoleControl
 * @dev     An abstract contract that defines role-based access control using role identifiers as bytes32 constants.
 * @dev     Each role identifier represents a specific role within the system (ADMIN_ROLE, PAUSE_ROLE, MINT_ROLE, UPGRADER_ROLE, BURN_ROLE, BLOCKLIST_ROLE, ALLOWLIST_ROLE, ORACLE_ROLE, and FREEZER_ROLE).
 * @dev     The contract provides a modifier `onlyRole` that restricts access to functions based on the caller's role.
 */
abstract contract RoleControl {
    bytes32 public constant ADMIN_ROLE = 0x00;
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant BLOCKLIST_ROLE = keccak256("BLOCKLIST_ROLE");
    bytes32 public constant ALLOWLIST_ROLE = keccak256("ALLOWLIST_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    IEuroDollarAccessControl private _accessControl;

    /**
     * @notice  This modifier requires that the caller has the specified role, otherwise, it reverts with an error message.
     * @notice  The `__RoleControl_init` function must be called during contract initialization to set the `_accessControl` reference.
     * @dev     Modifier to restrict access to functions based on the caller's role.
     * @param   role The role identifier that the caller must have to execute the function.
     */
    modifier onlyRole(bytes32 role) {
        require(
            _accessControl.hasRole(role, msg.sender),
            "AccessControl: access denied"
        );
        _;
    }

    /**
     * @notice  This function sets the reference to the EuroDollarAccessControl contract for role-based access checks.
     * @notice  It must be called during contract initialization.
     * @dev     Internal function to initialize the RoleControl contract.
     * @param   _accessControlAddress The address of the EuroDollarAccessControl contract to be referenced for role checks.
     */
    function __RoleControl_init(address _accessControlAddress) internal {
        _accessControl = IEuroDollarAccessControl(_accessControlAddress);
    }
}
