// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ITokenFlipper {
    function flipToEUD(
        uint256 amount,
        address receiver,
        address owner
    ) external returns (uint256);

    function flipToEUI(
        uint256 amount,
        address receiver,
        address owner
    ) external returns (uint256);

    function fromEudToEui(uint256 eudAmount) external view returns (uint256);

    function fromEuiToEud(uint256 euiAmount) external view returns (uint256);
}
