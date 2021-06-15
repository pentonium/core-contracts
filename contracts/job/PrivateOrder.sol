pragma solidity >=0.7.0 <0.8.0;
import "../interface/IERC20.sol";
import "../interface/IFactory.sol";
import "../interface/IConfig.sol";


interface Dispute {
    function addNewDispute() external returns ();
}

contract PrivateOrder {
    string public ipfs_hash;

    string service_provider_private;
    string service_provider_public;
    string client_private;
    string client_public;
    string[] ipfs_hash_list;

    address public service_provider;
    address public client;
    address public category_contract;
    address public token;

    mapping(address => bool) dispute_fee;
    mapping(address => uint256) dispute_vote;
    uint256 dispute_timer;

    uint256 public price;
    uint256 public duration;
    uint256 public order_created;

    uint256 public order_status;
    // 200 - created
    // 201 - accepted
    // 202 - rejected
    // 203 - cancelled
    // 204 - delivery - pending
    // 205 - delivery - accepted
    // 206 - dispute - created
    // 206 - dispute - proceeded by other party

    IConfig config_contract;

    function constructor( address _service_provider, address _client, address _token, string memory _client_public, string memory _client_private,
     string memory _ipfs_hash, uint256 _price, uint256 _duration, address _config_contract
    ){
        require(order_status == 0, "Should only be called once");
        order_created = block.timestamp;

        service_provider = _service_provider;
        client = _client;
        token = _token;
        client_public = _client_public;
        client_private = _client_private;
        price = _price;
        duration = _duration;
        ipfs_hash = _ipfs_hash;
        offer_contract = msg.sender;


        IConfig config_contract = IConfig(_config_contract);

        order_status = 200;
    }

    /** Order can be canceld after a day of no response */
    function cancelOrder() public {
        require(order_status == 200, "Order must not be gone further then created");
        require(order_created + 1 < block.timestamp, "Order must be 1 day old");
        require(msg.sender == client, "Must be client");

        IERC20(token).transfer(client, IERC20(token).balanceOf(address(this)));

        order_status = 203;
    }

    /** Service provider can accept the order */
    function acceptOrder(string memory _service_provider_public, string memory _service_provider_private) public {
        require(order_status == 200, "Order must not be gone further then created");
        require(msg.sender == service_provider, "Must be sevice provider");

        order_status = 201;
        service_provider_public = _service_provider_public;
        service_provider_private = _service_provider_private;
    }

    /** Service provider can reject the order */
    function rejectOrder() public {
        require(order_status == 200, "Order must not be gone further then created");
        require(msg.sender == service_provider, "Must be sevice provider");

        order_status = 202;

        IERC20(token).transfer(client, IERC20(token).balanceOf(address(this)));
    }

    /** Submit a deliver, requires ipfs hash of the chat */
    function deliver(string memory _ipfs_hash) public {
        require(msg.sender == service_provider, "Must be sevice provider");

        order_status = 204;

        ipfs_hash_list.push(_ipfs_hash);
    }

    /** Accept the delivery and transfer the fund */
    function acceptDelivery() public {
        require(msg.sender == client, "Must be client");

        order_status = 205;

        uint256 deliveryFee = config_contract.getConfigUint("DELIVERY_FEE");

        IERC20(token).transfer(service_provider, IERC20(token).balanceOf(address(this)));
    }


    /** Client Private & Public  */
    function getClientRequirements() public view returns (string memory, string memory, string memory){
        require(msg.sender == client, "Must be client");

        return (client_private, client_public, service_provider_public);
    }

    /** Service Provider Private & Public  */
    function getServiceProviderRequirements() public view returns (string memory, string memory, string memory){
        require(msg.sender == service_provider, "Must be sevice provider");

        return (service_provider_private, service_provider_public, client_public);
    }


    /** Create a dispute */
    function dispute() public {
        order_status = 206;

        address PTMtoken = config_contract.getConfigAddress("PTM_ADDRESS");
        uint256 disputeFee = config_contract.getConfigUint("DISPUTE_FEE");
        IERC20(PTMtoken).transferFrom(msg.sender, address(this), disputeFee);

        dispute_fee[msg.sender] = true;
        dispute_timer = block.timestamp;
    }


    /** Accept the dispute */
    function disputeAccept() public {
        order_status = 207;

        address PTMtoken = config_contract.getConfigAddress("PTM_ADDRESS");
        uint256 disputeFee = config_contract.getConfigUint("DISPUTE_FEE");
        IERC20(PTMtoken).transferFrom(msg.sender, address(this), disputeFee);

        dispute_fee[msg.sender] = true;


        address disputeContractAddress = config.config("DISPUTE");

        Dispute disputeContract = Dispute(disputeContractAddress);
        disputeContract.addNewDispute();
    }



    /** For Marshal's to vote through dispute contract */
    function vote(address user) public {
        PTMConfig config =
            PTMConfig(0x01fCAE732E224B4199de657aF7FC0fD3fe9835e5);
        address dispute = config.config("DISPUTE");

        require(order_status == 207, "Order must be in dispute state");
        require(msg.sender == dispute, "Should be from dispute contract");

        if (user == service_provider || user == client) {
            dispute_vote[user] = dispute_vote[user] + 1;

            if (dispute_vote[user] > 2) {
                // transfer funds to user
            }
        }
    }
}
