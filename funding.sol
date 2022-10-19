// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;


//import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";



// Coded by KD526
contract Groupfund is ReentrancyGuard {
  using Counters for Counters.Counter;
  
  
  Counters.Counter private pledgeId;
    address[] public owners;
    uint256 targetAmount;
    address owner;
    uint public count;
    uint public collectedAmount;
    uint public minimumContribution;
    uint256 deadline;

    event Pledging(address indexed pledger, uint amount);
    event Cancel(address indexed owner, uint pledgeId);
    event Accept(uint pledgeId);
    event Revoke(uint pledgeId);

    mapping(uint => Pledge) private pledges;
    mapping(address => uint256) private _balance;

    constructor(address[] memory _owners, uint _targetAmount, uint _minimumContribution, uint256 _deadline) {
        owners = _owners;
        targetAmount = _targetAmount;
        minimumContribution = _minimumContribution;
        deadline = block.timestamp + _deadline;

    }

    modifier onlyOwner() {
        for(uint i=0; i<owners.length; i++) {
            owners[i] = owner;
        }
    
        require(owner == payable (msg.sender), "Only members allowed");
        _;
    }

     modifier isDeadlinePassed() {
        require(
            block.timestamp < deadline,
            "Crowd Funding deadline has passed. Please try again later."
        );
        _;
    }
    // function to add owner not in the group 
    function addGroupOwners(address _owner) public onlyOwner returns(bool) {
        owners.push(_owner);
        return true;
    }

    struct Pledge {
        address pledger;
        uint pledgedAmount;
        uint pledgeId;
        uint32 pledgeDeadline;
        bool pledged;
    }

function inputPledge(
    address _pledger,
    uint _amount,
    uint _pledgeId
    ) 
    external onlyOwner() isDeadlinePassed returns(bool) 
    {

    pledgeId.increment();


    Pledge memory _pledge = pledges[_pledgeId];
    _balance[_pledger] -= _amount;
    _pledge.pledgedAmount += _amount;
    collectedAmount += _amount;
    require(_pledge.pledgeDeadline >= block.timestamp);
    uint32 _deadline = _pledge.pledgeDeadline;

    pledges[_pledgeId] = Pledge({
        pledger: _pledger,
        pledgedAmount: _amount,
        pledgeId: _pledgeId,
        pledgeDeadline: _deadline,
        pledged: true

    });
    emit Pledging(msg.sender, _amount);
    return true;
}

function getBalance() public view returns(uint256) {
return address(this).balance;
}
///to show balance  of each owner
function balanceOf(address _owner) public view returns(uint256) {
    return _balance[_owner];
}
///owners to accept pledges made
function AcceptPledge(uint _pledgeId) external onlyOwner returns(bool accepted) {
    emit Accept(_pledgeId);
    return accepted; 
}

/// owners to revoke pledges made by another owner
function revokePledge(uint _pledgeId) external onlyOwner {
    delete pledges[_pledgeId];
    emit Revoke( _pledgeId);
}
// cancel pledge by owner
function cancelPledge(address _owner, uint _pledgeId, uint _amount) external {

    require(_owner == msg.sender, "Invalid address!");
    pledges[_pledgeId].pledgedAmount -= _amount;
    collectedAmount -= _amount;
    _balance[_owner] += _amount;

    delete pledges[_pledgeId];

    emit Cancel(msg.sender, _pledgeId);

}   

/// To refund all owners contribution
function Refund(address payable _owner, uint _pledgeId) public onlyOwner returns(bool) {

    require(_owner == pledges[_pledgeId].pledger);
    require(_pledgeId == pledges[_pledgeId].pledgeId);
    require(collectedAmount < targetAmount);
    require(deadline < block.timestamp);

    _owner.transfer(pledges[_pledgeId].pledgedAmount);

   return true;

}
}