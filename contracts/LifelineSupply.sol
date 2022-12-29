// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.14;

// import "OpenZeppelin/openzeppelin-contracts@4.8.0/contracts/token/ERC721/ERC721.sol";
// import "OpenZeppelin/openzeppelin-contracts@4.8.0/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "OpenZeppelin/openzeppelin-contracts@4.8.0/contracts/access/Ownable.sol";
// import "OpenZeppelin/openzeppelin-contracts@4.8.0/contracts/utils/cryptography/ECDSA.sol";

contract LifeLineSupply {
    // using ECDSA for bytes32;
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    enum Status {
        LISTED,
        ASSIGNED,
        DONATED
    }

    struct Registrar {
        address addr;
        string name;
        bool isValid;
    }

    struct Donor {
        address addr;
        string name;
        uint age;
        string bloodType;
        string organ;
        Registrar registrar;
        uint lifespan;
        bool isViable;
        Status status; // Defualt: LISTED
    }

    struct Recipient {
        address addr;
        string name;
        uint age;
        string bloodType;
        string organ;
        uint priority; // Lower No. Low Priority (default to 0 max 10)
        Registrar registrar;
        bool isAssigned;
        Donor _donor;
    }
    
    mapping (address => Donor) public donors;
    mapping (address => Recipient) public recipients;
    mapping (address => Registrar) public registrars;

    modifier _onlyRegistrar {
        require(registrars[msg.sender].isValid, "Only a Hospital can invoke this function");
        _;
    }

    modifier _onlyOwner {
        require(msg.sender == _owner, "Only the Owner can invoke this function");
        _;
    }

    // Events
    event NewDonor(Donor d);
    event NewRecipient(Recipient r);
    event NewAssignemnt(Donor d, Recipient r);
    event NewDonation(Donor d, Recipient r, uint timestamp);

    function registerADonor(address donorAddress, string memory _name, uint _age, string memory _bloodType, string memory _organ, uint _lifespan) _onlyRegistrar public {
        Registrar memory reg = registrars[msg.sender];
        donors[donorAddress] = Donor(donorAddress, _name, _age, _bloodType, _organ, reg, block.timestamp + _lifespan*1 days, true, Status.LISTED);
        emit NewDonor(donors[donorAddress]);
    }

    function registerRecipient(address recipientAddress, string memory _name, uint _age, string memory _bloodType, string memory _organ, uint _priority) _onlyRegistrar public {
        Registrar memory reg = registrars[msg.sender];
        Donor memory d;
        recipients[recipientAddress] = Recipient(recipientAddress, _name, _age, _bloodType, _organ, _priority, reg, false, d);
        emit NewRecipient(recipients[recipientAddress]);
    }

    function assignDonorToRecipient(address _dAddr, address _rAddr) _onlyRegistrar public {
        if (block.timestamp > donors[_dAddr].lifespan) {
            donors[_dAddr].isViable = false;
        }
        // Only the registrar of the donor can assign to a recipient
        require(msg.sender == donors[_dAddr].registrar.addr, "Only the registrar of the Donor can assign to a recipient");
        require(block.timestamp <= donors[_dAddr].lifespan, "Organ Lifespan exceeded cannot proceed");
        require(donors[_dAddr].isViable, "Donor Organ is not viable");
        require(donors[_dAddr].status != Status.DONATED, "Donor has already Donated");
        require(donors[_dAddr].status != Status.ASSIGNED, "Donor has already been Assigned to another recipient");
        require(!recipients[_rAddr].isAssigned, "Recepient has already been assigned to a Donor call reassignDonorToRecipient to change");

        recipients[_rAddr]._donor = donors[_dAddr];
        recipients[_rAddr].isAssigned = true;
        donors[_dAddr].status = Status.ASSIGNED;
        emit NewAssignemnt(donors[_dAddr], recipients[_rAddr]);
    }

    function reassignDonorToRecipient(address _dAddr, address _rAddr) _onlyRegistrar public {
        // Only the registrar of the donor can call this function
        require(msg.sender == recipients[_rAddr]._donor.registrar.addr, "Only the registrar of the Donor can call this function");
        // Make the old donor available
        donors[recipients[_rAddr]._donor.addr].status = Status.LISTED;
        recipients[_rAddr].isAssigned = false;
        if (block.timestamp > recipients[_rAddr]._donor.lifespan) {
            donors[recipients[_rAddr]._donor.addr].isViable = false;
        }

        // Call the assignFunction again
        assignDonorToRecipient(_dAddr, _rAddr);
    }

    function donate(address _rAddr) _onlyRegistrar public {
        require(msg.sender == recipients[_rAddr]._donor.registrar.addr, "Only the registrar of the Donor can call this function");
        donors[recipients[_rAddr]._donor.addr].status = Status.DONATED;
        emit NewDonation(recipients[_rAddr]._donor, recipients[_rAddr], block.timestamp);
    }

    function newRegistrar(address _addr, string memory name) _onlyOwner public {
        registrars[_addr] = Registrar(_addr, name, true);
    }
}