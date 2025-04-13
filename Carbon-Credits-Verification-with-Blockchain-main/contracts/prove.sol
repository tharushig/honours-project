// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/operatorforwarder/Operator.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract OperatorConsumer is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    uint256 private constant ORACLE_PAYMENT = (1 * LINK_DIVISIBILITY) / 10; // 0.1 * 10**18
    string public projectName;
    string public location;
    string public hash;
    uint256 public expectedReductions;
    string public methodology;
    uint256 public projectStartDate;
    uint256 public validationDate;
    uint256 public verificationDate;
    uint256 public issuedCredits;

    event RequestEthereumPriceFulfilled(
        bytes32 indexed requestId,
        uint256 indexed price
    );

    /**
     *  Sepolia
     *@dev LINK address in Sepolia network: 0x779877A7B0D9E8603169DdbD7836e478b4624789
     * @dev Check https://docs.chain.link/docs/link-token-contracts/ for LINK address for the right network
     */
    constructor() ConfirmedOwner(msg.sender) {
        _setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
    }

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
            "https://4fa4-14-201-139-159.ngrok-free.app/data"
        );
        req._add("pathProjectName", "projectName");
        req._add(
            "urlLocation",
            "https://4fa4-14-201-139-159.ngrok-free.app/data"
        );
        req._add("pathLocation", "location");
        req._add(
            "urlHash",
            "https://4fa4-14-201-139-159.ngrok-free.app/data"
        );
        req._add("pathHash", "hash");
        req._add(
            "urlExpectedReductions",
            "https://4fa4-14-201-139-159.ngrok-free.app/data"
        );
        req._add("pathExpectedReductions", "expectedReductions");
        req._add(
            "urlMethodology",
            "https://4fa4-14-201-139-159.ngrok-free.app/data"
        );
        req._add("pathMethodology", "methodology");
        req._add(
            "urlProjectStartDate",
            "https://4fa4-14-201-139-159.ngrok-free.app/data"
        );
        req._add("pathProjectStartDate", "projectStartDate");
        req._add(
            "urlValidationDate",
            "https://4fa4-14-201-139-159.ngrok-free.app/data"
        );
        req._add("pathValidationDate", "validationDate");
        req._add(
            "urlVerificationDate",
            "https://4fa4-14-201-139-159.ngrok-free.app/data"
        );
        req._add("pathVerificationDate", "verificationDate");
        req._add(
            "urlIssuedCredits",
            "https://4fa4-14-201-139-159.ngrok-free.app/data"
        );
        req._add("pathIssuedCredits", "issuedCredits");
        _sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    function fulfillEthereumPrice(
        bytes32 _requestId,
        string memory _projectName,
        string memory _location,
        string memory _hash,
        uint256 _expectedReductions,
        string memory _methdology,
        uint256 _projectStartDate,
        uint256 _validationDate,
        uint256 _verificationDate,
        uint256 _issuedCredits
    ) public recordChainlinkFulfillment(_requestId) {
        emit RequestEthereumPriceFulfilled(_requestId, 1);
        projectName = _projectName;
        location = _location;
        hash = _hash;
        expectedReductions = _expectedReductions;
        methodology = _methdology;
        projectStartDate = _projectStartDate;
        validationDate = _validationDate;
        verificationDate = _verificationDate;
        issuedCredits = _issuedCredits;
    }

    function getChainlinkToken() public view returns (address) {
        return _chainlinkTokenAddress();
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(_chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) public onlyOwner {
        _cancelChainlinkRequest(
            _requestId,
            _payment,
            _callbackFunctionId,
            _expiration
        );
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



contract Prove {
    bytes32 private messageHash;
    OperatorConsumer public opConsumer;

    struct Project{   
        string projectName;
        string location;
        string methodology;
        uint256 expectedReductions;
        uint256 projectStartDate;
        uint256 validationDate;
        uint256 verificationDate;
        uint256 issuedCredits;
        bytes32 hash;
    }

    Project public proj;

    function newProj() public {
        Project memory p = Project({
            projectName: "newProj",
            location: "Australia", 
            methodology: "VM0038",
            expectedReductions: 100000,
            projectStartDate: 10101010101,
            validationDate: 10101010101,
            verificationDate: 10101010101,
            issuedCredits : 109238,
            hash:0x9df2ba90ecee146939dc2a5d442af963ca4478cda1620aa11d5060c7c4fbdc0d
        });
        proj = p;
    }

    function deployAPI() public {
        opConsumer = new OperatorConsumer();
    }

    function getProjDetails() public {
        // uint req = uint(apiConsumer.requestData(1));
    }

    function hash() public {
        string memory data = string.concat(proj.projectName, proj.location , proj.methodology, Strings.toString(proj.expectedReductions), Strings.toString(proj.projectStartDate), Strings.toString(proj.verificationDate), Strings.toString(proj.validationDate),Strings.toString(proj.issuedCredits));
        messageHash = keccak256(bytes(data));
        // uint req = uint(apiConsumer.requestData(1));
    }
    
    function getMessageHash() public view returns (bytes32) {
        return messageHash;
    }

    function checkData() public view returns (bool) {
        return messageHash == proj.hash;
    }


}