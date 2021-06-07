pragma solidity >=0.7.0 <0.8.0;
import "./Order.sol";


interface PTMMarshal {
    function addNewDispute() external returns ();
}

interface PTMConfig {
    function config(string memory _key) external view returns (address);
}

contract Dispute{


    struct DisputedOrder {
        address adr;
        uint vote_counter;
        uint256 next;
        uint256 prev;
    }

    mapping (uint => DisputedOrder) public disputedOrders;
    uint start;
    uint end;


    constructor(){
        start = 1;
        end = 0;
    }


    addNewDispute(){

        end++;

        disputedOrders[end] = DisputedOrder(msg.sender, 0, 0, end -1);

        if(end - 1 != 0){
            disputedOrders[end - 1].next = end;
        }
    }


    voteForDispute(uint id, address vote_for){

        PTMConfig config =
            PTMConfig(0x01fCAE732E224B4199de657aF7FC0fD3fe9835e5);
        address marhsal = config.config("MARSHAL");

        PTMMarshal marhsalContract = PTMMarshal(marhsal);

        require(marshalContract.marshal_index[msg.sender] > 0, "Only Marshal can vote");


        DisputedOrder current_order = disputedOrders[id];
        Order order = Order(current_order.adr);

        vote_count = current_order.vote_counter + 1;

        disputedOrders[id] = DisputedOrder(current_order.adr, vote_count, current_order.next, current_order.prev)
        order.vote(vote_for);

        if(vote_count == 5){
            uint prev = current_order.prev;
            uint next = current_order.next;

            if(prev >= start){
                disputedOrders[prev].next = current_order.next;
            }

            if(next <= end){
                disputedOrders[next].prev = current_order.prev;
            }

            delete disputedOrders[id];
            
            if(id == end){
                end--;
            }else if(id == start){
                start++;
            }
        }
    }


    getAllDispute(uint256 _start, uint256 count) public view returns(memory DisputedOrder){
        uint256 next = _start;

        DisputedOrder[] memory dispute_list = new DisputedOrder[](count);

        for (uint256 i = 0; i < count; i++) {

            dispute_list[i] = disputedOrders[next];
            next = disputedOrders[next].next;

            if (next > end || next == 0) {
                break;
            }
        }

        return dispute_list;
    }
}