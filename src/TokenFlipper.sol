// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "openzeppelin-contracts/contracts/utils/math/Math.sol";
import "../interfaces/IEUD.sol";
import "../interfaces/IEUI.sol";
import "../interfaces/IYieldOracle.sol";
import "./RoleControl.sol";

/**
 * @author  Fenris
 * @title   TokenFlipper
 * @dev     A contract that implements a token flipper for swapping between EuroInvest (EUI) and EuroDollar (EUD) tokens.
 * @dev     The contract allows users to flip their tokens between EUI and EUD with respect to the current yield oracle's price.
 * @dev     Only authorized accounts with specific roles are allowed to interact with the contract for access control.
 * @dev     The contract is pausable to prevent certain functionalities in emergency situations.
 */

contract TokenFlipper is Pausable, RoleControl {
    using Math for uint256;
    // event
    event flippedToEUD(
        address indexed account,
        uint256 euiAmount,
        uint256 eudAmount
    );
    event flippedToEUI(
        address indexed account,
        uint256 eudAmount,
        uint256 euiAmount
    );
    IEUD private _eud;
    IEUI private _eui;
    IYieldOracle private _yieldOracle;

    /**
     * @notice  This modifier make sure the only address can call the function is eui contract
     * @dev     modifier to check if the msg.sender is eui
     */
    modifier onlyEUI() {
        require(
            msg.sender == address(_eui),
            "Only EUI contract is allowed, you are "
        );
        _;
    }

    /**
     * @notice  The constructor sets up the contract with the specified contract addresses and access control.
     * @dev     Constructor to initialize the TokenFlipper contract.
     * @param   yieldOracleAddress The address of the yield oracle contract used for pricing.
     * @param   accessControlAddress The address of the EuroDollarAccessControl contract for role-based access control.
     */
    constructor(
        address yieldOracleAddress,
        address accessControlAddress
    ) Pausable() {
        _yieldOracle = IYieldOracle(yieldOracleAddress);
        __RoleControl_init(accessControlAddress);
    }

    /**
     * @notice  This function is accessible for eveyone.
     * @dev     Function to get the address of the EuroInvest (EUI) contract.
     * @return  address  The address of the EuroInvest contract.
     */
    function getEUI() external view returns (address) {
        return address(_eui);
    }

    /**
     * @notice  This function is accessible for eveyone.
     * @dev     Function to get the address of the EuroDollar (EUD) contract.
     * @return  address  The address of the EuroDollar contract.
     */
    function getEUD() external view returns (address) {
        return address(_eud);
    }

    /**
     * @notice  This function is accessible for eveyone.
     * @dev     Function to get the address of the oracle source contract (YieldOracle).
     * @return  address  The address of the YieldOracle contract.
     */
    function getOracleSource() external view returns (address) {
        return address(_yieldOracle);
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
     * @notice  This function is accessible only to accounts with the `ADMIN_ROLE`.
     * @dev     Function to update the address of the oracle source contract (YieldOracle).
     * @param   yieldOracleAddress  The new address of the YieldOracle contract.
     */
    function updateOracleSource(
        address yieldOracleAddress
    ) external onlyRole(ADMIN_ROLE) {
        _yieldOracle = IYieldOracle(yieldOracleAddress);
    }

    /**
     * @notice  This function is accessible only to accounts with the `ADMIN_ROLE`.
     * @dev     Function to set the address of the EUD (EuroDollar) contract.
     * @param   eudAddress  The address of the EuroDollar (EUD) contract.
     */
    function setEUD(address eudAddress) external onlyRole(ADMIN_ROLE) {
        _eud = IEUD(eudAddress);
    }

    /**
     * @notice  This function is accessible only to accounts with the `ADMIN_ROLE`.
     * @dev     Function to set the address of the EUI (EuroInvest) contract.
     * @param   euiAddress  The address of the EuroInvest (EUI) contract.
     */
    function setEUI(address euiAddress) external onlyRole(ADMIN_ROLE) {
        _eui = IEUI(euiAddress);
    }

    /**
     * @notice  This function will burn the specified amount of EUD tokens from the sender's account and mint the corresponding amount of EUI tokens to the sender's account.
     * @notice  Emits `flippedToEUI` event to indicate the successful conversion.
     * @dev     Function to flip a specified amount of EUD to EUI tokens.
     * @param   amount  The amount of EUD tokens to be converted.
     */
    function flipToEUI(uint256 amount) external {
        uint256 euiAmount = _flipToEUI(amount, msg.sender, msg.sender);
        emit flippedToEUI(msg.sender, amount, euiAmount);
    }

    /**
     * @notice  This function will burn the specified amount of EUI tokens from the sender's account and mint the corresponding amount of EUD tokens to the sender's account.
     * @notice  Emits `flippedToEUD` event to indicate the successful conversion.
     * @dev     Function to flip a specified amount of EUI to EUD tokens.
     * @param   amount  The amount of EUI tokens to be converted.
     */
    function flipToEUD(uint256 amount) external {
        uint256 eudAmount = _flipToEUD(amount, msg.sender, msg.sender);
        emit flippedToEUD(msg.sender, amount, eudAmount);
    }

    /**
     * @notice  This function can only be called by the EUI contract.
     * @notice  This function will burn the specified amount of EUD tokens from the specified owner's account and mint the corresponding amount of EUI tokens to the specified receiver's account.
     * @dev     Function to flip a specified amount of EUD to EUI tokens.
     * @param   amount  The amount of EUD tokens to be converted.
     * @param   receiver  The address where the newly minted EUI tokens will be transferred.
     * @param   owner  The address of the EUI tokens owner (who will burn the EUD tokens).
     * @return  uint256  The amount of EUI tokens that were minted to the specified receiver's account.
     */
    function flipToEUI(
        uint256 amount,
        address receiver,
        address owner
    ) external onlyEUI returns (uint256) {
        uint256 euiAmount = _flipToEUI(amount, receiver, owner);
        return euiAmount;
    }

    /**
     * @notice  This function can only be called by the EUI contract.
     * @notice  This function will burn the specified amount of EUI tokens from the specified owner's account and mint the corresponding amount of EUD tokens to the specified receiver's account.
     * @dev     Function to flip a specified amount of EUI to EUD tokens.
     * @param   amount  The amount of EUI tokens to be converted.
     * @param   receiver  The address where the newly minted EUD tokens will be transferred.
     * @param   owner  The address of the EUI tokens owner (who will burn the EUI tokens).
     * @return  uint256  The amount of EUD tokens that were minted to the specified receiver's account.
     */
    function flipToEUD(
        uint256 amount,
        address receiver,
        address owner
    ) external onlyEUI returns (uint256) {
        uint256 eudAmount = _flipToEUD(amount, receiver, owner);
        return eudAmount;
    }

    /**
     * @notice  This function is a read-only function and does not modify any state in the contract.
     * @dev     Function to calculate the equivalent amount of EUI tokens for a given amount of EUD tokens.
     * @param   eudAmount  The amount of EUD tokens for which the equivalent EUI tokens need to be calculated.
     * @return  uint256  The equivalent amount of EUI tokens based on the current price from the yield oracle.
     */
    function fromEudToEui(uint256 eudAmount) public view returns (uint256) {
        uint256 currentPrice = _yieldOracle.getPrice(_yieldOracle.epoch());
        return
            eudAmount.mulDiv(
                10 ** _eui.decimals(),
                currentPrice,
                Math.Rounding.Down
            );
    }

    /**
     * @notice  This function is a read-only function and does not modify any state in the contract.
     * @dev     Function to calculate the equivalent amount of EUD tokens for a given amount of EUI tokens.
     * @param   euiAmount  The amount of EUI tokens for which the equivalent EUD tokens need to be calculated.
     * @return  uint256  The equivalent amount of EUD tokens based on the previous epoch price from the yield oracle.
     */
    function fromEuiToEud(uint256 euiAmount) public view returns (uint256) {
        uint256 currentPrice = _yieldOracle.getPrice(_yieldOracle.epoch() - 1);
        return
            euiAmount.mulDiv(
                currentPrice,
                10 ** _eui.decimals(),
                Math.Rounding.Down
            );
    }

    /**
     * @notice  This function can only be called from within the contract and is used to perform EUD to EUI token conversion.
     * @dev     Internal function to convert EUD tokens to EUI tokens.
     * @param   amount  The amount of EUD tokens to be converted to EUI tokens.
     * @param   receiver  The address to receive the minted EUI tokens.
     * @param   owner  The address from which the EUD tokens will be burned.
     * @return  uint256  The equivalent amount of EUI tokens based on the current epoch price from the yield oracle.
     */
    function _flipToEUI(
        uint256 amount,
        address receiver,
        address owner
    ) internal whenNotPaused returns (uint256) {
        uint256 euiMintAmount = fromEudToEui(amount);
        _eud.burn(owner, amount);
        _eui.mint(receiver, euiMintAmount);
        return euiMintAmount;
    }

    /**
     * @notice  This function can only be called from within the contract and is used to perform EUI to EUD token conversion.
     * @dev     Internal function to convert EUI tokens to EUD tokens.
     * @param   amount  The amount of EUI tokens to be converted to EUD tokens.
     * @param   receiver  The address to receive the minted EUD tokens.
     * @param   owner  The address from which the EUI tokens will be burned.
     * @return  uint256  The equivalent amount of EUD tokens based on the previous epoch price from the yield oracle.
     */
    function _flipToEUD(
        uint256 amount,
        address receiver,
        address owner
    ) internal whenNotPaused returns (uint256) {
        uint256 eudMintAmount = fromEuiToEud(amount);
        _eui.burn(owner, amount);
        _eud.mint(receiver, eudMintAmount);
        return eudMintAmount;
    }
}
