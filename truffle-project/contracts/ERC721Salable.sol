// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

abstract contract ERC721Salable is ERC721PresetMinterPauserAutoId {

    ERC20PresetMinterPauser erc20;
    mapping(uint256 => bool) forSale;
    mapping(uint256 => uint256) price;
    mapping(uint256 => address) salerOf;

    event tradeMaded (address from, address to, uint256 price, uint256 tokenId);

    constructor(ERC20PresetMinterPauser _erc20) {
        erc20 = _erc20;
    }

    function sale(uint256 tokenId, uint256 _price) public {
        require(ownerOf(tokenId) == _msgSender(), "ERC721Salable: transfer caller is not owner");
        require(_exists(tokenId), "ERC721Salable: URI query for nonexistent token");
        
        forSale[tokenId] = true;   
        price[tokenId] = _price;
        salerOf[tokenId] = ownerOf(tokenId);
        _transfer(_msgSender(), address(this), tokenId);
    }

    function unSale(uint256 tokenId) public {
        require(salerOf[tokenId]==_msgSender(), "ERC721Salable: you're not saler of this token.");
        _transfer(address(this), salerOf[tokenId], tokenId);
        forSale[tokenId] = false;
        salerOf[tokenId] = address(0);
    }

    function buy(uint256 tokenId) public {
        require(forSale[tokenId], "ERC721Salable: this token is not salable");
        forSale[tokenId] = false;
        erc20.transferFrom(_msgSender(), salerOf[tokenId], price[tokenId]);
        _transfer(address(this), _msgSender(), tokenId);
        emit tradeMaded(salerOf[tokenId], _msgSender(), price[tokenId], tokenId);
    }

    function queryPrice(uint256 tokenId) public view returns(uint256){
        return price[tokenId];
    }

   function querySaler(uint256 tokenId) public view returns(address) {
       return salerOf[tokenId];
   }

   function onSale(uint256 tokenId) public view returns(bool) {
        return forSale[tokenId];
   }
}