pragma solidity >=0.7.0 <0.8.0;

interface IFactory {

    function getConfigContract() external view returns (address);
}