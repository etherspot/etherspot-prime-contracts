// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract TestCounter {
    uint256 public count;

    event ReceivedPayableCall(uint256 amount, uint256 payment);
    event ReceivedMultiTypeCall(address addr, uint256 num, bool boolVal);

    error InvalidCall(address addr, uint256 num);

    function changeCount(uint256 _value) public {
        count = _value;
    }

    function payableCall(uint256 _value) public payable {
        count = _value;
        emit ReceivedPayableCall(_value, msg.value);
    }

    function multiTypeCall(address _addr, uint256 _num, bool _bool) public {
        emit ReceivedMultiTypeCall(_addr, _num, _bool);
    }

    function invalid(address _addr, uint256 _num) public pure {
        revert InvalidCall(_addr, _num);
    }

    function getCount() public view returns (uint256) {
        return count;
    }
}
