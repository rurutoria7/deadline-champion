// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "./ERC721Salable.sol";

contract ROSCA {

    ERC20PresetMinterPauser public erc20;
    ERC721Salable public erc721;

    enum Status {
        pay,
        bid
    }

    struct Identity {
        uint256 id;
        bool attend;
        uint256 collateral;
        uint256 rid;
        address addr;
        bool won; 
        bool isHead;
    }
    
    // won: baseFee, else: baseFee-bid
    mapping(uint256 => uint256) payLn;
    mapping(uint256 => uint256) bidLn;
    mapping(uint256 => uint256) baseFee;
    mapping(uint256 => uint256) minBid;
    mapping(uint256 => Identity[]) members; //include head
    mapping(uint256 => address) head;
    mapping(uint256 => Status) status; //環節

    mapping(uint256 => uint256[]) winner; //得標者
    mapping(uint256 => uint256[]) bidAmount; //標金

    uint256 roscaCounter;
    uint256 identityCounter;

    //reverse mapping
    mapping(address => uint256[]) identityOfAddress;

    constructor(
        ERC20PresetMinterPauser _erc20,
        ERC721Salable _erc721
    ) {
        roscaCounter = 0;
        identityCounter = 0;
        erc20 = _erc20;
        erc721 = _erc721;
    }

    function buildROSCA(
        address[] memory _member, //not include head
        uint256 _baseFee,
        uint256 _minBid
    ) public returns(uint256){

        uint256 rid = roscaCounter;
        roscaCounter++;

        for (uint i=0; i<_member.length; i++) {
            members[rid].push(
                Identity(
                    identityCounter++,
                    false,
                    0,
                    rid,
                    _member[i],
                    false,
                    false
                )
            );
        }
        members[rid].push(
            Identity(
                identityCounter++,
                false,
                0,
                rid,
                msg.sender,
                false,
                true
            )
        );

        baseFee[rid] = _baseFee;
        minBid[rid] = _minBid;
        members[rid] = members[rid];
    
        return rid;
    }

    function pushNextStage(uint256 rid) public{
        
    }

    function attend(uint256 rid) public{
        //require member and not attend
        //transfer collateral to this
        //if everyone attend
            //status := bidding
    }

    function bid(uint256 rid, uint256 price) public {
        //require member and status == bid
        //if everyone bid
            //status := pay
    }

    function pay(uint256 rid) public {
        //require member and status == pay
        //transfer to winner
    }
}