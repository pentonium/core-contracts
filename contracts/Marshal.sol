pragma solidity >=0.7.0 <0.8.0;

contract PTMMarashals {
    struct marshal {
        address adr;
        uint256 next;
        uint256 prev;
    }

    struct candidate_detaile {
        string ipfs_hash;
        uint256 applied_on;
        uint256 vote_for;
        uint256 vote_against;
    }

    mapping(address => candidate_detaile) public candidate_details;
    mapping(uint256 => marshal) public marshals;
    mapping(address => uint256) public marshal_index;
    address[] public candidates;

    uint256 start;
    uint256 end;
    uint256 total_candidate;
    uint256 total_marshal;
    uint256 randNonce;

    constructor() {
        start = 1;
        end = 0;
    }

    function voteForMarshal(address _marshal) public {
        //check for required conditions

        candidate_details[_marshal] = candidate_detaile(
            candidate_details[_marshal].ipfs_hash,
            candidate_details[_marshal].applied_on,
            candidate_details[_marshal].vote_for + 1,
            candidate_details[_marshal].vote_against
        );
    }

    function voteAgainstMarshal(address _marshal) public {
        //check for required conditions

        candidate_details[_marshal] = candidate_detaile(
            candidate_details[_marshal].ipfs_hash,
            candidate_details[_marshal].applied_on,
            candidate_details[_marshal].vote_for,
            candidate_details[_marshal].vote_against + 1
        );
    }

    function applyForMarshal(string memory ipfs_hash) public {
        candidate_detaile memory selected_candidate =
            candidate_details[msg.sender];

        if (
            selected_candidate.applied_on == 0 ||
            (selected_candidate.applied_on > 0 &&
                selected_candidate.applied_on + 7 days < block.timestamp)
        ) {
            candidates.push(msg.sender);
            candidate_details[msg.sender] = candidate_detaile(
                ipfs_hash,
                block.timestamp,
                0,
                0
            );
            total_candidate++;
        }
    }

    function acceptResult(address _marshal) public {
        candidate_detaile memory selected_candidate =
            candidate_details[_marshal];

        if (selected_candidate.applied_on + 7 days < block.timestamp) {
            uint256 vote_for = candidate_details[_marshal].vote_for;
            uint256 vote_against = candidate_details[_marshal].vote_against;

            if (vote_for > vote_against) {
                if (marshal_index[_marshal] == 0) {
                    end++;
                    marshal_index[_marshal] = end;
                    marshals[end] = marshal(_marshal, end - 1, end + 1);
                    total_marshal++;
                }
            } else {
                if (marshal_index[_marshal] != 0) {
                    uint256 id = marshal_index[_marshal];

                    if (marshals[id].next <= end) {
                        marshals[marshals[id].next].prev = marshals[id].prev;
                    }
                    if (marshals[id].prev >= start) {
                        marshals[marshals[id].prev].next = marshals[id].next;
                    }

                    if (id == end) {
                        end = marshals[id].prev;
                    } else if (id == start) {
                        start = marshals[id].next;
                    }

                    delete marshal_index[_marshal];
                    delete marshals[id];
                    total_marshal--;
                }
            }
        }
    }

    
}
