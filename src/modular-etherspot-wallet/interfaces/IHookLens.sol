pragma solidity ^0.8.23;

interface IHookLens {
    function getActiveHook() external view returns (address hook);
}