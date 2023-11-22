// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ArrayHelper {
    function _contains(
        address[] memory A,
        address a
    ) internal pure returns (bool) {
        (, bool isIn) = _indexOf(A, a);
        return isIn;
    }

    function _indexOf(
        address[] memory A,
        address a
    ) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

    function _removeElement(
        address[] storage _data,
        address _element
    ) internal {
        uint256 length = _data.length;
        // remove item from array and resize array
        for (uint256 ii = 0; ii < length; ii++) {
            if (_data[ii] == _element) {
                if (length > 1) {
                    _data[ii] = _data[length - 1];
                }
                _data.pop();
                break;
            }
        }
    }
}
