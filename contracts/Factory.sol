// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Token.sol';

contract Factory {
  event Deployed(address indexed addr);

  uint256 constant SALT = 0xff;

  // 1. Get bytecode of contract to be deployed
  function getBytecode(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 taxFee_,
        uint256 liquidityFee_,
        uint256 totalSupply_,
        address _router
  ) public pure returns (bytes memory) {
    bytes memory bytecode = type(Token).creationCode;

    return abi.encodePacked(bytecode, abi.encode(name_, symbol_, decimals_, taxFee_, liquidityFee_, totalSupply_, _router));
  }

  // 2. Compute the address of the contract to be deployed
  function getAddress(bytes memory bytecode) public view returns (address) {
    bytes32 hash = keccak256(
      abi.encodePacked(bytes1(0xff), address(this), SALT, keccak256(bytecode))
    );
    // NOTE: cast last 20 bytes of hash to address
    return address(uint160(uint256(hash)));
  }

  // 3. Deploy the contract
  // NOTE:
  // Check the event log Deployed which contains the address of the deployed TestContract.
  // The address in the log should equal the address computed from above.
  function deploy(bytes memory bytecode, address admin) public payable {
    address payable addr;

    assembly {
      addr := create2(callvalue(), add(bytecode, 0x20), mload(bytecode), SALT)

      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }
    Token(addr).transferOwnership(admin);
    emit Deployed(addr);
  }
}