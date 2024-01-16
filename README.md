# Eurodollar Protocol

## System overview

The Eurodollar Protocol consists of two tokens, EUD a compliant USD stablecoin and EUI, a compliant yield token, and a price oracle, which allows seamless conversion between the two tokens. The system is designed to be compliant with EU regulation regarding stablecoins (MICA) and security tokens (MIFID2).
The solutions utilizes OpenZeppelin contracts for the tokens, to ensure upgradeability is implemented.

## EUD

- Inherits OpenZeppelinUpgradeable contracts:
    - `Initializable` - For upgradeability.
    - `PauseableUpgradeable` - To pause contract functions
    - `ERC20PermitUpgradeability` - ERC20 token functionality including permit function
    - `UUPSUpgradeable` - Upgradeability
    - `AccessControlUpgradeable` - For role based permissioning
- Mappings
    - `blocklist`: A list of addresses that should not be able to transfer or receive EUD tokens.
    - `frozenBalances`: List of addresses and their frozenBalances.
- Constants
    - `Roles` used for `AccessControl` permission scheme
- Modifiers
    - `notBlocked`
        - Checks if an address is in the `blocklist`. Used in transfer functions.
- Functions
    - `constructor` - calls `Initializable._disableInitializers`, to ensure contract can only be initialized once.
    - `initialize` - the "constructor” for upgradeable contracts. Sets fields in the EUD contract, and initializes inherited contracts. Sets the deployer as `DEFAULT_ADMIN_ROLE`. We will use deploy scripts to ensure ownership is transferred to another address if needed.
    - `transfer` - Overrides OpenZeppelin ERC20Upgradeable transfer, and implements check whether the sender or receiver is on the `blocklist`. Also calls the hook function `_beforeTokenTransfer` which checks whether the system is paused.
    - `transferFrom` - Overrides OpenZeppelin `ERC20Upgradeable` `transferFrom`, and implements check whether the sender or receiver is on the `blocklist`. Also calls the hook function `_beforeTokenTransfer` which checks whether the system is paused.
    - `_beforeTokenTransfer` - Hook function called before any transfer, burn or mint functionality. Overrides OpenZeppelin implementation with a check to see if the system is paused.
    - `mint` - Calls the internal `mint` function of `ERC20Upgradeable`, to mint specified amount of EUD to a specified address. Can only be called by addresses with the `MINT_ROLE`.
    - `burn` - Calls the internal `burn` function of `ERC20Upgradeable`, to burn specified amount of EUD from a specified address. Can only be called by addresses with the `BURN_ROLE`.
    - `pause` - Calls the internal `PausableUpgradeable._pause()` function to pause all EUD transfers, minting and burning. Can only be called by addresses with the `PAUSE_ROLE`.
    - `unpause` - Calls the internal `PausableUpgradeable._unpause()` function to resume all EUD transfers, minting and burning. Can only be called by addresses with the `PAUSE_ROLE`.
    - `freeze` - Calls the internal `_transfer` function of `ERC20Upgradeable` to transfer any EUD to any account. In practice, this function will only be used as a gas efficient way to freeze a subset of tokens, by moving them from a user wallet to a dedicated smart contract that will hold the tokens until they are released. A frozenBalances mapping keeps tabs on how many frozen tokens a specific address has. This negates the need to check a frozen mapping for each transfer. Can only be called by addresses with the `FREEZE_ROLE`.
    - `release` - Opposite of freeze. Calls the internal `_transfer` function of `ERC20Upgradeable` to transfer EUD tokens from any account to an address with a `frozenBalance`. In practice, this function will only be used to move tokens that have been previously frozen by being moved to a dedicated smart contract to custody frozen tokens, back to the original owner of the tokens. It will subtract the amount of frozen tokens from the `frozenBalances` mapping. Can only be called by addresses with the `FREEZE_ROLE`.
    - `reclaim` - A more flexible function to reclaim lost tokens, e.g. tokens sent to dead addresses or due to lost private keys. Can send any EUD tokens to any address. Are only used as a last resort. Can only be called by addresses with the `FREEZE_ROLE`.
    - `addToBlocklist` - A function to add an address to the `blocklist`. Can only be called by addresses with the `BLOCK_ROLE`.
    - `addManyToBlocklist` - A function to add an array of addresses to the `blocklist`. Can only be called by addresses with the `BLOCK_ROLE`.
    - `removeFromBlocklist` - A function to remove an address from the blocklist. Can only be called by addresses with the `BLOCK_ROLE`.
    - `removeManyFromBlocklist` - A function to remove an array of addresses from the `blocklist`. Can only be called by addresses with the `BLOCK_ROLE`.
    - `_authorizeUpgrade` - An internal function to point the ERC1967 Proxy to a new implementation contract.  Can only be called by addresses with the `DEFAULT_ADMIN_ROLE`.

