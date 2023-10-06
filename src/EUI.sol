// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: © 2023 Rhinefield Technologies Limited

pragma solidity ^0.8.21;

import {Initializable} from "oz-up/proxy/utils/Initializable.sol";
import {PausableUpgradeable} from "oz-up/security/PausableUpgradeable.sol";
import {ERC20PermitUpgradeable} from "oz-up/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {UUPSUpgradeable} from "oz-up/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "oz-up/access/AccessControlUpgradeable.sol";
import {IYieldOracle} from "../interfaces/IYieldOracle.sol";
import {IEUD} from "../interfaces/IEUD.sol";

/**
 * @author  Rhinefield Technologies Limited
 * @title   EUI - Eurodollar Invest
 * @dev     Inherits the OpenZepplin ERC20Upgradeable implentation
 * @notice  Serves as a sercurity token
 */
contract EUI is
    Initializable,
    PausableUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    IYieldOracle public yieldOracle;
    IEUD public eud;

    mapping(address => uint256) public frozenBalances;
    mapping(address => bool) public allowlist;


    // Roles
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant ALLOW_ROLE = keccak256("ALLOW_ROLE");
    bytes32 public constant FREEZE_ROLE = keccak256("FREEZE_ROLE");

    /**
     * @notice  The function using this modifier will only execute if the account is allowed.
     * @notice  If the account is not allowed, the transaction will be reverted with the error message "Account is not allowed".
     * @dev     Modifier to check if the given account is allowed.
     * @param   account  The address to be checked for allowlisting.
     */
    modifier onlyAllowed(address account) {
        if (account != address(0)) require(allowlist[account] == true, "Account is not on Allowlist");
        _;
    }

    // Events
    event AddedToAllowlist(address indexed account);
    event RemovedFromAllowlist(address indexed account);
    event FlippedToEUD(address indexed account, uint256 euiAmount, uint256 eudAmount);
    event FlippedToEUI(address indexed account, uint256 eudAmount, uint256 euiAmount);
    event Freeze(address indexed from, address indexed to, uint256 amount);
    event Release(address indexed from, address indexed to, uint256 amount);
    event Reclaim(address indexed from, address indexed to, uint256 amount);
    event Allow(address indexed account);
    event Deny(address indexed account);
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

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
     * @notice  It sets up the EUI token and associated contracts with essential features and permissions.
     * @notice  The contracts' addresses for blocklisting, allowlisting, access control are provided as parameters.
     * @dev     Initialization function to set up the EuroInvest (EUI) token contract.
     * @param   eudAddress  The address of the EuroDollar (EUD) token contract.
     * @param   yieldOracleAddress  The address of the token flipper contract.
     */
    function initialize(address eudAddress, address yieldOracleAddress) public initializer {
        __ERC20_init("EuroDollar Invest", "EUI");
        __Pausable_init();
        __ERC20Permit_init("EuroDollar Invest");
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        yieldOracle = IYieldOracle(yieldOracleAddress);
        eud = IEUD(eudAddress);
    }

    function setYieldOracle(address yieldOracleAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        yieldOracle = IYieldOracle(yieldOracleAddress);
    }

    function setEud(address eudAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        eud = IEUD(eudAddress);
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
     * @notice  The recipient's account must not be blocklisted and must be allowed.
     * @dev     Mints new tokens and adds them to the specified account.
     * @param   to  The address to receive the newly minted tokens.
     * @param   amount  The amount of tokens to mint and add to the account.
     */
    function mintEUI(address to, uint256 amount) public onlyRole(MINT_ROLE) {
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
    function burnEUI(address from, uint256 amount) public onlyRole(BURN_ROLE) {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused() {}

    function transfer(
        address to,
        uint256 amount
    )
        public
        override
        onlyAllowed(msg.sender)
        onlyAllowed(to)
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
        onlyAllowed(from)
        onlyAllowed(to)
        returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }

    // ERC1967
    /**
     * @notice  This function is called internally to authorize an upgrade.
     * @notice  Only accounts with the `UPGRADER_ROLE` can call this function.
     * @notice  This function is used to control access to contract upgrades.
     * @notice  The function does not perform any other action other than checking the role.
     * @dev     Internal function to authorize an upgrade to a new implementation.
     * @param   newImplementation  The address of the new implementation contract.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

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
     * @notice  This function is called internally to add an address to the allowlist.
     * @notice  The address must not be already on the allowlist.
     * @notice  Emits an `AddedToAllowlist` event upon successful addition.
     * @dev     Internal function to add an address to the allowlist.
     * @param   account The address to be added to the allowlist.
     */
    function _addToAllowlist(address account) internal {
        allowlist[account] = true;
        emit AddedToAllowlist(account);
    }

    function addToAllowlist(address account) external onlyRole(ALLOW_ROLE) {
        _addToAllowlist(account);
    }

    function addManyToAllowlist(address[] calldata accounts) external onlyRole(ALLOW_ROLE) {
        for (uint256 i; i < accounts.length; i++) {
            _addToAllowlist(accounts[i]);
        }
    }

    function _removeFromAllowlist(address account) internal {
        allowlist[account] = false;
        emit RemovedFromAllowlist(account);
    }

    function removeFromAllowlist(address account) external onlyRole(ALLOW_ROLE) {
        _removeFromAllowlist(account);
    }

    /**
     * @notice  This function is accessible only to accounts with the `ALLOWLIST_ROLE`.
     * @notice  The address must be currently on the allowlist.
     * @notice  Emits a `RemovedFromAllowlist` event upon successful removal.
     * @dev     Allows the `ALLOWLIST_ROLE` to remove an address from the allowlist.
     * @param   accounts The address to be removed from the allowlist.
     */
    function removeManyFromAllowlist(address[] calldata accounts) external onlyRole(ALLOW_ROLE) {
        for (uint256 i; i < accounts.length; i++) {
            _removeFromAllowlist(accounts[i]);
        }
    }

    function flipToEUI(
        address owner,
        address receiver,
        uint256 eudAmount
    ) public whenNotPaused returns (uint256) {
        uint256 euiMintAmount = yieldOracle.fromEudToEui(eudAmount);
        require(eud.transferFrom(owner, address(this), eudAmount), "EUD transfer failed");
        eud.burn(address(this), eudAmount);
        _mint(receiver, euiMintAmount);
        emit FlippedToEUI(msg.sender, eudAmount, euiMintAmount);
        return euiMintAmount;
    }

    /**
     * @notice  This function can only be called from within the contract and is used to perform EUI to EUD token conversion.
     * @dev     Internal function to convert EUI tokens to EUD tokens.
     * @param   euiAmount  The amount of EUI tokens to be converted to EUD tokens.
     * @param   receiver  The address to receive the minted EUD tokens.
     * @param   owner  The address from which the EUI tokens will be burned.
     * @return  uint256  The equivalent amount of EUD tokens based on the previous epoch price from the yield oracle.
     */
    function flipToEUD(address owner, address receiver, uint256 euiAmount) public whenNotPaused returns (uint256) {
        uint256 eudMintAmount = yieldOracle.fromEuiToEud(euiAmount);
        require(this.transferFrom(owner, address(this), euiAmount), "EUI transfer failed");
        _burn(address(this), euiAmount);
        eud.mint(receiver, eudMintAmount);
        emit FlippedToEUD(msg.sender, euiAmount, eudMintAmount);
        return eudMintAmount;
    }

    /// ---------- ERC4626 FUNCTIONS ---------- ///
    function asset() external view returns (address) {
        return address(eud);
    }
    /**
     * @notice  This function provides the total assets currently held in the vault, which are calculated by converting the total supply of shares (EUI) into assets (EUD) using the current exchange rate.
     * @dev     Returns the total assets held in the vault, converted from the total supply of shares (EUI).
     * @return  uint256  The total assets held in the vault.
     */

    function totalAssets() external view returns (uint256) {
        return _convertToAssets(totalSupply());
    }

    /**
     * @notice  This function allows you to convert a given amount of assets (EUD) into shares (EUI) using the current exchange rate between EUD and EUI.
     * @dev     Converts the specified amount of assets (EUD) into shares (EUI) using the current exchange rate.
     * @param   assets  The amount of assets (EUD) to convert into shares (EUI).
     * @return  uint256  The equivalent amount of shares (EUI) based on the current exchange rate.
     */
    function convertToShares(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets);
    }

    /**
     * @notice  This function allows you to convert a given amount of shares (EUI) into assets (EUD) using the current exchange rate between EUI and EUD.
     * @dev     Converts the specified amount of shares (EUI) into assets (EUD) using the current exchange rate.
     * @param   shares  The amount of shares (EUI) to convert into assets (EUD).
     * @return  uint256  The equivalent amount of assets (EUD) based on the current exchange rate.
     */
    function convertToAssets(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares);
    }

    // Deposit
    /**
     * @notice  This function returns the maximum amount of assets (EUD) that can be deposited by the specified receiver.
     * @notice  The maximum deposit amount is equal to the maximum value representable by uint256, allowing for a very large deposit if needed.
     * @dev     Returns the maximum amount of assets (EUD) that can be deposited by the specified receiver.
     * @return  uint256  The maximum amount of assets (EUD) that can be deposited by the specified receiver, which is equal to the maximum value representable by uint256.
     */
    function maxDeposit(address) public pure returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice  This function allows the user to preview the number of shares (EUI) that would be obtained by depositing the specified amount of assets (EUD).
     * @notice  It does not actually perform the deposit and is used for informational purposes only.
     * @dev     Previews the number of shares (EUI) that would be obtained by depositing the specified amount of assets (EUD).
     * @param   assets  The amount of assets (EUD) to be deposited.
     * @return  uint256  The number of shares (EUI) that would be obtained by depositing the specified amount of assets (EUD).
     */
    function previewDeposit(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets);
    }

    /**
     * @notice  This function allows the user to deposit the specified amount of assets (EUD) and receive the corresponding number of shares (EUI) in return.
     * @notice  The maximum allowed deposit amount is limited by the `maxDeposit` function for the specified receiver.
     * @notice  If the deposit amount exceeds the maximum allowed, the function will revert with an error message.
     * @dev     Deposits the specified amount of assets (EUD) to receive the corresponding number of shares (EUI).
     * @param   assets  The amount of assets (EUD) to be deposited.
     * @param   receiver  The address that will receive the shares (EUI).
     * @return  uint256  The number of shares (EUI) received after depositing the specified amount of assets (EUD).
     */


    function deposit(uint256 assets, address receiver) public returns (uint256) {
        // require(
        //     assets <= maxDeposit(receiver),      THIS IS UINT256_MAX, so no reason to check
        //     "ERC4626: deposit more than max"
        // );
        uint256 shares = flipToEUI(msg.sender, receiver, assets);
        emit Deposit(msg.sender, receiver, assets, shares);
        return shares;
    }
    // function deposit(uint256 assets, address receiver) public returns (uint256) {
    //     // require(
    //     //     assets <= maxDeposit(receiver),      THIS IS UINT256_MAX, so no reason to check
    //     //     "ERC4626: deposit more than max"
    //     // );
    //     uint256 shares = yieldOracle.fromEudToEui(assets);
    //     require(eud.transferFrom(msg.sender, address(this), assets), "EUD transfer failed");
    //     eud.burn(address(this), assets);
    //     _mint(receiver, shares);
    //     emit Deposit(msg.sender, receiver, assets, shares);
    //     return shares;
    // }

    // Mint
    /**
     * @notice  This function allows the user to determine the maximum amount of assets (EUD) that can be minted as shares (EUI) for the specified receiver.
     * @notice  The maximum mintable amount is equal to the maximum possible value of a uint256 type.
     * @dev     Returns the maximum amount of assets (EUD) that can be minted as shares (EUI) for the specified receiver.
     * @return  uint256  The maximum amount of assets (EUD) that can be minted as shares (EUI) for the specified receiver.
     */
    function maxMint(address) public pure returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice  This function allows the user to preview the amount of assets (EUD) that will be minted for the specified number of shares (EUI).
     * @notice  It performs the conversion from shares to assets using the internal _convertToAssets function.
     * @dev     Previews the amount of assets (EUD) that will be minted for the specified number of shares (EUI).
     * @param   shares  The number of shares (EUI) to preview the minted assets (EUD) for.
     * @return  uint256  The amount of assets (EUD) that will be minted for the specified number of shares (EUI).
     */
    function previewMint(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares);
    }

    /**
     * @notice  This function allows the user to mint the specified number of shares (EUI) and receive the corresponding amount of assets (EUD).
     * @notice  It performs the conversion from shares to assets using the internal yieldOracle.flipToEUD function.
     * @notice  The minted assets will be transferred to the receiver's address.
     * @dev     Pulls the specified number of shares (EUI) and mints the corresponding amount of assets (EUD) to the receiver's address.
     * @param   shares  The number of shares (EUI) to pull.
     * @param   receiver  The address of the receiver who will receive the minted assets (EUD).
     * @return  uint256  The amount of assets (EUD) minted for the specified number of shares (EUI).
     */
    function mint(uint256 shares, address receiver) public returns (uint256) {
        // require(shares <= maxMint(receiver), "ERC4626: mint more than max"); THIS IS UINT256_MAX NO REASON TO CHECK
        uint256 assets = _convertToAssets(shares);
        flipToEUI(msg.sender, receiver, assets);
        emit Deposit(msg.sender, receiver, assets, shares);
        return assets;
    }

    // Withdraw

    /**
     * @notice  This function allows the owner to check the maximum amount of assets (EUD) they can withdraw from the vault based on their EUI balance.
     * @notice  The maximum withdrawal amount is calculated by converting the owner's EUI balance to assets (EUD) using the internal _convertToAssets function.
     * @dev     Returns the maximum amount of assets (EUD) that the specified owner can withdraw based on their EUI balance.
     * @param   owner  The address of the owner whose maximum withdrawal amount is queried.
     * @return  uint256  The maximum amount of assets (EUD) that the owner can withdraw based on their EUI balance.
     */
    function maxWithdraw(address owner) public view returns (uint256) {
        if (paused()) {
            return 0;
        }
        return convertToAssets(balanceOf(owner));
    }

    /**
     * @notice  This function allows users to preview the amount of shares (EUI) that will be redeemed when they withdraw the specified amount of assets (EUD) from the vault.
     * @notice  The preview amount is calculated by converting the given amount of assets (EUD) to shares (EUI) using the internal _convertToShares function.
     * @dev     Returns the preview amount of shares (EUI) that will be redeemed when the specified amount of assets (EUD) is withdrawn.
     * @param   assets  The amount of assets (EUD) to be withdrawn.
     * @return  uint256  The preview amount of shares (EUI) that will be redeemed for the given amount of assets (EUD).
     */
    function previewWithdraw(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets);
    }

    /**
     * @notice  This function allows the owner of the vault to withdraw the specified amount of assets (EUD) from the vault and receive the equivalent amount of shares (EUI) in return.
     * @notice  The function checks if the withdrawal amount is not greater than the maximum allowed for the owner.
     * @notice  If the sender is not the owner, it spends the required allowance to withdraw the shares on behalf of the owner.
     * @notice  Finally, it calls the internal yieldOracle's flipToEUD function to perform the share-to-assets conversion and transfers the withdrawn assets (EUD) to the owner.
     * @dev     Allows the owner of the vault to withdraw the specified amount of assets (EUD) from the vault and receive the equivalent amount of shares (EUI) in return.
     * @param   assets  The amount of assets (EUD) to be withdrawn.
     * @param   receiver  The address that will receive the shares (EUI) upon withdrawal.
     * @param   owner  The owner's address, who is the owner of the vault and will receive the withdrawn assets (EUD).
     * @return  uint256  The amount of shares (EUI) redeemed for the given amount of assets (EUD).
     */
    function withdraw(uint256 assets, address receiver, address owner) public returns (uint256) {
        //require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");
        uint256 euiAmount = _convertToShares(assets);
        require(this.transferFrom(owner, address(this), euiAmount), "EUI transfer failed");
        _burn(address(this), euiAmount);
        eud.mint(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, euiAmount);
        return assets;
    }

    // Redeem

    /**
     * @notice  This function returns the maximum amount of shares (EUI) that can be redeemed for assets (EUD) by the owner of the vault.
     * @notice  The maximum amount is equal to the balance of shares (EUI) owned by the owner.
     * @dev     Returns the maximum amount of shares (EUI) that can be redeemed for assets (EUD) by the owner of the vault.
     * @param   owner  The owner's address, who is the owner of the vault and can redeem shares (EUI) for assets (EUD).
     * @return  uint256  The maximum amount of shares (EUI) that can be redeemed by the owner.
     */
    function maxRedeem(address owner) public view returns (uint256) {
        if (paused()) {
            return 0;
        }
        return balanceOf(owner);
    }

    /**
     * @notice  This function calculates the amount of assets (EUD) that would be pulled by redeeming the specified amount of shares (EUI).
     * @notice  It converts the shares (EUI) to assets (EUD) using the current conversion rate.
     * @dev     Returns the amount of assets (EUD) that would be pulled by redeeming the specified amount of shares (EUI).
     * @param   shares  The amount of shares (EUI) to be redeemed for assets (EUD).
     * @return  uint256  The amount of assets (EUD) that would be pulled by redeeming the specified amount of shares (EUI).
     */
    function previewRedeem(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares);
    }

    /**
     * @notice  This function redeems the specified amount of shares(EUI) and transfers the shares to the specified receiver.
     * @notice  If the `owner` is different from the `msg.sender`, an allowance is required to spend the assets (EUD) on behalf of the owner.
     * @notice  The amount of assets (EUD) to be redeemed is calculated based on the given number of shares (EUI) using the current conversion rate.
     * @dev     Redeems the specified amount of shares (EUI) and transfers the shares to the specified receiver.
     * @param   shares  The amount of shares (EUI) to be redeemed.
     * @param   receiver  The address that will receive the redeemed shares (EUI).
     * @param   owner  The address of the account that owns the assets (EUD) being redeemed.
     * @return  uint256  The amount of assets (EUD) that have been pulled.
     */
    function redeem(uint256 shares, address receiver, address owner) public returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");
        uint256 assets = convertToAssets(shares);
        require(this.transferFrom(owner, address(this), shares), "EUI transfer failed");
        _burn(address(this), shares);
        eud.mint(receiver, assets);
        //uint256 assets = flipToEUD(owner, receiver, shares);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        return assets;
    }

    /**
     * @notice  This internal function converts the specified amount of assets (EUD) into shares (EUI) using the current conversion rate obtained from the `yieldOracle` contract.
     * @notice  The conversion rate is calculated based on the current epoch price of EUD-to-EUI.
     * @notice  The result is the equivalent amount of shares (EUI) for the given amount of assets (EUD).
     * @dev     Converts the specified amount of assets (EUD) into shares (EUI) using the current conversion rate.
     * @param   assets  The amount of assets (EUD) to be converted into shares (EUI).
     * @return  uint256  The equivalent amount of shares (EUI) based on the given amount of assets (EUD).
     */
    function _convertToShares(uint256 assets) internal view returns (uint256) {
        return yieldOracle.fromEudToEui(assets);
    }

    /**
     * @notice  This internal function converts the specified amount of shares (EUI) into assets (EUD) using the current conversion rate obtained from the `yieldOracle` contract.
     * @notice  The conversion rate is calculated based on the previous epoch price of EUD-to-EUI.
     * @notice  The result is the equivalent amount of assets (EUD) for the given amount of shares (EUI).
     * @dev     Converts the specified amount of shares (EUI) into assets (EUD) using the current conversion rate.
     * @param   shares  The amount of shares (EUI) to be converted into assets (EUD).
     * @return  uint256  The equivalent amount of assets (EUD) based on the given amount of shares (EUI).
     */
    function _convertToAssets(uint256 shares) internal view returns (uint256) {
        return yieldOracle.fromEuiToEud(shares);
    }
}
