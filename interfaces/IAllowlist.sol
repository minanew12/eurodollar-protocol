// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IAllowlist {
    function isAllowed(address account) external view returns (bool);
}
