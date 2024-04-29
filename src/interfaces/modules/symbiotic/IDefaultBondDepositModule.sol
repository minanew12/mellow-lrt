// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../external/symbiotic/IDefaultBond.sol";

interface IDefaultBondDepositModule {
    function deposit(address bond, uint256 amount) external;
}
