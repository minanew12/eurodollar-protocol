// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: © 2023 Rhinefield Technologies Limited

pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IValidator} from "../src/interfaces/IValidator.sol";
import {EUD} from "../src/EUD.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        EUD eud = new EUD(
            IValidator(0x59C70CDbb3171c0166f489080435E788e2a6f2c0) // Validator
        );

        console.logAddress(address(eud));

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(eud), abi.encodeCall(EUD.initialize, (address(0x0BB0a01BD816ffefe7b7165897CfDa3C54d09876)))
        );

        console.logAddress(address(proxy));

        vm.stopBroadcast();
    }
}
