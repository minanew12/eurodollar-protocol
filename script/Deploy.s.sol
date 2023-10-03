// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: © 2023 Rhinefield Technologies Limited

pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {EUD} from "../src/EUD.sol";
import {EUI} from "../src/EUI.sol";
import {YieldOracle} from "../src/YieldOracle.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy is Script {
    function run() external returns (address, address, address) {
        vm.startBroadcast();
        YieldOracle oracle = new YieldOracle();
        require(oracle.adminUpdateCurrentPrice(1e18));
        require(oracle.adminUpdateOldPrice(1e18));
        console.log("Oracle address:");
        console.log(address(oracle));

        EUD eud = new EUD();
        console.log("EUD address:");
        console.log(address(eud));
        ERC1967Proxy eudProxy = new ERC1967Proxy(address(eud), abi.encodeCall(EUD.initialize, ()));
        //address(eudProxy).call(abi.encodeWithSignature("grantRole(bytes32,address)", DEFAULT_ADMIN_ROLE, admin));
        console.log("EUDProxy address:");
        console.log(address(eudProxy));

        EUI eui = new EUI();
        console.log("EUI address:");
        ERC1967Proxy euiproxy =
            new ERC1967Proxy(address(eui), abi.encodeCall(EUI.initialize, (address(eudProxy), address(oracle))));
        console.log("EUIProxy address:");
        console.log(address(euiproxy));
        vm.stopBroadcast();

        return (address(eud), address(eui), address(oracle));
    }
}
