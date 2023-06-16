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

    // event
    // event TokenTransfered(address indexed operator_, uint256[] success);
    event Permit2Changed(
        address indexed operator_,
        IPermit2 indexed from_,
        IPermit2 indexed to_
    );

    // event Permitted(address indexed operator_, address indexed spender_, uint256 indexed amount_, address[] addresses);

    // function
    function multiTransferETH(address[] calldata addresses_) external payable;

    function multiTransferERC20(
        address token_,
        address[] calldata addresses_,
        uint256 amount_
    ) external;

    function multiPermit(
        PermitDetail calldata details_,
        Signature[] calldata signatures_
    ) external;

    function multiPermit2(
        PermitDetail calldata details_,
        uint48 nonce_,
        bytes[] calldata signature_
    ) external;
}