## EUI

- Inherits `OpenZeppelinUpgradeable` contracts:
    - `Initializable` - For upgradeability.
    - `PauseableUpgradeable` - To pause contract functions
    - `ERC20PermitUpgradeability` - ERC20 token functionality including permit function
    - `UUPSUpgradeable` - Upgradeability
    - `AccessControlUpgradeable` - For role based permissioning
- Mappings
    - `allowlist`: A list of addresses that are able to transfer and receive EUI tokens.
    - `frozenBalances`: List of addresses and their frozenBalances.
- Fields
    - `yieldOracle` - address of the `YieldOracle` contract
    - `eud` - address of the `EUD` token contract
- Constants
    - `Roles` used for `AccessControl` permission scheme
- Modifiers
    - `onlyAllowed`
        - Checks if an address is in the `allowlist`. Used in transfer functions.
- Functions
    - `constructor` - calls `Initializable._disableInitializers`, to ensure contract can only be initialized once.
    - `initialize` - the "constructor” for upgradeable contracts. Sets fields in the `EUI` contract, and initializes inherited contracts. Sets the deployer as `DEFAULT_ADMIN_ROLE`. We will use deploy scripts to ensure ownership is transferred to another address if needed.
    - `transfer` - Overrides OpenZeppelin `ERC20Upgradeable` `transfer`, and implements check whether the sender or receiver is on the `allowlist`. Also calls the hook function `_beforeTokenTransfer` which checks whether the system is paused.
    - `transferFrom` - Overrides OpenZeppelin `ERC20Upgradeable` `transferFrom`, and implements check whether the sender or receiver is on the `allowlist`. Also calls the hook function `_beforeTokenTransfer` which checks whether the system is paused.
    - `_beforeTokenTransfer` - Hook function called before any transfer, burn or mint functionality. Overrides OpenZeppelin implementation with a check to see if the system is paused.
    - `mintEUI` - Calls the internal `mint` function of `ERC20Upgradeable`, to mint specified amount of EUI to a specified address. Note, this function is called mintEUI due to collision with the ERC4626 interface mint function. Can only be called by addresses with the `MINT_ROLE`.
    - `burnEUI` - Calls the internal `burn` function of `ERC20Upgradeable`, to burn specified amount of EUI from a specified address. Can only be called by addresses with the `BURN_ROLE`.
    - `flipToEui` - Uses the `YieldOracle` to fetch the EUIEUD price to calculate how much EUI to mint based on the provided amount of EUD. Transfers the specified EUD amount from the owner to the EUI contract, burns the specified EUD amount, and mints the corresponding EUI amount to the specified receiver.
    - `flipToEud` - Uses the `YieldOracle` to fetch the EUIEUD price to calculate how much EUD to mint based on the provided amount of EUI. Transfers the specified EUI amount from the owner to the EUI contract, burns the specified EUI amount, and mints the corresponding EUD amount to the specified receiver.
    - `asset` - ERC4626. Returns the asset address - the EUD address.
    - `totalAssets` - ERC4626. Returns the total amount of EUD backing EUI in this contract. I.e. the staked amount of EUD including yield and fees. Returns the amount of EUD you would get if you redeemed all EUI.
    - `convertToShares` - ERC4626. calls the `YieldOracle.fromEudToEui` function to convert a specific amount of EUD to EUI using the prices in the Yield Oracle contract.
    - `convertToAssets` - ERC4626. calls the `YieldOracle.fromEuiToEud` function to convert a specific amount of EUI to EUD using the prices in the Yield Oracle contract.
    - `maxDeposit` - ERC4626. Returns the maximum amount of EUD that can be deposited into the contract. According to the interface, this should be `uint256_max`, if we do not have any specific limit. See https://eips.ethereum.org/EIPS/eip-4626. Returns 0 if paused.
    - `previewDeposit` - ERC4626. Returns the amount of EUI you can expect to get for the provided amount fo EUD when calling the deposit function.
    - `deposit` - ERC4626. Equivalent to `flipToEui`. Checks if you try to deposit more than max. Transfers specified amount of EUD from `msg.sender` to the `EUI` contract, and mints corresponding EUI to the `receiver` based on the Yield Oracle pricing.
    - `maxMint` - ERC4626. Returns the max amount of EUI that can be minted. According to the interface should be `uint256_max` if there is no specific limit. See https://eips.ethereum.org/EIPS/eip-4626. Returns 0 if paused.
    - `previewMint` - ERC4626. Returns the amount of EUD you need to deposit to mint the specified amount of EUI.
    - `mint` - ERC4626. Deposits the necessary amount of EUD into the contract based on the specified amount of EUI the user wants to mint for the receiver address. Transfers EUD from the `msg.sender` and mints EUI to the `receiver` based on the Yield Oracle pricing.
    - `maxWithdraw` - ERC4626. Returns that maximum amount of EUD a specific address can withdraw from the contract. Calculates this by calling `convertToAssets` of the owner's EUI token balance. If paused, returns 0.
    - `previewWithdraw` - ERC4626. Returns the amount of EUI the user must deposit to withdraw the specified amount of EUD tokens. Uses `convertToShares`, which uses the `YieldOracle.fromEudToEui` to calculate this.
    - `withdraw` - ERC4626. Withdraws the specified amount of EUD from the contract to the receiver. Deposits necessary EUI tokens from the owner (requires approval) based on the Yield Oracle pricing into the contract, which are subsequently burnt. EUD tokens are then minted to the `receiver`.
    - `maxRedeem` - ERC4626. Returns how many EUI tokens a user can redeem for EUD, which is simply all of this token balance. If paused, returns 0.
    - `previewRedeem` - ERC4626. Returns how many EUD tokens a user can expect from redeeming a specific amount of EUI tokens. Uses `convertToAssets`, which uses the `YieldOracle.fromEuiToEud` to calculate this.
    - `redeem` - ERC4626. Redeems the specified amount of EUI tokens for EUD tokens based on the YieldOracle pricing. Deposits EUI tokens from the owner to the contract (requires approval), burns the EUI tokens, and mints EUD corresponding to the pricing.
    - `setYieldOralce` - sets the Yield Oracle address. Used in case the pricing mechanism needs to be updated. Can only be called by addresses with the `DEFAULT_ADMIN_ROLE`.
    - `setEud` - sets the EUD token address. Used in case a new EUD token is deployed. Can only be called by addresses with the `DEFAULT_ADMIN_ROLE`.
    - `pause` - Calls the internal `PausableUpgradeable._pause()` function to pause all EUI transfers, minting and burning. Can only be called by addresses with the `PAUSE_ROLE`.
    - `unpause` - Calls the internal `PausableUpgradeable._unpause()` function to resume all EUD transfers, minting and burning. Can only be called by addresses with the `PAUSE_ROLE`.
    - `freeze` - Calls the internal `_transfer` function of `ERC20Upgradeable` to transfer any EUI to any account. In practice, this function will only be used as a gas efficient way to freeze a subset of tokens, by moving them from a user wallet to a dedicated smart contract that will hold the tokens until they are released. A `frozenBalances` mapping keeps tabs on how many frozen tokens a specific address has. This negates the need to check a frozen mapping for each transfer. Can only be called by addresses with the `FREEZE_ROLE`.
    - `release` - Opposite of `freeze`. Calls the internal `_transfer` function of `ERC20Upgradeable` to transfer EUD tokens from any account to an address with a `frozenBalance`. In practice, this function will only be used to move tokens that have been previously frozen by being moved to a dedicated smart contract to custody frozen tokens, back to the original owner of the tokens. It will subtract the amount of frozen tokens from the `frozenBalances` mapping. Can only be called by addresses with the `FREEZE_ROLE`.
    - `reclaim` - A more flexible function to reclaim lost tokens, e.g. tokens sent to dead addresses or due to lost private keys. Can send any EUD tokens to any address. Are only used as a last resort. Can only be called by addresses with the `FREEZE_ROLE`.
    - `addToAllowlist` - A function to add an address to the `allowlist`. Can only be called by addresses with the `ALLOW_ROLE`.
    - `addManyToAllowlist` - A function to add an array of addresses to the `allowlist`. Can only be called by addresses with the `ALLOW_ROLE`.
    - `removeFromAllowlist` - A function to remove an address from the `allowlist`. Can only be called by addresses with the `ALLOW_ROLE`.
    - `removeManyFromAllowlist` - A function to remove an array of addresses from the `allowlist`. Can only be called by addresses with the `ALLOW_ROLE`.
    - `_authorizeUpgrade` - An internal function to point the ERC1967 Proxy to a new implementation contract.  Can only be called by addresses with the `DEFAULT_ADMIN_ROLE`.

