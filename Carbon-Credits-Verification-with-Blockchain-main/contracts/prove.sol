// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts@1.3.0/src/v0.8/ChainlinkClient.sol";
import ".deps/npm/@chainlink/contracts@1.3.0/src/v0.8/shared/access/ConfirmedOwner.sol";
// import "@chainlink/contracts@1.3.0/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {Operator} from "@chainlink/contracts@1.3.0/src/v0.8/operatorforwarder/Operator.sol";


/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */


contract OperatorConsumer is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    // string public projectName;
    // string public location;
    // string public hash;
    // uint256 public expectedReductions;
    // string public methodology;
    // uint256 public projectStartDate;
    // uint256 public validationDate;
    // uint256 public verificationDate;
    // uint256 public issuedCredits;

    string[] public data;
    string public hash;
    string public full;

    /**
     *  Sepolia
     *@dev LINK address in Sepolia network: 0x779877A7B0D9E8603169DdbD7836e478b4624789
     * @dev Check https://docs.chain.link/docs/link-token-contracts/ for LINK address for the right network
     */
    constructor() ConfirmedOwner(msg.sender) {
        _setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
    }

    function requestEthereumPrice(
        address _oracle
    ) public onlyOwner {
        Chainlink.Request memory req = _buildChainlinkRequest(
            "20e79fd0c8cb4b2d9fbcd906951daac7",
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
        _sendChainlinkRequestTo(_oracle, req, (1 * LINK_DIVISIBILITY) / 10);
    }

    function fulfillEthereumPrice(
        bytes32 _requestId,
        string memory _projectName,
        string memory _location,
        string memory _hash,
        uint256 _expectedReductions,
        string memory _methodology,
        uint256 _projectStartDate,
        uint256 _validationDate,
        uint256 _verificationDate,
        uint256 _issuedCredits
    ) public recordChainlinkFulfillment(_requestId) {
        hash = _hash;
        full = string(abi.encodePacked(_projectName, _location, _expectedReductions, _methodology, _projectStartDate, _validationDate, _verificationDate, _issuedCredits));
    }
    
}

// Carbon-Credits-Verification-with-Blockchain-main/contracts/Operator.sol
// pragma solidity ^0.8.20;
// import "@openzeppelin/contracts/token/ERC165

//     // }

//     function getChainlinkToken() public view returns (address) {
//         return _chainlinkTokenAddress();
//     }

//     function withdrawLink() public onlyOwner {
//         LinkTokenInterface link = LinkTokenInterface(_chainlinkTokenAddress());
//         require(
//             link.transfer(msg.sender, link.balanceOf(address(this))),
//             "Unable to transfer"
//         );
//     }
// }



contract Prove {
    OperatorConsumer public opConsumer;
    Operator public operator;
    address[] a;

    function deployAPI() public {
        opConsumer = new OperatorConsumer();
    }

    function deployOperator() public {
        operator = new Operator(0x779877A7B0D9E8603169DdbD7836e478b4624789,0xCbd38adA2d31C7071e041fC8F8C1DA9Df9c76dD4);
        a.push(0x48104C06a5195f196a4fff0D485bED476c165A55);
        operator.setAuthorizedSenders(a);
    }

    function getProjDetails() public {
        opConsumer.requestEthereumPrice(address(opConsumer));
    }

    function hash() public view returns (bool) {
        return keccak256(bytes(opConsumer.full())) == keccak256(bytes(opConsumer.hash()));
    }

    function checkWorking(uint x, uint y) public pure returns (bool) {
        return x == y;
    }


}