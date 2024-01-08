// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: © 2023 Rhinefield Technologies Limited

pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {EUD} from "../src/EUD.sol";
import {EUI} from "../src/EUI.sol";
import {YieldOracle} from "../src/YieldOracle.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy is Script {
    function run() external returns (address, address, address) {
        vm.startBroadcast();
        YieldOracle oracle = new YieldOracle();
        console.log("Oracle address:");
        console.log(address(oracle));

        EUD eudImplementation = new EUD();
        console.log("EUD implementation address:");
        console.log(address(eudImplementation));
        ERC1967Proxy eudProxy = new ERC1967Proxy(address(eudImplementation), abi.encodeCall(EUD.initialize, ()));
        console.log("EUDProxy address:");
        console.log(address(eudProxy));

        EUI euiImplementation = new EUI(address(eudProxy));
        console.log("EUI implementation address:");
        ERC1967Proxy euiProxy =
            new ERC1967Proxy(address(euiImplementation), abi.encodeCall(EUI.initialize, (address(oracle))));
        console.log("EUIProxy address:");
        console.log(address(euiProxy));
        vm.stopBroadcast();

        return (address(eudProxy), address(euiProxy), address(oracle));
    }
}
