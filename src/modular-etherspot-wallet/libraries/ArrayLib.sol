// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library ArrayLib {
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

    function _removeElement(
        address[] memory _data,
        address _element
    ) internal pure returns (address[] memory) {
        address[] memory newData = new address[](_data.length - 1);
        uint256 j;
        for (uint256 i; i < _data.length; i++) {
            if (_data[i] != _element) {
                newData[j] = _data[i];
                j++;
            }
        }
        return newData;
    }
}
