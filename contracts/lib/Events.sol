pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;


contract Events {

    /** Events from category contract */
    event JobStatus(address user, address category, uint256 id, uint256 status_code);

    /** Events for Order Contract */
    event OrderStatus(address client, address serviceProvider, address orderContract, uint256 status_code);


    /** Function to emit from category contract */
    function EventForJobStatus(address user, address category, uint256 id, uint256 status_code) public{
        require(msg.sender == category, "Must be emited by the category");
        emit JobStatus(user, category, id, status_code);
    }

    /** Function to emit from Order Contract */
    function EventForOrderStatus(address client, address serviceProvider, address orderContract, uint256 status_code) public{
        require(msg.sender == orderContract, "Must be emited by the order");
        emit OrderStatus(client, serviceProvider, orderContract, status);
    }
}