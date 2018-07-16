pragma solidity ^0.4.24;


contract ERC721 {
    function getSerializedData(string _tokenVIN) public returns(bytes32[2]);
    function recoveryToken(address _receiver, string _tokenVIN, bytes32[2] _data) public;
    function demolishToken(string _tokenVIN) public;
}

contract BasicBridge {
    event UserRequestForSignature(address _from, string _tokenVIN, bytes32[2] _data);

    event TransferCompleted(string _tokenVIN);

    ERC721 ERC721Contract;
    bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

    address[] validators;
    uint requiredSignatures;
    mapping (bytes32 => bool) validatorAlreadyHandled;
    mapping (bytes32 => uint) signaturesCollected;
    mapping (bytes32 => bool) tokenRecovered;
    

    function tranferApproval(address _receiver, string _tokenVIN, bytes32[2] _data) public {
        require(_isValidator(msg.sender));
        
        bytes32 transaction = _hashTransaction(_receiver, _tokenVIN, _data);
        bytes32 sender = _hashSender(msg.sender, transaction);
        
        require(!validatorAlreadyHandled[sender]);
        require(!tokenRecovered[transaction]);
        
        signaturesCollected[transaction]++;
        
        require(signaturesCollected[transaction] >= requiredSignatures);
        
        ERC721Contract.recoveryToken(_receiver, _tokenVIN, _data);
        tokenRecovered[transaction] = true;
        emit TransferCompleted(_tokenVIN);
    }
    
    function _isValidator(address _validator) private view returns(bool) {
        bool _result;
        
        for (uint i = 0; i < validators.length; i++) {
            if (validators[i] == _validator) {
                _result = true;
                break;
            }
        }
        
        return _result;
    }
    
    function _hashTransaction(address _receiver, string _tokenVIN, bytes32[2] _data) private pure returns(bytes32) {
        return keccak256(abi.encode(_receiver, _tokenVIN, _data));
    }
    
    function _hashSender(address _sender, bytes32 _hash) private pure returns(bytes32) {
        return keccak256(abi.encode(_sender, _hash));   
    }
}

contract HomeBridge is BasicBridge {
    constructor(address[] _validators, uint _requiredSignatures) public {
        validators = _validators;
        requiredSignatures = _requiredSignatures;
    }
    
    function onERC721Received(
        address _from,
        address _owner,
        string _tokenVIN,
        bytes _data
    ) public returns(bytes4) {
        bytes32[2] memory data = ERC721(msg.sender).getSerializedData(_tokenVIN);
        emit UserRequestForSignature(_from, _tokenVIN, data);
        return ERC721_RECEIVED;
    }
}

contract ForeignBridge is BasicBridge {
    constructor(address[] _validators, uint _requiredSignatures) public {
        validators = _validators;
        requiredSignatures = _requiredSignatures;
    }
    
    function onERC721Received(
        address _from,
        address _owner,
        string _tokenVIN,
        bytes _data
    ) public returns(bytes4) {
        bytes32[2] memory data = ERC721(msg.sender).getSerializedData(_tokenVIN);
        emit UserRequestForSignature(_from, _tokenVIN, data);
        return ERC721_RECEIVED;
    }
}
