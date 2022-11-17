// SPDX-License-Identifier: MIT;
pragma solidity ^0.8.7;

contract test {

    mapping (address => uint256) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) private excludedFromTax;

    address public owner;
    string public name;
    string public symbol;
    uint256 public initialSupply;
    uint8 public decimals;
    uint8 public transfer_fee;
    address public marketAddress;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        name = "";
        symbol = "";
        owner = msg.sender;

        transfer_fee = 6;
        marketAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

        decimals = 18;
        initialSupply = 1000000 * 10 ** decimals;

        balanceOf[msg.sender] = initialSupply;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(allowance[_from][msg.sender] >= _value);
        require(balanceOf[_from] >= _value );

        require(_from != address(0));
        require(_to != address(0));
        require(_to != _from);

        require(!isBlacklisted[_to], "Recipient is backlisted");

        uint8 half = 50;

        uint fee = _value * transfer_fee / 100;
        uint burn = fee * half / 100;
        uint market = fee - burn;

        initialSupply -= burn;
        balanceOf[marketAddress] += market;

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value - fee;

        emit Transfer(_from, _to, _value);

        return success;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] > _value);
        require(!isBlacklisted[msg.sender], "you are on the blacklist"); 
        require(!isBlacklisted[_to], "Recipient is backlisted");

        uint8 half = 50;

        if (excludedFromTax[msg.sender]) {
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;

            return true;
        } else {
            uint fee = _value * transfer_fee / 100;
            uint burn = fee * half / 100;
            uint market = fee - burn;

            initialSupply -= burn;
            balanceOf[marketAddress] += market;

            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value - fee;

            return true;
        }
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return success;
    }

    function addAddressToBlacklist(address _wallet) public onlyOwner {
        require(!isBlacklisted[_wallet]);
        require(_wallet != owner);

        isBlacklisted[_wallet] = true;
    }

    function removeAddressToBlacklist(address _wallet) public onlyOwner {
        require(isBlacklisted[_wallet]);

        isBlacklisted[_wallet] = false;
    }
}