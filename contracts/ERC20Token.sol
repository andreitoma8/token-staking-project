// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IStaking {
    function getTotalRewardsPaid() external view returns (uint256);

    function getTotalAmountStaked() external view returns (uint256);
}

contract Token is ERC20, ERC20Burnable, Pausable, Ownable {
    // The state of fees on transaction. If true, fees are paid on transfers
    bool public taxState;

    // The fee paid on transfers
    uint256 public fee = 1000; // 10000 = 100%

    // Staking Smart Contract Address
    address public stakingSC;

    // Stake Types
    enum StakeType {
        THREE_MONTHS,
        SIX_MONTHS,
        TWELVE_MONTHS,
        TWENTY_FOUR_MONTHS
    }

    // Mapping of addresses that are excluded from paying fees
    mapping(address => bool) public excludedFromFee;

    constructor() ERC20("Name", "TICKER") {
        _mint(msg.sender, 10000000000 * 10**decimals());
        excludedFromFee[msg.sender] = true;
    }

    // Allows the owner to pause token transfers
    function pause() external onlyOwner {
        _pause();
    }

    // Allows the owner to unpause token transfers
    function unpause() external onlyOwner {
        _unpause();
    }

    // Allows the owner to mint tokens
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Allows staking Smart Contract to mint rewards
    function mintForRewards(address to, uint256 amount) external {
        require(
            msg.sender == stakingSC,
            "Only the Staking SC can mint tokens!"
        );
        _mint(to, amount);
    }

    // Set the address of the Staking Smart Contract and whitelist it
    function setStakingSC(address _address) external onlyOwner {
        stakingSC = _address;
        excludedFromFee[_address] = true;
    }

    // Set tax state
    function setTaxState(bool _taxState) external onlyOwner {
        taxState = _taxState;
    }

    // Set fee on token transfer (with 2 decimals)
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    // Exclude address form paying fee
    function excludeFromFee(address _address) external onlyOwner {
        excludedFromFee[_address] = true;
    }

    // Inlcude address to pay fee
    function includeToFee(address _address) external onlyOwner {
        excludedFromFee[_address] = false;
    }

    // Get statistics for admin in front end
    function getStatistics()
        external
        view
        returns (
            uint256 totalSupply_,
            uint256 circulatingSupply_,
            uint256 totalAmountStaked_,
            uint256 totalRewardsPaid_
        )
    {
        totalSupply_ = totalSupply();
        totalAmountStaked_ = IStaking(stakingSC).getTotalAmountStaked();
        totalRewardsPaid_ = IStaking(stakingSC).getTotalRewardsPaid();
        circulatingSupply_ = totalSupply_ - totalAmountStaked_;
    }

    // Override to implement pause functionality on token transfers
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    // Override to implement tax on token transfer
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (!taxState) {
            super._transfer(from, to, amount);
        } else {
            if (excludedFromFee[from] || excludedFromFee[to]) {
                super._transfer(from, to, amount);
            } else {
                uint256 _fee = (amount * fee) / 10000;
                uint256 _amountAfterFee = amount - _fee;
                super._transfer(from, to, _amountAfterFee);
                super._transfer(from, owner(), _fee);
            }
        }
    }
}
