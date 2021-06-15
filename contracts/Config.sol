pragma solidity >=0.7.0 <0.8.0;

contract Config {

    mapping(string => address) public configAddress;
    mapping(string => uint256) public configUint;

    function setConfigAddress(string memory _key, address _value) public {
        configAddress[_key] = _value;
    }

    function getConfigAddress(string memory _key) public returns(address){
        return configAddress[_key];
    }

    function setConfigUint(string memory _key, uint _value) public {
        configUint[_key] = _value;
    }

    function getConfigUint(string memory _key) public returns(uint){
        return configUint[_key];
    }
}
