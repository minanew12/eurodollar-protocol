// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: © 2023 Rhinefield Technologies Limited

pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {Strings} from "oz/utils/Strings.sol";
import {YieldOracle, MIN_PRICE} from "../src/YieldOracle.sol";

abstract contract YieldOracleInvariants is Test {
    YieldOracle public yieldOracle;

    function invariantMonotonePrices() external {
        assertGe(yieldOracle.currentPrice(), yieldOracle.oldPrice(), "Current price must never decrease over time");
    }

    function invariantMinPrice() external {
        assertGe(yieldOracle.currentPrice(), MIN_PRICE, "Prices must always be at least MIN_PRICE");
        assertGe(yieldOracle.oldPrice(), MIN_PRICE, "Prices must always be at least MIN_PRICE");
    }

    function invariantNoFreeLunch() external {
        if (yieldOracle.paused()) return;

        uint256 someEud = 1.41247819372198e25;
        uint256 someEui = yieldOracle.fromEudToEui(someEud);

        assertLe(yieldOracle.fromEuiToEud(someEui), someEud, "Converting back and forth should never incease balance");
    }

    function invariantPriceIncrease() external {
        assertGt(yieldOracle.maxPriceIncrease(), 0, "Price increase should be greater than 0");
    }

    function invariantDelay() external {
        assertGt(yieldOracle.delay(), 0, "Delay should be greater than 0");
    }
}

