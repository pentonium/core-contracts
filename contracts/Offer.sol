pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;
import "./Order.sol";
import "./Category.sol";

contract PTMOffers {
    struct gig {
        string ipfs_hash;
        string thumbnail;
        address service_provider;
        uint256 duration;
        uint256 price;
        uint256 id;
        uint256 next;
        uint256 prev;
    }

    mapping(uint256 => gig) public gigs;

    string public category;

    uint256 public start;
    uint256 public end;

    address category_contract;

    IERC20 public USDT;

    constructor() {
        start = 1;
        end = 0;

        PTMConfig config =
            PTMConfig(0x01fCAE732E224B4199de657aF7FC0fD3fe9835e5);
        address usdt_adr = config.config("USDT");
        category_contract = address(msg.sender);

        USDT = IERC20(usdt_adr);
    }

    function setCategory(string memory _name) public {
        category = _name;
    }

    function create(
        string memory ipfs_hash,
        string memory thumbnail,
        uint256 price,
        uint256 duration
    ) public {
        end++;

        gigs[end] = gig(
            ipfs_hash,
            thumbnail,
            msg.sender,
            price,
            duration,
            end,
            end + 1,
            end - 1
        );

        if(end - 1 != 0){
            gigs[end - 1].next = end;
        }

        PTMCategories cat = PTMCategories(category_contract);

        cat.addNewUserGig(msg.sender, address(this), end);
    }

    function read(uint256 _start, uint256 count)
        public
        view
        returns (gig[] memory)
    {
        uint256 next = _start;

        gig[] memory gig_list = new gig[](count);

        for (uint256 i = 0; i < count; i++) {
            if (gigs[next].service_provider == address(0)) {
                break;
            }

            gig_list[i] = gigs[next];
            next = gigs[next].next;

            if (next > end || next == 0) {
                break;
            }
        }

        return gig_list;
    }

    function update(
        string memory ipfs_hash,
        string memory thumbnail,
        uint256 price,
        uint256 duration,
        uint256 id
    ) public {
        gigs[id] = gig(
            ipfs_hash,
            thumbnail,
            gigs[id].service_provider,
            price,
            duration,
            id,
            gigs[id].next,
            gigs[id].prev
        );
    }

    function deleteGig(uint256 id) public {

        if (gigs[id].next <= end) {
            gigs[gigs[id].next].prev = gigs[id].prev;
        }
        if (gigs[id].prev >= start) {
            gigs[gigs[id].prev].next = gigs[id].next;
        }

        if (id == end) {
            end = gigs[id].prev;
        } else if (id == start) {
            start = gigs[id].next;
        }

        delete gigs[id];
    }

    function placeOrder(
        uint256 id,
        string memory client_public,
        string memory client_private
    ) public {
        gig memory selected_gig = gigs[id];

        PTMOrderEscrow order = new PTMOrderEscrow();

        PTMCategories cat = PTMCategories(category_contract);

        cat.addNewClientOrder(msg.sender, address(order));
        cat.addNewServiceProviderOrder(
            selected_gig.service_provider,
            address(order)
        );

        // USDT.transferFrom(
        //     msg.sender,
        //     address(order),
        //     selected_gig.price
        // );

        order.create(
            selected_gig.service_provider,
            msg.sender,
            client_public,
            client_private,
            selected_gig.ipfs_hash,
            selected_gig.price,
            selected_gig.duration
        );
    }
}
