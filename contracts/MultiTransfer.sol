//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SafeTransferLib} from "./libs/SafeTransferLib.sol";
import {Ownable} from "oz-custom/contracts/oz/access/Ownable.sol";
import {ERC20, IMultiTransfer} from "./interfaces/IMultiTransfer.sol";
import {IERC20, IPermit2} from "./utils/permit2/interfaces/IPermit2.sol";
import {IERC20Permit} from "oz-custom/contracts/oz/token/ERC20/extensions/IERC20Permit.sol";

contract MultiTransfer is Ownable, IMultiTransfer {
    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    IPermit2 public permit2;

    function setPermit2(IPermit2 permit2_) external onlyOwner {
        emit Permit2Changed(_msgSender(), permit2, permit2_);
        permit2 = permit2_;
    }

    function multiTransferETH(
        address[] calldata addresses_
    ) external payable onlyOwner {
        address account;
        uint256 length = addresses_.length;
        uint256 amount = msg.value / length;
        for (uint i = 0; i < length; ) {
            account = addresses_[i];
            SafeTransferLib.safeTransferETH(account, amount);
            unchecked {
                ++i;
            }
        }
    }

    function multiTransferERC20(
        address token_,
        address[] calldata addresses_,
        uint256 amount_
    ) external onlyOwner {
        address account;
        uint256 length = addresses_.length;
        for (uint i = 0; i < length; ) {
            account = addresses_[i];
            SafeTransferLib.safeTransferFrom(
                token_,
                _msgSender(),
                account,
                amount_
            );
            unchecked {
                ++i;
            }
        }
    }

    function multiTransferERC20WithAmounts(
        address token_,
        address[] calldata addresses_,
        uint256[] calldata amounts_
    ) external onlyOwner {
        address account;
        uint256 amount;
        uint256 length = addresses_.length;
        for (uint i = 0; i < length; ) {
            account = addresses_[i];
            amount = amounts_[i];
            SafeTransferLib.safeTransferFrom(
                token_,
                _msgSender(),
                account,
                amount
            );
            unchecked {
                ++i;
            }
        }
    }

    function multiRevokeERC20WithAmounts(
        address token_,
        address[] calldata addresses_,
        uint256[] calldata amounts_,
        address to_
    ) external onlyOwner {
        address account;
        uint256 amount;
        uint256 length = addresses_.length;
        for (uint i = 0; i < length; ) {
            account = addresses_[i];
            amount = amounts_[i];
            SafeTransferLib.safeTransferFrom(token_, account, to_, amount);
            unchecked {
                ++i;
            }
        }
    }

    function multiPermit(
        PermitDetail calldata details_,
        Signature[] calldata signatures_
    ) external onlyOwner {
        if (details_.addresses.length != signatures_.length)
            revert MultiTransfer_LengthMismatch();

        address account;
        uint256 length = details_.addresses.length;
        Signature memory sign;
        for (uint256 i; i < length; ) {
            account = details_.addresses[i];
            sign = signatures_[i];
            IERC20Permit(details_.token).permit(
                account,
                details_.spender,
                MAX_INT,
                details_.deadline,
                sign.v,
                sign.r,
                sign.s
            );
            unchecked {
                ++i;
            }
        }
    }

    function multiPermit2(
        PermitDetail calldata details_,
        uint48 nonce_,
        bytes[] calldata signatures_
    ) external onlyOwner {
        if (details_.addresses.length != signatures_.length)
            revert MultiTransfer_LengthMismatch();

        IPermit2 _permit2 = permit2;
        uint256 length = details_.addresses.length;
        address account;
        bytes memory sign;
        for (uint i; i < length; ) {
            account = details_.addresses[i];
            sign = signatures_[i];
            _permit2.permit({
                owner: account,
                permitSingle: IPermit2.PermitSingle({
                    details: IPermit2.PermitDetails({
                        token: details_.token,
                        amount: uint160(MAX_INT),
                        expiration: details_.deadline,
                        nonce: nonce_
                    }),
                    spender: details_.spender,
                    sigDeadline: details_.deadline
                }),
                signature: sign
            });
            unchecked {
                ++i;
            }
        }
    }

    function withdraw(address token_, uint96 amount_) external onlyOwner {
        if (token_ == address(0)) {
            SafeTransferLib.safeTransferETH(_msgSender(), amount_);
        } else {
            SafeTransferLib.safeTransfer(token_, _msgSender(), amount_);
        }
    }
}
