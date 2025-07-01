// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts@1.3.0/src/v0.8/ChainlinkClient.sol";
import ".deps/npm/@chainlink/contracts@1.3.0/src/v0.8/shared/access/ConfirmedOwner.sol";
import "@chainlink/contracts@1.3.0/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {Operator} from "@chainlink/contracts@1.3.0/src/v0.8/operatorforwarder/Operator.sol";


contract OperatorConsumer is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;
    uint256 private constant ORACLE_PAYMENT = (1 * LINK_DIVISIBILITY) / 10; // 0.1 * 10**18
    string public hash;
    string public full;

    constructor() ConfirmedOwner(msg.sender) {
        _setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
    }

    //jobid: 95edfc2ee2724e1db6db0eecf74d2669

    
    function requestEthereumPrice(
        address _oracle,
        string memory _jobId
    ) public onlyOwner {
        Chainlink.Request memory req = _buildChainlinkRequest(
            stringToBytes32(_jobId),
            address(this),
            this.fulfillEthereumPrice.selector
        );
        req._add(
            "urlProjectName",
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
        );
        req._add("pathProjectName", "projectName");
        req._add(
            "urlLocation",
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
        );
        req._add("pathLocation", "location");
        req._add(
            "urlHash",
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
        );
        req._add("pathHash", "hash");
        req._add(
            "urlExpectedReductions",
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
        );
        req._add("pathExpectedReductions", "expectedReductions");
        req._add(
            "urlMethodology",
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
        );
        req._add("pathMethodology", "methodology");
        req._add(
            "urlProjectStartDate",
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
        );
        req._add("pathProjectStartDate", "projectStartDate");
        req._add(
            "urlValidationDate",
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
        );
        req._add("pathValidationDate", "validationDate");
        req._add(
            "urlVerificationDate",
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
        );
        req._add("pathVerificationDate", "verificationDate");
        req._add(
            "urlIssuedCredits",
            "https://tnywkhvak3.execute-api.ap-southeast-2.amazonaws.com/default/honours"
        );
        req._add("pathIssuedCredits", "issuedCredits");
        _sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    function fulfillEthereumPrice(
        bytes32 _requestId,
        string memory _projectName,
        string memory _location,
        string memory _hash,
        uint256  _expectedReductions,
        string memory _methodology,
        uint256  _projectStartDate,
        uint256  _validationDate,
        uint256  _verificationDate,
        uint256  _issuedCredits
    ) public recordChainlinkFulfillment(_requestId) {
        hash = _hash;
        full = string(abi.encodePacked(_projectName, _location, Strings.toString(_expectedReductions), _methodology));
        full = string(abi.encodePacked(full, Strings.toString(_projectStartDate), Strings.toString(_validationDate), Strings.toString(_verificationDate), Strings.toString(_issuedCredits)));
    }

    function stringToBytes32(
        string memory source
    ) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }
    
}


/*
Flow Execution:
    - Deploy opNode if haven't already
    - Run the chainlink and postgres docker containers
    - Deploy prove contract
    - deployAPI()
    - getProjectDetails() -> wait until the job is completed fully
    - hashCheck()

*/

contract Prove {
    OperatorConsumer public opConsumer;
    event HashResult(bytes32);
    event Data(string);
    
    
    function deployAPI() public {
        opConsumer = new OperatorConsumer();
    }

    function getProjDetails(address opNode) public {
        opConsumer.requestEthereumPrice(opNode, "95edfc2ee2724e1db6db0eecf74d2669");
    }

    function hashCheck() public view returns (bool) {
        bytes32 calcHash = keccak256(abi.encodePacked(opConsumer.full()));
        string memory calcHashStr = bytes32ToString(calcHash);
        return keccak256(abi.encodePacked(calcHashStr)) == keccak256(abi.encodePacked(opConsumer.hash()));
    }


    function bytes32ToString(bytes32 data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64); // Each byte corresponds to 2 hex characters

        for (uint256 i = 0; i < 32; i++) {
            str[i * 2] = alphabet[uint8(data[i] >> 4) & 0xf]; // Extract the first 4 bits
            str[1 + i * 2] = alphabet[uint8(data[i]) & 0xf];  // Extract the last 4 bits
        }

        return string(str);
    }

    

}