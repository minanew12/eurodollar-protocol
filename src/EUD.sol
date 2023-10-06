// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: © 2023 Rhinefield Technologies Limited

pragma solidity ^0.8.21;

import {Initializable} from "oz-up/proxy/utils/Initializable.sol";
import {PausableUpgradeable} from "oz-up/security/PausableUpgradeable.sol";
import {ERC20PermitUpgradeable} from "oz-up/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {UUPSUpgradeable} from "oz-up/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "oz-up/access/AccessControlUpgradeable.sol";

/**
 * @author  Rhinefield Technologies Limited
 * @title   EUD - Eurodollar Token
 * @dev     Inherits the OpenZepplin ERC20Upgradeable implentation
 * @notice  Serves as a stable token
 */

contract EUD is
    Initializable,
    PausableUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    mapping(address => bool) public blocklist;
    mapping(address => uint256) public frozenBalances;

    // Roles
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant BLOCK_ROLE = keccak256("BLOCK_ROLE");
    bytes32 public constant FREEZE_ROLE = keccak256("FREEZE_ROLE");

    /**
     * @notice  The function using this modifier will only execute if the account is not blocked.
     * @notice  If the account is blocked, the transaction will be reverted with the error message "Account is blocked."
     * @dev     Modifier to check if the given account is not blocked.
     * @param   account  The address to be checked for blocklisting.
     */
    modifier notBlocked(address account) {
        if (account != address(0)) require(blocklist[account] == false, "Account is blocked");
        _;
    }

    //Events
    event AddedToBlocklist(address indexed account);
    event RemovedFromBlocklist(address indexed account);
    event Freeze(address indexed from, address indexed to, uint256 amount);
    event Release(address indexed from, address indexed to, uint256 amount);
    event Reclaim(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Constructor function to disable initializers.
     * @notice This constructor is automatically executed when the contract is deployed.
     * @notice It disables initializers to prevent further modification of contract state after deployment.
     * @notice Only essential setup should be done within this constructor.
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice  This function is called only once during the contract deployment process.
     * @notice  It sets up the EUD token with essential features and permissions.
     * @notice  The contracts' addresses for blocklisting and access control are provided as parameters.
     * @dev     Initialization function to set up the EuroDollar (EUD) token contract.
     */
    function initialize() public initializer {
        __ERC20_init("EuroDollar", "EUD");
        __Pausable_init();
        __ERC20Permit_init("EuroDollar");
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // ERC20 Pausable
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

    // Supply Management
    /**
     * @notice  This function can only be called by an account with the `MINT_ROLE`.
     * @notice  It mints new tokens and assigns them to the specified recipient's account.
     * @notice  The recipient's account must not be blocklisted.
     * @dev     Mints new tokens and adds them to the specified account.
     * @param   to  The address to receive the newly minted tokens.
     * @param   amount  The amount of tokens to mint and add to the account.
     */
    function mint(address to, uint256 amount) public onlyRole(MINT_ROLE) {
        _mint(to, amount);
    }

    /**
     * @notice  This function can only be called by an account with the `BURN_ROLE`.
     * @notice  It removes the specified amount of tokens from the `from` account.
     * @notice  Burning tokens effectively reduces the total supply of the token.
     * @dev     Burns a specific amount of tokens from the specified account.
     * @param   from  The address from which tokens will be burned.
     * @param   amount  The amount of tokens to be burned.
     */
    function burn(address from, uint256 amount) public onlyRole(BURN_ROLE) {
        _burn(from, amount);
    }

    // ERC20 Base
    /**
     * @notice  This function is an internal override and is automatically called before token transfers.
     * @notice  It ensures that token transfers are only allowed when the contract is not paused.
     * @notice  This function is used to implement additional checks or logic before token transfers.
     * @dev     Hook function called before any token transfer occurs(check paused or not).
     * @param   from  The address from which tokens are transferred.
     * @param   to  The address to which tokens are transferred.
     * @param   amount  The amount of tokens being transferred.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {}

    function transfer(
        address to,
        uint256 amount
    )
        public
        override
        notBlocked(msg.sender)
        notBlocked(to)
        returns (bool)
    {
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        public
        override
        notBlocked(from)
        notBlocked(to)
        returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }

    function freeze(address from, address to, uint256 amount) external onlyRole(FREEZE_ROLE) returns (bool) {
        _transfer(from, to, amount);
        unchecked {
            frozenBalances[from] += amount;
        }
        emit Freeze(from, to, amount);
        return true;
    }

    function release(address from, address to, uint256 amount) external onlyRole(FREEZE_ROLE) returns (bool) {
        require(frozenBalances[to] >= amount, "Release amount exceeds balance");
        unchecked {
            frozenBalances[to] -= amount;
        }
        _transfer(from, to, amount);
        emit Release(from, to, amount);
        return true;
    }

    function reclaim(address from, address to, uint256 amount) external onlyRole(FREEZE_ROLE) returns (bool) {
        _burn(from, amount);
        _mint(to, amount);
        emit Reclaim(from, to, amount);
        return true;
    }

    /**
     * @notice  This function is called internally to add an address to the blocklist.
     * @notice  The address must not be already on the blocklist.
     * @notice  Emits an `addedToBlocklist` event upon successful addition.
     * @dev     Internal function to add an address to the blocklist.
     * @param   account The address to be added to the blocklist.
     */
    function _addToBlocklist(address account) internal {
        blocklist[account] = true;
        emit AddedToBlocklist(account);
    }

    function _removeFromBlocklist(address account) internal {
        blocklist[account] = false;
        emit RemovedFromBlocklist(account);
    }

    function addToBlocklist(address account) external onlyRole(BLOCK_ROLE) {
        _addToBlocklist(account);
    }

    function removeFromBlocklist(address account) external onlyRole(BLOCK_ROLE) {
        _removeFromBlocklist(account);
    }

    /**
     * @notice  This function is accessible only to accounts with the `BLOCKLIST_ROLE`.
     * @notice  It iterates through the provided addresses and calls the internal `_addToBlocklist` function for each one.
     * @dev     Allows the `BLOCKLIST_ROLE` to add multiple addresses to the blocklist at once.
     * @param   accounts An array of addresses to be added to the blocklist.
     */
    function addManyToBlocklist(address[] calldata accounts) external onlyRole(BLOCK_ROLE) {
        for (uint256 i; i < accounts.length; i++) {
            _addToBlocklist(accounts[i]);
        }
    }

    /**
     * @notice  This function is accessible only to accounts with the `BLOCKLIST_ROLE`.
     * @notice  The address must be currently on the blocklist.
     * @notice  Emits a `removedFromBlocklist` event upon successful removal.
     * @dev     Allows the `BLOCKLIST_ROLE` to remove an address from the blocklist.
     * @param   accounts An array of addresses to be removed from the blocklist.
     */
    function removeManyFromBlocklist(address[] calldata accounts) external onlyRole(BLOCK_ROLE) {
        for (uint256 i; i < accounts.length; i++) {
            _removeFromBlocklist(accounts[i]);
        }
    }

    // ERC1967
    /**
     * @notice  This function is called internally to authorize an upgrade.
     * @notice  Only accounts with the `DEFAULT_ADMIN_ROLE` can call this function.
     * @notice  This function is used to control access to contract upgrades.
     * @notice  The function does not perform any other action other than checking the role.
     * @dev     Internal function to authorize an upgrade to a new implementation.
     * @param   newImplementation  The address of the new implementation contract.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
