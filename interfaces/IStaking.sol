// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

interface IStaking {
    function getTotalRewardsPaid() external view returns (uint256);

    function getTotalAmountStaked() external view returns (uint256);
}
