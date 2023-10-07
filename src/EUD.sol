// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: © 2023 Rhinefield Technologies Limited

pragma solidity ^0.8.21;

import {Initializable} from "oz-up/proxy/utils/Initializable.sol";
import {PausableUpgradeable} from "oz-up/security/PausableUpgradeable.sol";
import {ERC20PermitUpgradeable} from "oz-up/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {UUPSUpgradeable} from "oz-up/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "oz-up/access/AccessControlUpgradeable.sol";

/**
 * @author Rhinefield Technologies Limited
 * @title EUD - Eurodollar Token
 */

contract EUD is
    Initializable,
    PausableUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    // @notice Blocklist contains addresses that are not allowed to send or receive tokens.
    mapping(address => bool) public blocklist;
    // @notice Mapping of frozen balances that cannot be transferred.
    mapping(address => uint256) public frozenBalances;

    // Roles
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant BLOCK_ROLE = keccak256("BLOCK_ROLE");
    bytes32 public constant FREEZE_ROLE = keccak256("FREEZE_ROLE");

    /**
     * @dev Modifier to check if an account is not blocked.
     * @param account The address of the account to check.
     */
    modifier notBlocked(address account) {
        if (account != address(0)) require(blocklist[account] == false, "Account is blocked");
        _;
    }

    // Events
    event AddedToBlocklist(address indexed account);
    event RemovedFromBlocklist(address indexed account);
    event Freeze(address indexed from, address indexed to, uint256 amount);
    event Release(address indexed from, address indexed to, uint256 amount);
    event Reclaim(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice Disables initializers from being called more than once.
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice  This function is called only once during the contract deployment process.
     * @notice  It sets up the EUD token with essential features and permissions.
     */
    function initialize() public initializer {
        __ERC20_init("EuroDollar", "EUD");
        __Pausable_init();
        __ERC20Permit_init("EuroDollar");
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// ---------- ERC20 FUNCTIONS ---------- ///
    /**
     * @notice Transfers tokens from msg.sender to a specified recipient.
     * @notice The sender or receiver account must not be on the blocklist.
     * @param to The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     * @return A boolean value indicating whether the transfer was successful.
     */
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

    /**
     * @notice Transfers tokens from one address to another if approval is granted.
     * @notice The sender or receiver account must not be on the blocklist.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param amount The amount of tokens to be transferred.
     * @return A boolean that indicates if the operation was successful.
     */
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

    /**
     * @notice  Hook function called before any token transfers, mints or burns.
     * @notice  Ensures that token transfers are only allowed when the contract is not paused.
     * @param   from  The address from which tokens are transferred.
     * @param   to  The address to which tokens are transferred.
     * @param   amount  The amount of tokens being transferred.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {}

    /// ---------- SUPPLY MANAGEMENT FUNCTIONS ---------- ///
    /**
     * @notice  Mints new tokens and adds them to the specified account.
     * @notice  This function can only be called by an account with the `MINT_ROLE`.
     * @notice  The recipient's account must not be on the blocklist.
     * @param   to  The address to receive the newly minted tokens.
     * @param   amount  The amount of tokens to mint to the account.
     */
    function mint(address to, uint256 amount) public onlyRole(MINT_ROLE) {
        _mint(to, amount);
    }

    /**
     * @notice  Burns a specific amount of tokens from a specified account.
     * @notice  This function can only be called by an account with the `BURN_ROLE`.
     * @param   from  The address from which tokens will be burned.
     * @param   amount  The amount of tokens to be burned.
     */
    function burn(address from, uint256 amount) public onlyRole(BURN_ROLE) {
        _burn(from, amount);
    }

    /// ---------- TOKEN MANAGEMENT FUNCTIONS ---------- ///
    /**
     * @notice  This function can only be called by an account with the `PAUSE_ROLE`.
     * @notice  Once paused, certain operations are unavailable until the contract is unpaused.
     */
    function pause() public onlyRole(PAUSE_ROLE) {
        _pause();
    }

    /**
     * @notice  This function can only be called by an account with the `PAUSE_ROLE`.
     * @notice  It resumes certain functionalities of the contract that were previously paused.
     */
    function unpause() public onlyRole(PAUSE_ROLE) {
        _unpause();
    }

    /**
     * @notice Freezes a specified amount of tokens from a specified address.
     * @notice Only callable by accounts with the `FREEZE_ROLE`.
     * @notice The `to` address will be a contract address that will hold the frozen tokens.
     * @param from The address to freeze tokens from.
     * @param to The address to transfer the frozen tokens to.
     * @param amount The amount of tokens to freeze.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function freeze(address from, address to, uint256 amount) external onlyRole(FREEZE_ROLE) returns (bool) {
        _transfer(from, to, amount);
        unchecked {
            frozenBalances[from] += amount;
        }
        emit Freeze(from, to, amount);
        return true;
    }

    /**
     * @notice Release a specified amount of frozen tokens.
     * @notice Only callable by accounts with the `FREEZE_ROLE`.
     * @param from The address that currently holds the frozen tokens.
     * @param to The address that will receive the released tokens.
     * @param amount The amount of tokens to release.
     * @return A boolean indicating whether the release was successful.
     */
    function release(address from, address to, uint256 amount) external onlyRole(FREEZE_ROLE) returns (bool) {
        require(frozenBalances[to] >= amount, "Release amount exceeds balance");
        unchecked {
            frozenBalances[to] -= amount;
        }
        _transfer(from, to, amount);
        emit Release(from, to, amount);
        return true;
    }

    /**
     * @notice Reclaims tokens from one address and mints them to another address.
     * @notice Only callable by accounts with the `FREEZE_ROLE`.
     * @notice Can be used in the event of lost user access to tokens.
     * @param from The address of the account to reclaim tokens from.
     * @param to The address of the account to mint tokens to.
     * @param amount The amount of tokens to reclaim and mint.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function reclaim(address from, address to, uint256 amount) external onlyRole(FREEZE_ROLE) returns (bool) {
        _burn(from, amount);
        _mint(to, amount);
        emit Reclaim(from, to, amount);
        return true;
    }

    /**
     * @notice  Add an address to the blocklist.
     * @notice Only callable by accounts with the `BLOCK_ROLE`.
     * @param   account The address to be added to the blocklist.
     */
    function addToBlocklist(address account) external onlyRole(BLOCK_ROLE) {
        _addToBlocklist(account);
    }

    /**
     * @notice  Remove an address from the blocklist.
     * @notice Only callable by accounts with the `BLOCK_ROLE`.
     * @param   account The address to be removed from the blocklist.
     */
    function removeFromBlocklist(address account) external onlyRole(BLOCK_ROLE) {
        _removeFromBlocklist(account);
    }

    /**
     * @notice  Add multiple addresses to the blocklist.
     * @notice Only callable by accounts with the `BLOCK_ROLE`.
     * @param   accounts The addresses to be added to the blocklist.
     */
    function addManyToBlocklist(address[] calldata accounts) external onlyRole(BLOCK_ROLE) {
        for (uint256 i; i < accounts.length; i++) {
            _addToBlocklist(accounts[i]);
        }
    }

    /**
     * @notice  Remove multiple addresses from the blocklist.
     * @notice  Only callable by accounts with the `BLOCK_ROLE`.
     * @param   accounts The addresses to be removed from the blocklist.
     */
    function removeManyFromBlocklist(address[] calldata accounts) external onlyRole(BLOCK_ROLE) {
        for (uint256 i; i < accounts.length; i++) {
            _removeFromBlocklist(accounts[i]);
        }
    }

    function _addToBlocklist(address account) internal {
        blocklist[account] = true;
        emit AddedToBlocklist(account);
    }

    function _removeFromBlocklist(address account) internal {
        blocklist[account] = false;
        emit RemovedFromBlocklist(account);
    }

    // ERC1967 Proxy
    /**
     * @notice  Internal function to authorize a contract upgrade.
     * @notice  Only accounts with the `DEFAULT_ADMIN_ROLE` can call this function.
     * @param   newImplementation  The address of the new implementation contract.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
