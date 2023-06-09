//SDPX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IPermit2} from "../utils/permit2/interfaces/IPermit2.sol";
import {ERC20} from "oz-custom/contracts/oz/token/ERC20/ERC20.sol";
interface IMultiTransfer {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct PermitDetail {
        address token;
        address spender; 
        uint48 deadline;
        address[] addresses;
    }

    // error
    error MultiTransfer_LengthMismatch();
    error MultiTransfer_InsufficientBalance();
    error MultiTransfer_Unauthorized(address caller_);

    // event
    // event TokenTransfered(address indexed operator_, uint256[] success);
    event Permit2Changed(address indexed operator_, IPermit2 indexed from_, IPermit2 indexed to_);
    // event Permitted(address indexed operator_, address indexed spender_, uint256 indexed amount_, address[] addresses);

    // function
    function multiTransferNative (address[] calldata addresses_) external payable returns (uint256[] memory success);
    function multiTransferERC20 (ERC20 token_, address[] calldata addresses_, uint256 amount_) external returns (uint256[] memory success);
}