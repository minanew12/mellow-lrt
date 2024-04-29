// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/validators/IValidator.sol";

contract AllowAllValidator is IValidator {
    function validate(address, address, bytes calldata) external pure {}
}
