// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/EUD.sol";

contract EUDTest is Test {
    EUD public eud;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    eud = new EUD();
    eud.initialize();

    function setUp() public {
    }

    function testPause() public {
        
        eud.pause();
        assertTrue(eud.paused());
    }

    // function testUnpause() public {
    //     eud.pause();
    //     eud.unpause();
    //     assertFalse(eud.paused());
    // }

    // function testMint(address to, uint256 amount) public {
    //     eud.mint(to, amount);
    //     assertEq(eud.balanceOf(to), amount);
    // }

    // function testBurn(address from, uint256 amount) public {
    //     eud.burn(from, amount);
    //     assertEq(eud.balanceOf(from), 0);
    // }
}
