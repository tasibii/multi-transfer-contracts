//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Ownable} from "oz-custom/contracts/oz/access/Ownable.sol";
import {ERC20, IMultiTransfer} from "./interfaces/IMultiTransfer.sol";
import {IERC20, IPermit2} from "./utils/permit2/interfaces/IPermit2.sol";
import {IERC20Permit} from "oz-custom/contracts/oz/token/ERC20/extensions/IERC20Permit.sol";

contract MultiTransfer is Ownable, IMultiTransfer {
    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    IPermit2 public permit2;

    receive() external payable {}
    fallback() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setPermit2(IPermit2 permit2_) external onlyOwner {
        emit Permit2Changed(_msgSender(), permit2, permit2_);
        permit2 = permit2_;
    }

    function multiTransferNative(
        address[] calldata addresses_
    ) external payable onlyOwner returns (uint256[] memory success) {
        uint256 length = addresses_.length;
        uint256 balance = address(this).balance;
        uint256 totalAmount = msg.value * length;
        
        if (totalAmount > balance) 
            revert MultiTransfer_InsufficientBalance();

        success = new uint256[](length);
        address account;
        bool ok;
        for (uint256 i; i < length; ) {
            account = addresses_[i];
            (ok, ) = account.call{value: msg.value}("");
            success[i] = ok ? 2 : 1;

            unchecked {
                ++i;
            }
        }
    }

    function multiTransferERC20(
        ERC20 token_,
        address[] calldata addresses_,
        uint256 amount_
    ) external onlyOwner returns (uint256[] memory success) {
        uint256 length = addresses_.length;
        uint256 balance = token_.balanceOf(address(this));
        uint256 totalAmount = balance * length;

        if (totalAmount > balance) 
            revert MultiTransfer_InsufficientBalance();

        success = new uint256[](length);
        bytes memory callData = abi.encodeCall(
            IERC20.transfer,
            (address(0), amount_)
        );

        address _payment = address(token_);
        bool ok;
        address account;
        for (uint256 i; i < length; ) {
            account = addresses_[i];

            assembly {
                mstore(add(callData, 0x24), account)
            }

            (ok, ) = _payment.call(callData);

            success[i] = ok ? 2 : 1;

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

        uint256 length = details_.addresses.length;
        address account;
        Signature memory sign;
        for (uint i; i < length; ) {
            account = details_.addresses[i];
            sign = signatures_[i];
            IERC20Permit(details_.token).permit(account, details_.spender, MAX_INT, details_.deadline, sign.v, sign.r, sign.s);
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
            _permit2.permit ({
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
}