contract YieldOracleTest is Test, YieldOracleInvariants {
    function setUp() public {
        yieldOracle = new YieldOracle();
    }

    function testConstructor() public {
        YieldOracle newOracle = new YieldOracle();
        assertTrue(newOracle.hasRole(newOracle.DEFAULT_ADMIN_ROLE(), address(this)));
        assertEq(newOracle.oldPrice(), MIN_PRICE);
        assertEq(newOracle.currentPrice(), MIN_PRICE);
        assertEq(newOracle.maxPriceIncrease(), 1e17);
        assertEq(newOracle.delay(), 1 hours);
    }

    function testPause(address pauser) public {
        yieldOracle.grantRole(yieldOracle.PAUSE_ROLE(), pauser);
        vm.prank(pauser);
        yieldOracle.pause();
        assertEq(yieldOracle.paused(), true);
    }

    function testUnpause(address pauser) public {
        yieldOracle.grantRole(yieldOracle.PAUSE_ROLE(), pauser);

        vm.startPrank(pauser);
        yieldOracle.pause();
        assertEq(yieldOracle.paused(), true);

        yieldOracle.unpause();
        assertEq(yieldOracle.paused(), false);
        vm.stopPrank();
    }

    function testAdminSetPricesWhenPaused(address pauser) public {
        yieldOracle.grantRole(yieldOracle.PAUSE_ROLE(), pauser);

        vm.prank(pauser);
        yieldOracle.pause();
        assertEq(yieldOracle.paused(), true);

        yieldOracle.adminUpdateCurrentPrice(2e18);
        assertEq(yieldOracle.currentPrice(), 2e18);

        yieldOracle.adminUpdateOldPrice(2e18);
        assertEq(yieldOracle.oldPrice(), 2e18);

        vm.prank(pauser);
        yieldOracle.unpause();
        assertEq(yieldOracle.paused(), false);

        assertEq(yieldOracle.currentPrice(), 2e18);
        assertEq(yieldOracle.oldPrice(), 2e18);
    }

    function testGrantPauseRole(address account) public {
        yieldOracle.grantRole(yieldOracle.PAUSE_ROLE(), account);
        assertTrue(yieldOracle.hasRole(yieldOracle.PAUSE_ROLE(), account));
    }

    function testGrantOracleRole(address account) public {
        yieldOracle.grantRole(yieldOracle.ORACLE_ROLE(), account);
        assertTrue(yieldOracle.hasRole(yieldOracle.ORACLE_ROLE(), account));
    }

    function testUnauthorizedGrantPauseRole(address account) public {
        bytes32 role = yieldOracle.PAUSE_ROLE();

        // Ensure the account is not able to grant the PAUSE role
        bytes32 roleAdmin = yieldOracle.getRoleAdmin(role);
        vm.assume(!yieldOracle.hasRole(roleAdmin, account));

        vm.expectRevert(accessControlError(account, yieldOracle.DEFAULT_ADMIN_ROLE()));
        vm.prank(account);
        yieldOracle.grantRole(role, account);
    }

    function testUnauthorizedGrantOracleRole(address account) public {
        bytes32 role = yieldOracle.ORACLE_ROLE();

        // Ensure the account is not able to grant the PAUSE role
        bytes32 roleAdmin = yieldOracle.getRoleAdmin(role);
        vm.assume(!yieldOracle.hasRole(roleAdmin, account));

        vm.expectRevert(accessControlError(account, yieldOracle.DEFAULT_ADMIN_ROLE()));
        vm.prank(account);
        yieldOracle.grantRole(role, account);
    }

    function testSetMaxPriceIncrease(uint256 amount) public {
        assertTrue(yieldOracle.hasRole(yieldOracle.DEFAULT_ADMIN_ROLE(), address(this)));

        yieldOracle.setMaxPriceIncrease(amount);
        assertEq(yieldOracle.maxPriceIncrease(), amount);
    }

    function testSetDelay(uint256 amount) public {
        assertTrue(yieldOracle.hasRole(yieldOracle.DEFAULT_ADMIN_ROLE(), address(this)));

        yieldOracle.setDelay(amount);
        assertEq(yieldOracle.delay(), amount);
    }

    function testUpdatePrice(address oracle, uint256 advance, uint256 increase) public {
        advance = bound(advance, yieldOracle.delay(), 30 days);

        uint256 price0 = yieldOracle.currentPrice();
        uint256 price1 = bound(increase, price0, price0 + yieldOracle.maxPriceIncrease());
        uint256 price2 = bound(increase, price1, price1 + yieldOracle.maxPriceIncrease());

        yieldOracle.grantRole(yieldOracle.ORACLE_ROLE(), oracle);

        super.skip(advance);
        vm.prank(oracle);
        yieldOracle.updatePrice(price1);
        assertEqDecimal(yieldOracle.oldPrice(), price0, 18);
        assertEqDecimal(yieldOracle.currentPrice(), price1, 18);

        super.skip(advance);
        vm.prank(oracle);
        yieldOracle.updatePrice(price2);
        assertEqDecimal(yieldOracle.oldPrice(), price1, 18);
        assertEqDecimal(yieldOracle.currentPrice(), price2, 18);
    }

    function testUnauthorizedUpdatePrice(address notOracle) public {
        vm.assume(notOracle != address(this));
        assert(!yieldOracle.hasRole(yieldOracle.ORACLE_ROLE(), notOracle));

        vm.expectRevert(accessControlError(notOracle, yieldOracle.ORACLE_ROLE()));
        vm.prank(notOracle);
        yieldOracle.updatePrice(MIN_PRICE);
    }

    function testNotEnoughTimeBetweenPriceUpdates(address oracle, uint256 delay) public {
        delay = bound(delay, 0, yieldOracle.delay() - 1);
        yieldOracle.grantRole(yieldOracle.ORACLE_ROLE(), oracle);
        skip(delay);

        vm.expectRevert("YieldOracle: price can only be updated after the delay period");
        vm.prank(oracle);
        yieldOracle.updatePrice(MIN_PRICE);
    }

    function testPriceUpdateAboveLimit(address oracle, uint256 increase) public {
        increase = bound(increase, yieldOracle.maxPriceIncrease() + 1, type(uint256).max - yieldOracle.currentPrice());
        uint256 price = yieldOracle.currentPrice() + increase;
        yieldOracle.grantRole(yieldOracle.ORACLE_ROLE(), oracle);
        skip(yieldOracle.delay());

        vm.expectRevert("YieldOracle: price increase exceeds maximum allowed");
        vm.prank(oracle);
        yieldOracle.updatePrice(price);
    }

    function testPriceUpdateBelowLimit(address oracle, uint256 price) public {
        price = bound(price, 0, MIN_PRICE - 1);
        yieldOracle.grantRole(yieldOracle.ORACLE_ROLE(), oracle);
        skip(yieldOracle.delay());

        vm.expectRevert("YieldOracle: price must be greater than or equal to the current price");
        vm.prank(oracle);
        yieldOracle.updatePrice(price);
    }

    function testAdminSetCurrentPriceBelowLimit(uint256 price) public {
        price = bound(price, 0, MIN_PRICE - 1);

        vm.expectRevert("YieldOracle: price must be greater than or equal to MIN_PRICE");
        yieldOracle.adminUpdateCurrentPrice(price);
    }

    function testAdminSetOldPriceBelowLimit(uint256 price) public {
        price = bound(price, 0, MIN_PRICE - 1);

        vm.expectRevert("YieldOracle: price must be greater than or equal to MIN_PRICE");
        yieldOracle.adminUpdateOldPrice(price);
    }

    function testFromEudtoEui() public {
        yieldOracle.adminUpdateCurrentPrice(1.25e18);
        uint256 amount = 1e18;
        assertEqDecimal(yieldOracle.fromEudToEui(amount), 0.8e18, 18); // 1.00 / 1.25 = 0.8
    }

    function testFromEuiToEud() public {
        yieldOracle.adminUpdateOldPrice(1.25e18);
        uint256 amount = 1e18;
        assertEqDecimal(yieldOracle.fromEuiToEud(amount), 1.25e18, 18); // 1.00 * 1.25 = 1.25
    }

    /// forge-config: default.fuzz.runs = 2048
    function test_NumericalStability(uint256 price, uint256 balance) public {
        // Calculate an upperbound for EUI assuming a hourly 10 cent increase hourly
        // for 100 years
        uint256 maxPriceIncrease = 0.1e18;
        uint256 lowerBoundPrice = MIN_PRICE;
        uint256 hourlyFor100Years = (365 days * 100) / 1 hours;
        uint256 upperBoundPrice = lowerBoundPrice + maxPriceIncrease * hourlyFor100Years;

        price = bound(price, lowerBoundPrice, upperBoundPrice);

        // Use a balance between 0.1 cent and 1000 trillion EUD
        balance = bound(balance, 0.001e18, 1e33);

        yieldOracle.adminUpdateCurrentPrice(price);
        yieldOracle.adminUpdateOldPrice(price);

        assertEq(
            yieldOracle.currentPrice(), yieldOracle.oldPrice(), "Prices must be equal to isolate loss to truncation"
        );

        uint256 eudAmount = yieldOracle.fromEuiToEud(balance);
        uint256 euiAmount = yieldOracle.fromEudToEui(eudAmount);

        assertApproxEqRelDecimal(euiAmount, balance, 0.0000000001e18, 18);
    }
}

