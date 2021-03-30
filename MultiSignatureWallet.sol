pragma solidity 0.7.5;

pragma abicoder v2;

contract MultiSignatureWallet {
    
    // Private so that only the contract can modify it
    address[] private walletOwners;
    uint private requiredSignatures;
    
    // mapping of apporvals
    mapping(uint => address[]) clearedApproves;
    
    // Keep track of requests
    struct TransferRequests{
        address payable to;
        uint amount;
        bool isPayed;
    }
    
    TransferRequests[] TransferRequestLog;
    
    // So the creator sets the owners of the shared wallet. The creator is not
    // included as a owner if he/she does not pass their own address as owner.
    //
    // Note that _reqSigns - required signatures can be zero. Thus withdrawls
    // CAN be made without approval of any of the owners if not specified.
    constructor(address[] memory _owners, uint _reqSigns){
        require(_owners.length > 1, "Give at least one address.");// There has to be at least one owner.
        require(_reqSigns <= _owners.length, "Cannot have more required 'signs' than owners.");// There has to be enough owners.
        for (uint i = 0 ; i < _owners.length ; i++){
            walletOwners.push(_owners[i]);
        }
        requiredSignatures = _reqSigns;
    }
    
    // Anyone can deposit ether to the wallet.
    function deposit() public payable returns(uint){
        return address(this).balance;
    }
    
    // See who can make transfer requests - this was not specified but I
    // thought it would be nice!
    function getWalletOwners() public view returns(address[] memory){
        return walletOwners;
    }
    
    // transfer request that can only be added by an owner
    function transferRequest(address payable _to, uint _amount) public{
        require(isOwner(), "Is not owner");
        require(_amount <= address(this).balance, "The wallet does not have sufficient funds");
        if (requiredSignatures == 0){
            _to.transfer(_amount);
        }else{
            TransferRequestLog.push(TransferRequests(_to, _amount, false));
        }
    }
    
    // If is an owner
    function isOwner() private returns (bool){
        for (uint i = 0 ; i < walletOwners.length ; i++){
            if(walletOwners[i] == msg.sender){
                return true;
            }
        }
        return false;
    }
    
    // Get all requests
    function getRequests() public view returns(uint, TransferRequests[] memory){
        return(TransferRequestLog.length, TransferRequestLog);
    }
    
    // Approve requests and send them if they are not paid and has enough approvals
    // else return number of approvals that the transfer has so far.
    function approveRequest(uint _index) public payable returns(uint){
        require(isOwner());
        clearedApproves[_index].push(msg.sender);
        if(clearedApproves[_index].length >= requiredSignatures && TransferRequestLog[_index].isPayed == false){
            TransferRequestLog[_index].to.transfer(TransferRequestLog[_index].amount);
            TransferRequestLog[_index].isPayed = true;
        }else{
            return clearedApproves[_index].length
        }
    }
}