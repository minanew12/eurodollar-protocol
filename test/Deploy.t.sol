// pragma solidity ^0.8.13;

// import {Test} from "forge-std/Test.sol";
// import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
// import {EUD} from "../src/EUD.sol";
// import {EUI} from "../src/EUI.sol";
// import {Constants} from "./Constants.sol";
// import {Deploy} from "../script/Deploy.s.sol";
// import {YieldOracle} from "../src/YieldOracle.sol";

// contract DeployTest is Test, Constants
// {
//     YieldOracle yieldOracle = YieldOracle(0x5FbDB2315678afecb367f032d93F642f64180aa3);
//     EUD eud = EUD(0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9);
//     //address eudProxy = 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9;
//     EUI eui = EUI(0x0165878A594ca255338adfa4d48449f69242Eb8F);
//     //address euiProxy = 0x0165878A594ca255338adfa4d48449f69242Eb8F;

//     address admin = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

//     function testGetCurrentPrice() public {
//         assertEq(yieldOracle.currentPrice(), 1e18);
//         vm.warp(3601);
//         vm.prank(admin);
//         yieldOracle.adminUpdateCurrentPrice(2e18);
//         assertEq(yieldOracle.currentPrice(), 2e18);
//     }

//     function testDeployment(address account) public {
//         vm.assume(account != address(0));
//         vm.startPrank(admin);
//         eui.grantRole(DEFAULT_ADMIN_ROLE, admin);
//         eud.grantRole(DEFAULT_ADMIN_ROLE, admin);
//         eud.grantRole(MINT_ROLE, admin);
//         eud.grantRole(BURN_ROLE, admin);
//         eud.grantRole(PAUSE_ROLE, admin);
//         eud.grantRole(MINT_ROLE, address(eui));
//         eud.grantRole(BURN_ROLE, address(eui));
//         eui.grantRole(MINT_ROLE, address(eud));
//         eui.grantRole(BURN_ROLE, address(eud));
//         eui.grantRole(MINT_ROLE, admin);
//         eui.grantRole(ALLOW_ROLE, admin);
//         eui.addToAllowlist(address(eui));
//         assertEq(eud.hasRole(MINT_ROLE, admin), true);

//         eud.mint(account, 1000e18);
//         assertEq(eud.balanceOf(account), 1000e18);

//         eud.burn(account, 1000e18);
//         assertEq(eud.balanceOf(account), 0);

//         eud.pause();
//         assertEq(eud.paused(), true);
//         eud.unpause();
//         assertEq(eud.paused(), false);

//         eui.addToAllowlist(account);
//         eui.mintEUI(account, 1000e18);
//         assertEq(eui.balanceOf(account), 1000e18);
//         vm.stopPrank();
//         vm.startPrank(account);
//         eui.approve(address(eui), 1000e18);
//         eui.flipToEUD(account, account, 1000e18);
//         assertEq(eui.balanceOf(account), 0);
//         assertEq(eud.balanceOf(account), 1000e18);
//         // address(eudProxy).call(abi.encodeWithSignature("grantRole(bytes32,address)", DEFAULT_ADMIN_ROLE, account));
//         // assertEq(address(eudProxy).call(abi.encodeWithSignature("hasRole(DEFAULT_ADMIN_ROLE, account)")), true);
//         // assertEq(eudProxy.admin(), address(this));
//         // assertEq(eudProxy.implementation(), address(eud));
//         // assertEq(eudProxy.hasRole(DEFAULT_ADMIN_ROLE, address(this)), true);
//         // assertEq(eudProxy.hasRole(MINT_ROLE, address(this)), true);
//         // assertEq(eudProxy.hasRole(BURN_ROLE, address(this)), true);
//         // assertEq(eudProxy.hasRole(PAUSE_ROLE, address(this)), true);
//         // assertEq(eudProxy.hasRole(FREEZE_ROLE, address(this)), true);
//         // assertEq(eudProxy.hasRole(BLOCK_ROLE, address(this)), true);
//         // assertEq(eudProxy.hasRole(ALLOW_ROLE, address(this)), true);
//         // assertEq(eudProxy.hasRole(ORACLE_ROLE, address(this)), true);
//     }
// }
