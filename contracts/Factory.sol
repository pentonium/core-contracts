pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;
import "./job/Category.sol";
import "./lib/Events.sol";

contract Factory is Events{

    struct CategoryStruct {
        string category_name;
        address contract_address;
    }


    CategoryStruct[] public categories;
    uint256 public total_categories;

    address config_contract_address;
    address owner;


    constructor(){
        owner = msg.sender;
    }

    /** Create a new category */
    function createCategory(string memory name) public {
        require(msg.sender == owner, "Only owner can create a category");

        Category new_category = new Category(name);

        CategoryStruct memory cat = CategoryStruct(name, address(new_category));

        categories.push(cat);

        total_categories++;
    }

    /** update configuration contract address */
    function setConfigContract(address _config_contract_address) public{
        config_contract_address = _config_contract_address;
    }

    function getConfigContract() public returns (address){
        return config_contract_address;
    }

    /** update owner's address */
    function setOwnerAddress(address _owner) public{
        owner = _owner;
    }

    /** Returns array of categories */
    function getAllCategpries() public view returns (CategoryStruct[] memory) {
        return categories;
    }

}