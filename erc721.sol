pragma solidity ^0.4.24;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract ERC721Reciever{
    function onERC721Received(
        address _from,
        address _to,
        string _tokenVIN,
        bytes _data
    ) public returns(bytes4);
}

contract ERC721 {
    using SafeMath for uint256;

    event Transfer(address indexed _from, address indexed _to, string indexed _tokenId);
    event tokenRecovered(string _tokenId);
    event tokenBurnt(string _tokenId);
    event Approval(address indexed _owner, address indexed _approved, string indexed _tokenId);
    event tokenColorChanged(string indexed _tokenVIN, string _tokenColor);
    event tokenRegNumberChanged(string indexed _tokenVIN, string indexed _tokenRegNumber);

    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    uint256 public totalSupply;
    bool public canNotCreateToken;
    mapping (address => uint256) balances;
    mapping (string => address) tokenOwner;
    mapping (string => address) tokenApprovals;
    mapping (string => string) private tokenColor;
    mapping (string => string) private tokenRegNumber;

    constructor(bool _canNotCreateToken) public {
        canNotCreateToken = _canNotCreateToken;
        totalSupply = 0;
    }

    function approve(address _approved, string _tokenVIN) public {
        address owner = ownerOf(_tokenVIN);
        require(owner == msg.sender);
        require(_approved != msg.sender);
        tokenApprovals[_tokenVIN] = _approved;
        emit Approval(owner, _approved, _tokenVIN);
    }

    function transferFrom(address _from, address _to, string _tokenVIN) public {
        require(_from != address(0) && _to != address(0));
        require(_from != _to);
        address owner = ownerOf(_tokenVIN);
        require(owner == _from);
        require(owner == msg.sender || getApproved(_tokenVIN) == msg.sender);
        clearApproval(_from, _tokenVIN);
        removeTokenFrom(_from, _tokenVIN);
        addTokenTo(_to, _tokenVIN);
        emit Transfer(_from, _to, _tokenVIN);
    }

    function transfer(address _to, string _tokenVIN) public returns (bool) {
        emit Transfer(msg.sender, _to, _tokenVIN);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function ownerOf(string _tokenVIN) public view returns (address) {
        return tokenOwner[_tokenVIN];
    }
    
    function getApproved(string _tokenVIN) public view returns (address) {
        return tokenApprovals[_tokenVIN];
    }
    
    function clearApproval(address _owner, string _tokenVIN) internal {
        require(ownerOf(_tokenVIN) == _owner);
        if (tokenApprovals[_tokenVIN] != address(0)) {
            tokenApprovals[_tokenVIN] = address(0);
        }
    }
    
    function removeTokenFrom(address _from, string _tokenVIN) internal {
        require(ownerOf(_tokenVIN) == _from);
        tokenOwner[_tokenVIN] = address(0);
        balances[_from] -= 1;
    }
    
    function addTokenTo(address _to, string _tokenVIN) internal {
        require(tokenOwner[_tokenVIN] == address(0));
        tokenOwner[_tokenVIN] = _to;
        balances[_to] += 1;
    }
    
    function _produce(address _to, string _tokenVIN, string _color) public {
        require(!canNotCreateToken);
        require(_to != address(0));
        require(tokenOwner[_tokenVIN] == address(0));
        addTokenTo(_to, _tokenVIN);
        tokenColor[_tokenVIN] = _color;
        totalSupply += 1;
        emit Transfer(address(0), _to, _tokenVIN);
    }
    
    function _produce(address _to, string _tokenVIN, string _color, string _regNumber) public {
        require(!canNotCreateToken);
        require(_to != address(0));
        require(tokenOwner[_tokenVIN] == address(0));
        addTokenTo(_to, _tokenVIN);
        tokenColor[_tokenVIN] = _color;
        tokenRegNumber[_tokenVIN] = _regNumber;
        totalSupply += 1;
        emit Transfer(address(0), _to, _tokenVIN);
    }
    
    function _destroy(address _owner, string _tokenVIN) public {
        require(tokenOwner[_tokenVIN] != address(0));
        clearApproval(_owner, _tokenVIN);
        removeTokenFrom(_owner, _tokenVIN);
        totalSupply -= 1;
        emit Transfer(_owner, address(0), _tokenVIN);
    }
    
    function getTokenColor(string _tokenVIN) public view returns (string) {
        require(ownerOf(_tokenVIN) != address(0));
        return tokenColor[_tokenVIN];
    }
    
    function getTokenRegNumber(string _tokenVIN) public view returns (string) {
        require(ownerOf(_tokenVIN) != address(0));
        return tokenRegNumber[_tokenVIN];
    }
    
    function setTokenColor(string _tokenVIN, string _newTokenColor) public {
        address owner = ownerOf(_tokenVIN);
        require(owner != address(0));
        require(owner == msg.sender || getApproved(_tokenVIN) == msg.sender);
        tokenColor[_tokenVIN] = _newTokenColor;
    }
    
    function setTokenRegNumber(string _tokenVIN, string _newTokenRegNumber) public {
        address owner = ownerOf(_tokenVIN);
        require(owner != address(0));
        require(owner == msg.sender || getApproved(_tokenVIN) == msg.sender);
        tokenRegNumber[_tokenVIN] = _newTokenRegNumber;
    }
    
    function safeTransferFrom(address _from, address _to, string _tokenVIN) public {
        safeTransferFrom(_from, _to, _tokenVIN, "");
    }
    
    function safeTransferFrom(address _from, address _to, string _tokenVIN, bytes _data) public {
        transferFrom(_from, _to, _tokenVIN);
        if (isContract(_to)) {
            bytes4 retval = ERC721Reciever(_to).onERC721Received(_from, _to, _tokenVIN, _data);
            require (retval == ERC721_RECEIVED);
        }
    }
    
    function getSerializedData(string _tokenVIN) public view returns (bytes32[2]) {
        return [
                convertStringToBytes32(tokenColor[_tokenVIN]), 
                convertStringToBytes32(tokenRegNumber[_tokenVIN])
            ];
    }
    
    function recoveryToken(string _tokenVIN, bytes32[2] data) public {
        require(ownerOf(_tokenVIN) == msg.sender || ownerOf(_tokenVIN) == address(0));
        setTokenColor(_tokenVIN, convertBytes32ToString(data[0]));
        setTokenRegNumber(_tokenVIN, convertBytes32ToString(data[1]));
        emit tokenRecovered(_tokenVIN);
    }

    
    function convertStringToBytes32(string memory source) public pure returns (bytes32 result) {
      bytes memory testEmptyStringTest = bytes(source);
      
      if (testEmptyStringTest.length == 0) {
          return 0x0;
      }  
      
      assembly {
          result := mload(add(source, 32))
      }
        
    }
    
    function convertBytes32ToString(bytes32 source) public pure returns (string) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = source[i];
        }
        return string(bytesArray);
    }
    
    function demolishToken(string _tokenId) public {
        emit tokenBurnt(_tokenId);
    }
    
    // function setPermissionsToRecover(address _owner) public {}
    // function setPermissionsToDemolish(address _owner) public {}
    
    function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
    }
}
