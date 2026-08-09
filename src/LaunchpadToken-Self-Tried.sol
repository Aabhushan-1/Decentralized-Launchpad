//SPDX-License_Identifier: MIT

pragma solidity ^0.8.19;

contract LaunchpadToken {
    string private i_name;
    string private i_symbol;
    uint8 private immutable i_decimals;
    uint256 private immutable i_totalSupply;

    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {
        i_name = _name;
        i_symbol = _symbol;
        i_decimals = _decimals;
        i_totalSupply = _totalSupply;

        _balanceOf[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view returns (string memory) {
        return i_name;
    }

    function symbol() public view returns (string memory) {
        return i_symbol;
    }

    function decimals() public view returns (uint8) {
        return i_decimals;
    }

    function totalSupply() public view returns (uint256) {
        return i_totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balanceOf[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (_balanceOf[msg.sender] < _value) {
            revert("Not Enough Balance!");
        }

        if (_to == address(0)) {
            revert("Receiver Address Zero!");
        }

        _balanceOf[msg.sender] -= _value;
        _balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (_from == address(0)) {
            revert("Sender Address Zero!");
        }

        if (_to == address(0)) {
            revert("Receiver Address Zero!");
        }

        if (_allowance[msg.sender][_from] < _value) {
            revert("Amount exceeds allowance");
        }

        _balanceOf[_from] -= _value;
        _balanceOf[_to] += _value;
        _allowance[msg.sender][_from] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_spender == address(0)) {
            revert("Sender Address Zero!");
        }

        _allowance[_spender][msg.sender] += _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        if (_owner == address(0)) {
            revert("Owner Address Zero!");
        }

        if (_spender == address(0)) {
            revert("Sender Address Zero!");
        }

        return _allowance[_spender][_owner];
    }
}
