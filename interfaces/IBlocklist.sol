// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IBlocklist {
    function isBlocked(address account) external view returns (bool);
}