## YieldOracle

The YieldOracle is not upgradeable. If we desire to change the pricing mechanism, we can deploy a new contract, and update the connection in the EUI contract.

- Inherits OpenZeppelin contracts:
    - `Pauseable` - To pause contract functions
    - `AccessControl` - For role based permissioning
    - `Math` - For mulDiv operations
- Fields
    - `maxPriceIncrease` - guard rail to ensure that a faulty oracle bot does not increase price arbitrarily.
    - `lastUpdate` - timestamp of the last price update used to check against guard rail delay, below.
    - `delay` - guard rail to ensure that if an oracle bot is faulty that price updates can only be pushed at a certain time interval.
    - `_oldPrice` - we maintain two EUIEUD prices, a current price, and the last price before that called the “oldPrice". This is to ensure that users who flip from EUI to EUD do not accrue "today's” yield, but gets “yesterday's” conversion rate. This is due to a redemption delay on the backend fiat systems.
    - `_currentPrice` - the latest EUIEUD price. This is used when users flip from EUD to EUI, to ensure they do not accrue fees based on yields that were accumulated before depositing.
- Constants
    - `Roles` used for `AccessControl` permission scheme
    - `MIN_PRICE = 1e18`, to enable minimum 18 decimals of pricing.
- Functions
    - `constructor` - Gives the deployer `DEFAULT_ADMIN_ROLE`, and sets both `_oldPrice` and `_currentPrice` to `MIN_PRICE`.
        - Sets the `maxPriceIncrease` to `1e17` (0.1 after we divide with 1e18).
        - Sets the `delay` for price updates to `1 hour`
        - Sets last `update` to `block.timestamp` for the deployment
    - `pause` - pauses all price updates from happening. Can only be called by addresses with the `PAUSE_ROLE`.
    - `unpause` - unpauses all price updates. Can only be called by addresses with the `PAUSE_ROLE`.
    - `oldPrice` - returns `_oldPrice`, unless paused where it returns `_oldPricePaused`
    - `currentPrice` - returns `_currentPrice`, unless paused where it returns `_currentPricePaused`
    - `updatePrice` - updates `oldPrice` as the `currentPrice`, and sets a new price as `currentPrice`, granted it does not violate the `delay` since last update, and that the new price is not larger than the difference between the two and the `maxIncrease`. Can only be called by addresses with the `ORACLE_ROLE`.
    - `setMaxPrice` - sets the max price increase in a price update. Can only be called by addresses with the `DEFAULT_ADMIN_ROLE`.
    - `setDelay` - sets the delay between price updates. Can only be called by addresses with the `DEFAULT_ADMIN_ROLE`.
    - `adminUpdateOldPric`e - updates the `oldPrice` while circumventing guardrail restrictions. Only used in case of oracle malfunctions. Must be greater than `MIN_PRIC`E. Can only be called by addresses with the `DEFAULT_ADMIN_ROLE`.
    - `adminUpdateCurrentPrice` - updates the `currentPrice` while circumventing guardrail restrictions. Only used in case of oracle malfunctions. Must be greater than `MIN_PRICE` and higher than oldPrice. Can only be called by addresses with the `DEFAULT_ADMIN_ROLE`.
    - `fromEudToEui` - calculates the conversion for a given amount of EUD to EUI. If not paused, it will return the given EUD amount multiplied by `1e18`, divided by `_currentPric`e. We multiply by `1e18`, because we use 18 decimals for our EUIEUD pricing. So we basically divide EUD amount with current EUIEUD price, and manage the decimals. The `Math.mulDiv` function rounds down as standard unless anything else is specified. We do this to avoid ever giving the user "too many” assets, to ensure each asset is always fully backed.
    - `fromEuiToEud` - calculates the conversion for a given amount of EUI to EUD. If not paused, it will return the given EUI amount multiplied by `_oldPrice`, divided by `1e18`. We divide by 1e18, because we use 18 decimals for our EUIEUD pricing. So we basically multiply the EUI amount with current EUIEUD price, and manage the decimals. The `Math.mulDiv` function rounds down as standard unless anything else is specified. We do this to avoid ever giving the user "too many” assets, to ensure each asset is always fully backed.