function accessControlError(address account, bytes32 role) pure returns (bytes memory) {
    return abi.encodePacked(
        "AccessControl: account ",
        Strings.toHexString(account),
        " is missing role ",
        Strings.toHexString(uint256(role), 32)
    );
}

contract AccessControl is Test, YieldOracleInvariants {
    address admin;
    address pauser;
    address oracle;
    address nobody;

    function setUp() public {
        yieldOracle = new YieldOracle();

        admin = address(this);
        pauser = makeAddr("pauser");
        yieldOracle.grantRole(yieldOracle.PAUSE_ROLE(), pauser);
        oracle = makeAddr("oracle");
        yieldOracle.grantRole(yieldOracle.ORACLE_ROLE(), oracle);
        nobody = makeAddr("nobody");
    }

    function test_RevertWhen_RoleIsNobody() public {
        vm.startPrank(nobody);

        vm.expectRevert(accessControlError(nobody, yieldOracle.PAUSE_ROLE()));
        yieldOracle.pause();

        vm.expectRevert(accessControlError(nobody, yieldOracle.PAUSE_ROLE()));
        yieldOracle.unpause();

        vm.expectRevert(accessControlError(nobody, yieldOracle.ORACLE_ROLE()));
        yieldOracle.updatePrice(MIN_PRICE);

        vm.expectRevert(accessControlError(nobody, yieldOracle.DEFAULT_ADMIN_ROLE()));
        yieldOracle.setMaxPriceIncrease(1e17);

        vm.expectRevert(accessControlError(nobody, yieldOracle.DEFAULT_ADMIN_ROLE()));
        yieldOracle.setDelay(1 hours);

        vm.expectRevert(accessControlError(nobody, yieldOracle.DEFAULT_ADMIN_ROLE()));
        yieldOracle.adminUpdateCurrentPrice(MIN_PRICE);

        vm.expectRevert(accessControlError(nobody, yieldOracle.DEFAULT_ADMIN_ROLE()));
        yieldOracle.adminUpdateOldPrice(MIN_PRICE);

        // Allowed methods
        yieldOracle.fromEuiToEud(MIN_PRICE);
        yieldOracle.fromEudToEui(MIN_PRICE);

        vm.stopPrank();
    }

    function test_RevertWhen_RoleIsAdmin() public {
        assertTrue(yieldOracle.hasRole(yieldOracle.DEFAULT_ADMIN_ROLE(), admin));
        vm.startPrank(admin);

        vm.expectRevert(accessControlError(admin, yieldOracle.PAUSE_ROLE()));
        yieldOracle.pause();

        vm.expectRevert(accessControlError(admin, yieldOracle.PAUSE_ROLE()));
        yieldOracle.unpause();

        vm.expectRevert(accessControlError(admin, yieldOracle.ORACLE_ROLE()));
        yieldOracle.updatePrice(MIN_PRICE);

        // Allowed methods
        yieldOracle.setMaxPriceIncrease(1e17);
        yieldOracle.setDelay(1 hours);
        yieldOracle.adminUpdateCurrentPrice(MIN_PRICE);
        yieldOracle.adminUpdateOldPrice(MIN_PRICE);
        yieldOracle.fromEuiToEud(MIN_PRICE);
        yieldOracle.fromEudToEui(MIN_PRICE);

        vm.stopPrank();
    }

    function test_RevertWhen_RoleIsPause() public {
        assertTrue(yieldOracle.hasRole(yieldOracle.PAUSE_ROLE(), pauser));
        vm.startPrank(pauser);

        vm.expectRevert(accessControlError(pauser, yieldOracle.ORACLE_ROLE()));
        yieldOracle.updatePrice(MIN_PRICE);

        vm.expectRevert(accessControlError(pauser, yieldOracle.DEFAULT_ADMIN_ROLE()));
        yieldOracle.setMaxPriceIncrease(1e17);

        vm.expectRevert(accessControlError(pauser, yieldOracle.DEFAULT_ADMIN_ROLE()));
        yieldOracle.setDelay(1 hours);

        vm.expectRevert(accessControlError(pauser, yieldOracle.DEFAULT_ADMIN_ROLE()));
        yieldOracle.adminUpdateCurrentPrice(MIN_PRICE);

        vm.expectRevert(accessControlError(pauser, yieldOracle.DEFAULT_ADMIN_ROLE()));
        yieldOracle.adminUpdateOldPrice(MIN_PRICE);

        // Allowed methods
        yieldOracle.pause();
        yieldOracle.unpause();
        yieldOracle.fromEuiToEud(MIN_PRICE);
        yieldOracle.fromEudToEui(MIN_PRICE);

        vm.stopPrank();
    }

    function test_RevertWhen_RoleIsOracle() public {
        assertTrue(yieldOracle.hasRole(yieldOracle.ORACLE_ROLE(), oracle));
        vm.startPrank(oracle);

        vm.expectRevert(accessControlError(oracle, yieldOracle.PAUSE_ROLE()));
        yieldOracle.pause();

        vm.expectRevert(accessControlError(oracle, yieldOracle.PAUSE_ROLE()));
        yieldOracle.unpause();

        vm.expectRevert(accessControlError(oracle, yieldOracle.DEFAULT_ADMIN_ROLE()));
        yieldOracle.setMaxPriceIncrease(1e17);

        vm.expectRevert(accessControlError(oracle, yieldOracle.DEFAULT_ADMIN_ROLE()));
        yieldOracle.setDelay(1 hours);

        vm.expectRevert(accessControlError(oracle, yieldOracle.DEFAULT_ADMIN_ROLE()));
        yieldOracle.adminUpdateCurrentPrice(MIN_PRICE);

        vm.expectRevert(accessControlError(oracle, yieldOracle.DEFAULT_ADMIN_ROLE()));
        yieldOracle.adminUpdateOldPrice(MIN_PRICE);

        // Allowed methods
        skip(yieldOracle.delay()); // make updatePrice a legal operation
        yieldOracle.updatePrice(MIN_PRICE);
        yieldOracle.fromEuiToEud(MIN_PRICE);
        yieldOracle.fromEudToEui(MIN_PRICE);

        vm.stopPrank();
    }
}

