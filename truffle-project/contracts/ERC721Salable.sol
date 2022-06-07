// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

abstract contract ERC721Salable is ERC721PresetMinterPauserAutoId {

    ERC20PresetMinterPauser erc20;

    constructor(ERC20PresetMinterPauser _erc20) {
        erc20 = _erc20;
    }

    function sale(uint256 tokenId, uint256 price) public {

    }

    function sale(uint256 tokenId, uint256 price) public {
        
    }

}