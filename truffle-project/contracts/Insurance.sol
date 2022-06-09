// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Insurance {

    ERC20PresetMinterPauser public erc20;
    ERC721 public erc721;

    mapping (uint256 => address) insurer;
    mapping (uint256 => address) guarantor;
    mapping (uint256 => address) beneficiary;
    mapping (uint256 => address) validator;

    mapping (uint256 => uint256) insuredTargetTokenId;
    mapping (uint256 => uint256) soldPrice;
    mapping (uint256 => uint256) sumInsured;
    mapping (uint256 => uint256) expireLn;
    mapping (uint256 => uint256) createdTime;

    mapping (uint256 => bool) getPaid;
    mapping (uint256 => uint256) bank;
    mapping (uint256 => bool) exists;

    //reverse mapping
    mapping (address => uint256[]) guarantorToId;
    mapping (address => uint256[]) beneficiaryToId;
    mapping (address => uint256[]) validatorToId;

    uint256[] tmp;

    uint256 insuranceIdCounter;

    event newInsurance (
        address insurer,
        address guarantor,
        address beneficiary,
        address validator,
        uint256 insuredTargetTokenId,
        uint256 soldPrice,
        uint256 sumInsured,
        uint256 expireLn,
        uint256 insuranceId
    );

    event triggerInsurance (
        address insurer,
        address guarantor,
        address beneficiary,
        uint256 insuredTargetTokenId,
        uint256 sumInsured,
        uint256 triggerTime,
        uint256 sumInsuredPercentage
    );        

    constructor (ERC20PresetMinterPauser _erc20, ERC721 _erc721) {
        erc20 = _erc20;
        erc721 = _erc721;
        insuranceIdCounter = 0;
    }

    modifier insurerOnly(uint256 id) {
        require(msg.sender == insurer[id], "HouseInsurance: insurer only");
        _;
    }
    modifier guarantorOnly(uint256 id) {
        require(msg.sender == guarantor[id], "HouseInsurance: guarantor only");
        _;
    }
    modifier beneficiaryOnly(uint256 id) {
        require(msg.sender == beneficiary[id], "HouseInsurance: beneficiary only");
        _;
    }
    modifier validatorOnly(uint256 id) {
        require(msg.sender == validator[id], "HouseInsurance: validator only");
        _;
    }
    modifier requirePaid(uint256 id) {
        require(getPaid[id], "HouseInsurance: guarantor should pay first");
        _;
    }

    function isExist(uint256 id) public returns (bool) {
        if (block.timestamp > expireLn[id]+createdTime[id]) {
            stopContract(id);
        }
        return exists[id];
    } 

    modifier requireExist(uint256 id) {
        require(isExist(id), "This insurance id is not exist");
        _;
    }

    modifier guarantorIsOwner(uint256 id)  {
        require(erc721.ownerOf(insuredTargetTokenId[id]) == guarantor[id], "Insurance: Guarantor is not owner of target token.");
        _;

    }

    function _saveTokenInBank(
        uint256 id,
        uint256 amount
    ) internal {
        require(erc20.balanceOf(msg.sender) > amount);
        erc20.transfer(address(this), amount);
        bank[id] += amount;
    }

    function _takeTokenOutBank(
        uint256 id, 
        address to, 
        uint256 amount
    ) internal {
        erc20.transferFrom(address(this), to, amount);
        bank[id] -= amount;
    }


    function buildInsurance(
        address _guarantor,
        address _beneficiary,
        address _validator,
        uint256 _insuredTarget,
        uint256 _soldPrice,
        uint256 _sumInsured,
        uint256 _expireLn
    ) public {

        uint256 id = insuranceIdCounter;
        insuranceIdCounter += 1;

        //transfer insurer's money into contract
        _saveTokenInBank(id, _sumInsured);

        //set info
        insurer[id] = msg.sender;
        guarantor[id] = _guarantor;
        beneficiary[id] = _beneficiary;
        validator[id] = _validator;

        guarantorToId[guarantor[id]].push(id);
        beneficiaryToId[beneficiary[id]].push(id);
        validatorToId[validator[id]].push(id);
        
        insuredTargetTokenId[id] = _insuredTarget;
        soldPrice[id] = _soldPrice;
        sumInsured[id] = _sumInsured;
        expireLn[id] = _expireLn;

        getPaid[id] = false;
        exists[id] = true;
        createdTime[id] = block.timestamp;

        emit newInsurance(
            insurer[id],
            guarantor[id],
            beneficiary[id],
            validator[id],
            insuredTargetTokenId[id],
            soldPrice[id],
            sumInsured[id],
            expireLn[id],
            id
        );
    }

    function triggerCompensation(
        uint256 id,
        uint256 sumInsuredPercentage
    ) public requireExist(id) validatorOnly(id) requirePaid(id) guarantorIsOwner(id) {
        //send required money to beneficiary
        uint256 claim = sumInsured[id]*sumInsuredPercentage/100;
        _takeTokenOutBank(id, beneficiary[id], claim);
        //stop contract
        stopContract(id);

        emit triggerInsurance (
            insurer[id],
            guarantor[id],
            beneficiary[id],
            insuredTargetTokenId[id],
            sumInsured[id],
            block.timestamp,
            sumInsuredPercentage
        );        
    }

    function stopContract(
        uint256 id
    ) public requireExist(id) guarantorOnly(id) { 
        // transfer money to company
        _takeTokenOutBank(
            id,
            insurer[id],
            bank[id]
        );
        // exist = false
        exists[id] = false;
    }

    function setBenificiary(
        uint256 id, address _beneficiary
    ) public requireExist(id) guarantorOnly(id) guarantorIsOwner(id){

            while (tmp.length > 0) tmp.pop();
            uint256 l = beneficiaryToId[beneficiary[id]].length;

            for (uint i=0; i<l; i++) {
                if (beneficiaryToId[beneficiary[id]][i] == id) continue;
                tmp.push(beneficiaryToId[beneficiary[id]][i]);
            }
            beneficiaryToId[beneficiary[id]] = tmp;

            beneficiary[id] = _beneficiary;
            beneficiaryToId[beneficiary[id]].push(id);            
    }

    function pay(
        uint256 id
    ) public requireExist(id) guarantorOnly(id) guarantorIsOwner(id){
        _saveTokenInBank(id,soldPrice[id]);
        getPaid[id] = true;
    }

    function queryInsurer(uint256 id) public requireExist(id) returns(address) {
        return insurer[id];
    }

    function queryBeneficiary(uint256 id) public  requireExist(id) returns(address) {
        return beneficiary[id];
    }   

    function queryValidator(uint256 id) public  requireExist(id) returns(address) {
        return validator[id];
    }       

    function queryInsuredTarget(uint256 id) public  requireExist(id) returns(uint256) {
        return insuredTargetTokenId[id];
    }   

    function querySoldPrice(uint256 id) public  requireExist(id) returns(uint256) {
        return soldPrice[id];
    }   

    function querySumInsured(uint256 id) public  requireExist(id) returns(uint256) {
        return sumInsured[id];
    }   

    function queryExpireLn(uint256 id) public  requireExist(id) returns(uint256) {
        return expireLn[id];
    }   

    function queryBank(uint256 id) public  requireExist(id) returns(uint256) {
        return bank[id];
    }    

    function queryGuarantorToId(address adr) public view returns(uint256[] memory) {
        return guarantorToId[adr];
    }

    function queryBeneficiaryToId(address adr) public view returns(uint256[] memory) {
        return beneficiaryToId[adr];
    }

    function queryValidatorToId(address adr) public view returns(uint256[] memory) {
        return validatorToId[adr];
    }

    function queryGetPaid (uint256 tokenId) public view returns(bool) {
        return getPaid[tokenId];
    }
}