contract Paused is Test, YieldOracleInvariants {
    function setUp() public {
        yieldOracle = new YieldOracle();
        yieldOracle.grantRole(yieldOracle.PAUSE_ROLE(), address(this));
        yieldOracle.grantRole(yieldOracle.ORACLE_ROLE(), address(this));
        yieldOracle.pause();
    }

    function test_setUpState() public {
        assertTrue(yieldOracle.paused(), "Must be paused");
        assertTrue(yieldOracle.hasRole(yieldOracle.DEFAULT_ADMIN_ROLE(), address(this)), "Must have admin role");
        assertTrue(yieldOracle.hasRole(yieldOracle.PAUSE_ROLE(), address(this)), "Must have pause role");
        assertTrue(yieldOracle.hasRole(yieldOracle.ORACLE_ROLE(), address(this)), "Must have oracle role");
    }

    function test_CannotUpdatePrice(uint256 amount) public {
        assertTrue(yieldOracle.paused(), "Must be paused");
        vm.expectRevert("Pausable: paused");
        yieldOracle.updatePrice(amount);
    }

    function test_CannotFromEuiToEud(uint256 amount) public {
        assertTrue(yieldOracle.paused(), "Must be paused");
        vm.expectRevert("Pausable: paused");
        yieldOracle.fromEuiToEud(amount);
    }

    function test_CannotFromEudToEui(uint256 amount) public {
        assertTrue(yieldOracle.paused(), "Must be paused");
        vm.expectRevert("Pausable: paused");
        yieldOracle.fromEudToEui(amount);
    }

    function test_CannotSetMaxPriceIncrease() public {
        assertTrue(yieldOracle.paused(), "Must be paused");
        yieldOracle.setMaxPriceIncrease(1e17);
    }

    function test_SetDelay() public {
        assertTrue(yieldOracle.paused(), "Must be paused");
        yieldOracle.setDelay(1 hours);
    }

    function test_AdminUpdateCurrentPrice() public {
        assertTrue(yieldOracle.paused(), "Must be paused");
        yieldOracle.adminUpdateCurrentPrice(MIN_PRICE);
    }

    function test_AdminUpdateOldPrice() public {
        assertTrue(yieldOracle.paused(), "Must be paused");
        yieldOracle.adminUpdateOldPrice(MIN_PRICE);
    }
}
