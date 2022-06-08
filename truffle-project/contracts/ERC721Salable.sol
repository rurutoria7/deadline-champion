// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

abstract contract ERC721Salable is ERC721PresetMinterPauserAutoId {

    ERC20PresetMinterPauser erc20;
    mapping(uint256 => bool) forSale;
    mapping(uint256 => uint256) price;
    mapping(uint256 => address) salerOf;

    constructor(ERC20PresetMinterPauser _erc20) {
        erc20 = _erc20;
    }

    function sale(uint256 tokenId, uint256 _price) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Salable: transfer caller is not owner nor approved");
        require(_exists(tokenId), "ERC721Salable: URI query for nonexistent token");

        forSale[tokenId] = true;   
        price[tokenId] = _price;
        salerOf[tokenId] = _msgSender();
    }

    function unSale(uint256 tokenId) public {
        forSale[tokenId] = false;
        transferFrom(address(this), salerOf[tokenId], tokenId);
    }

    function buy(uint256 tokenId, uint256 price) public {
        require(forSale[tokenId], "ERC721Salable: this token is not salable");
        forSale[tokenId] = false;
        erc20.transfer(price[tokenId], salerOf[tokenId]);
        transferFrom(address(this), msg.sender, tokenId);
    }

}