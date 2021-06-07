pragma solidity >=0.7.0 <0.8.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface PTMConfig {
    function config(string memory _key) external view returns (address);
}

interface Dispute {
    function addNewDispute() external returns ();
}

contract PTMOrderEscrow {
    string public ipfs_hash;

    string service_provider_private;
    string service_provider_public;
    string client_private;
    string client_public;
    string[] ipfs_hash_list;

    address public service_provider;
    address public client;
    address public offer_contract;
    address[] public marshals_list;

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

    IERC20 USDT;

    constructor() {
        USDT = IERC20(0x8b5D9502938FDCA4a56047cb4D42314550e9B8E2);
    }

    function create(
        address _service_provider,
        address _client,
        string memory _client_public,
        string memory _client_private,
        string memory _ipfs_hash,
        uint256 _price,
        uint256 _duration
    ) public {
        require(order_status == 0, "Should only be called once");
        order_created = block.timestamp;

        service_provider = _service_provider;
        client = _client;
        client_public = _client_public;
        client_private = _client_private;
        price = _price;
        duration = _duration;
        ipfs_hash = _ipfs_hash;
        offer_contract = msg.sender;

        order_status = 200;
    }

    function cancelOrder() public {
        require(
            order_status == 200,
            "Order must not be gone further then created"
        );
        require(order_created + 1 < block.timestamp, "Order must be 1 day old");
        require(msg.sender == client, "Must be client");

        USDT.transfer(client, USDT.balanceOf(address(this)));
        order_status = 203;
    }

    function acceptOrder(
        string memory _service_provider_public,
        string memory _service_provider_private
    ) public {
        require(
            order_status == 200,
            "Order must not be gone further then created"
        );
        require(msg.sender == service_provider, "Must be sevice provider");
        order_status = 201;
        service_provider_public = _service_provider_public;
        service_provider_private = _service_provider_private;
    }

    function rejectOrder() public {
        require(
            order_status == 200,
            "Order must not be gone further then created"
        );
        require(msg.sender == service_provider, "Must be sevice provider");
        order_status = 202;
        USDT.transfer(client, USDT.balanceOf(address(this)));
    }

    function deliver(string memory _ipfs_hash) public {
        require(msg.sender == service_provider, "Must be sevice provider");
        order_status = 204;
        ipfs_hash_list.push(_ipfs_hash);
    }

    function acceptDelivery() public {
        require(msg.sender == client, "Must be client");
        order_status = 205;
        USDT.transfer(service_provider, USDT.balanceOf(address(this)));
    }

    function getClientRequirements()
        public
        view
        returns (
            string memory,
            string memory,
            string memory
        )
    {
        require(msg.sender == client, "Must be client");

        return (client_private, client_public, service_provider_public);
    }

    function getServiceProviderRequirements()
        public
        view
        returns (
            string memory,
            string memory,
            string memory
        )
    {
        require(msg.sender == service_provider, "Must be sevice provider");

        return (
            service_provider_private,
            service_provider_public,
            client_public
        );
    }

    function dispute() public {
        order_status = 206;

        // transfer dispute fee

        dispute_fee[msg.sender] = true;
        dispute_timer = block.timestamp;
    }

    function disputeAccept() public {
        order_status = 207;

        // transfer dispute fee

        dispute_fee[msg.sender] = true;

        PTMConfig config =
            PTMConfig(0x01fCAE732E224B4199de657aF7FC0fD3fe9835e5);
        address dispute = config.config("DISPUTE");

        Dispute disputeContract = Dispute(dispute);
        disputeContract.addNewDispute();
    }

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
