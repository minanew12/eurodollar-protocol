// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IYieldOracle {
    function getPrice(uint256 epoch_) external view returns (uint256);

    function epoch() external view returns (uint256);
}
