pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;
import "../interface/IERC20.sol";
import "../interface/IFactory.sol";
import "../interface/IConfig.sol";
import "./Order.sol";
import "./PrivateOrder.sol";

contract Category {
    struct JobStruct {
        string ipfs_hash;
        string thumbnail;
        address service_provider;
        uint256 duration;
        uint256 price;
        uint256 id;
        uint256 next;
        uint256 prev;
    }

    struct PrivateJobStruct {
        string ipfs_hash;
        string thumbnail;
        address service_provider;
        address client;
        address token;
        uint256 duration;
        uint256 price;
        uint256 id;
        uint256 next;
        uint256 prev;
    }

    mapping(uint256 => JobStruct) public jobs;
    mapping(uint246 => PrivateJobStruct) private private_jobs;

    string public name;

    uint256 public start;
    uint256 public end;
    uint256 public total_private_jobs;

    IFactory factory_contact;
    IConfig config_contract;

    constructor(string memory _name) {
        start = 1;
        end = 0;

        name = _name;
        factory_contact = IFactory(address(msg.sender));

        address config_contract_address = factory_contact.getConfigContract();
        config_contract = IConfig(config_contract_address);
    }

    /* Post public job */
    function create(string memory ipfs_hash, string memory thumbnail, uint256 price, uint256 duration ) public {
        end++;

        jobs[end] = JobStruct( ipfs_hash, thumbnail, msg.sender, price, duration, end, end + 1, end - 1);

        if (end - 1 != 0) {
            gigs[end - 1].next = end;
        }

        // Add Category to users contract

        factory_contact.EventForJobStatus(msg.sender, address(this), end, 200);
    }


    /* returns jobs starting from start till start + count */
    function read(uint256 _start, uint256 count) public view returns (JobStruct[] memory){
        uint256 next = _start;

        JobStruct[] memory job_list = new JobStruct[](count);

        for (uint256 i = 0; i < count; i++) {
            if (jobs[next].service_provider == address(0)) {
                break;
            }

            job_list[i] = jobs[next];
            next = jobs[next].next;

            if (next > end || next == 0) {
                break;
            }
        }

        return job_list;
    }


    /* Update jobs */
    function update(string memory ipfs_hash,string memory thumbnail,uint256 price,uint256 duration,uint256 id) public {
        // update job, should only be done by service provider
        require(msg.sender == jobs[id].service_provider);
        jobs[id] = JobStruct(ipfs_hash, thumbnail, jobs[id].service_provider, price, duration, id, jobs[id].next, jobs[id].prev);

        factory_contact.EventForJobStatus(msg.sender, address(this), id, 201);
    }


    /* Delete job posted by service provider */
    function deleteJob(uint256 id) public {
        // update job, should only be done by service provider
        // Check logic of delte one more time
        require(msg.sender == jobs[id].service_provider);

        if (jobs[id].next <= end) {
            jobs[jobs[id].next].prev = jobs[id].prev;
        }

        if (jobs[id].prev >= start) {
            jobs[jobs[id].prev].next = jobs[id].next;
        }

        if (id == end) {
            end = jobs[id].prev;
        } else if (id == start) {
            start = jobs[id].next;
        }

        delete jobs[id];

        factory_contact.EventForJobStatus(msg.sender, address(this), id, 202);
    }

    
    /* Place an order for a pubblic job post */
    function placeOrder( uint256 id, string memory client_public, string memory client_private) public {

        JobStruct memory selected_gig = jobs[id];

        Order order = new Order(service_provider, client, client_public, client_private, ipfs_hash, price, duration, config_contract);

        address token = config_contract.getConfigAddress("PAYMENT_TOKEN");

        IERC20(token).transferFrom(msg.sender, address(order), price);

        // Add to client order
        // Add to service provider order
    }



    /* Post private job */
    function createPrivateJob(address client, address token, string memory ipfs_hash, string memory thumbnail, uint256 price, uint256 duration ) public {
        total_private_jobs++;

        private_jobs[total_private_jobs] = PrivateJobStruct(ipfs_hash, thumbnail, msg.sender, client, token, price, duration, end, end + 1, end - 1);

        factory_contact.EventForJobStatus(msg.sender, address(this), total_private_jobs, 203);
    }


    /* Returns a private job if called from service provider and client */
    function getPrivateJob(uint256 id) public returns (PrivateJobStruct) {
        require( msg.sender == private_jobs[id].client || msg.sender == private_jobs[id].service_provider,
            "It's a private order"
        );

        return private_jobs[id];
    }


    /** Place am order for a private job post */
    function placePrivateOrder(uint256 id, string memory client_public, string memory client_private) public {
        PrivateJobStruct memory current_job = private_jobs[id];

        Order order = new PrivateOrder(service_provider, client, client_public, client_private, ipfs_hash, price, duration, config_contract);


        IERC20(current_job.token).transferFrom(msg.sender, address(order), price);

        // Add to client order
        // Add to service provider order
    }
}
