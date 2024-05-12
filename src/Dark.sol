// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TokenPool is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address public tokenContractAddress;
    uint256 public poolSize;
    uint256 public fee;

    mapping(uint256 => address) public tokenOwners;
    mapping(address => uint256) public balances;

    event TokenDeposited(address indexed owner, uint256 tokenId, uint256 amount);
    event TokenBurned(address indexed owner, uint256 tokenId, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        address _tokenContractAddress,
        uint256 _poolSize,
        uint256 _fee
    ) ERC721(_name, _symbol) {
        tokenContractAddress = _tokenContractAddress;
        poolSize = _poolSize;
        fee = _fee;
    }

    function deposit(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(IERC20(tokenContractAddress).balanceOf(msg.sender) >= _amount, "Insufficient balance");
        require(IERC20(tokenContractAddress).allowance(msg.sender, address(this)) >= _amount, "Not enough allowance");

        IERC20(tokenContractAddress).transferFrom(msg.sender, address(this), _amount);

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        tokenOwners[newTokenId] = msg.sender;
        balances[msg.sender] += _amount;

        emit TokenDeposited(msg.sender, newTokenId, _amount);
    }

    function burn(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "Not the token owner");
        require(balanceOf(msg.sender) >= fee, "Insufficient balance");

        _burn(_tokenId);

        uint256 amount = balances[msg.sender];
        balances[msg.sender] -= fee;
        
        uint256 randomTokenId = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % poolSize;
        address randomTokenOwner = tokenOwners[randomTokenId];
        IERC20(tokenContractAddress).transfer(msg.sender, fee);
        IERC20(tokenContractAddress).transferFrom(randomTokenOwner, msg.sender, 1);

        emit TokenBurned(msg.sender, _tokenId, amount);
    }
}