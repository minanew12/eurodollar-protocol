// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IEUD {
    function burn(address from, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external returns (bool);
}
