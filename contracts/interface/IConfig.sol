pragma solidity >=0.7.0 <0.8.0;

interface IConfig {

    function getConfigAddress(string) external view returns (address);
    function getConfigUint(string) external view returns (uint256);
}